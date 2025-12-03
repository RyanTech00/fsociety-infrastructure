#!/bin/sh
#
# OpenVPN RADIUS Accounting Daemon
# Implementa RADIUS Accounting (RFC 2866) para OpenVPN no pfSense
#
# Autor: Hugo Correia
# Projeto: FSociety.pt - ESTG/IPP
# UC: Administração de Sistemas II
# Ano Letivo: 2024/2025
#
# Funcionalidades:
# - Acct-Start: Enviado quando cliente conecta
# - Acct-Interim-Update: Enviado a cada 30 segundos (keepalive)
# - Acct-Stop: Enviado quando cliente desconecta ou muda de IP
#
# Instalação:
# 1. Copiar este script para /usr/local/bin/openvpn-accounting-daemon.sh
# 2. Tornar executável: chmod +x /usr/local/bin/openvpn-accounting-daemon.sh
# 3. Configurar no Shellcmd: System → Shellcmd → Add
#    Command: /usr/local/bin/openvpn-accounting-daemon.sh
#    Type: shellcmd
#
# NOTA: Substituir <RADIUS_SECRET> pelo secret configurado no FreeRADIUS

# ===========================
# CONFIGURAÇÃO
# ===========================

# Servidor RADIUS
RADIUS_SERVER="192.168.1.10"
RADIUS_SECRET="<RADIUS_SECRET>"
RADIUS_ACCT_PORT="1813"

# NAS (Network Access Server) - pfSense
NAS_IP="192.168.1.1"
NAS_IDENTIFIER="pfSense-OpenVPN"

# OpenVPN
STATUS_LOG="/var/log/openvpn-status.log"
SESSIONS_DIR="/var/openvpn/accounting"

# Intervalo de atualização (segundos)
INTERIM_INTERVAL=30

# Logging
LOG_TAG="openvpn-accounting"

# ===========================
# INICIALIZAÇÃO
# ===========================

# Criar diretório de sessões se não existe
mkdir -p "${SESSIONS_DIR}"

# Log de início
logger -t "${LOG_TAG}" "Daemon iniciado - Intervalo de atualização: ${INTERIM_INTERVAL}s"

# ===========================
# FUNÇÕES
# ===========================

# Envia pacote RADIUS Accounting
# Argumentos: $1=username, $2=session_id, $3=acct_status_type, $4=framed_ip, $5=bytes_in, $6=bytes_out, $7=session_time
send_radius_accounting() {
    USERNAME="$1"
    SESSION_ID="$2"
    ACCT_STATUS_TYPE="$3"
    FRAMED_IP="$4"
    BYTES_IN="${5:-0}"
    BYTES_OUT="${6:-0}"
    SESSION_TIME="${7:-0}"
    
    # Criar ficheiro temporário com atributos RADIUS
    TEMP_FILE=$(mktemp)
    
    cat > "${TEMP_FILE}" <<EOF
User-Name = "${USERNAME}"
Acct-Session-Id = "${SESSION_ID}"
Acct-Status-Type = ${ACCT_STATUS_TYPE}
NAS-IP-Address = ${NAS_IP}
NAS-Identifier = "${NAS_IDENTIFIER}"
NAS-Port-Type = Virtual
Service-Type = Framed-User
Framed-IP-Address = ${FRAMED_IP}
Framed-Protocol = PPP
Acct-Input-Octets = ${BYTES_IN}
Acct-Output-Octets = ${BYTES_OUT}
Acct-Session-Time = ${SESSION_TIME}
EOF
    
    # Enviar para servidor RADIUS
    cat "${TEMP_FILE}" | radclient -x "${RADIUS_SERVER}:${RADIUS_ACCT_PORT}" acct "${RADIUS_SECRET}" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        logger -t "${LOG_TAG}" "RADIUS Acct enviado: ${USERNAME} (${ACCT_STATUS_TYPE}) - IP: ${FRAMED_IP}"
    else
        logger -t "${LOG_TAG}" "ERRO: Falha ao enviar RADIUS Acct para ${USERNAME}"
    fi
    
    # Remover ficheiro temporário
    rm -f "${TEMP_FILE}"
}

# Processa cliente conectado
process_client() {
    USERNAME="$1"
    FRAMED_IP="$2"
    BYTES_IN="$3"
    BYTES_OUT="$4"
    CONNECTED_SINCE="$5"
    
    # Gerar session ID baseado em username e timestamp de conexão
    SESSION_ID=$(echo "${USERNAME}_${CONNECTED_SINCE}" | md5)
    SESSION_FILE="${SESSIONS_DIR}/${SESSION_ID}"
    
    # Calcular tempo de sessão
    CURRENT_TIME=$(date +%s)
    CONNECTED_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M:%S" "${CONNECTED_SINCE}" +%s 2>/dev/null || echo "${CURRENT_TIME}")
    SESSION_TIME=$((CURRENT_TIME - CONNECTED_TIMESTAMP))
    
    # Verificar se é nova sessão
    if [ ! -f "${SESSION_FILE}" ]; then
        # Nova sessão - enviar Acct-Start
        send_radius_accounting "${USERNAME}" "${SESSION_ID}" "Start" "${FRAMED_IP}" "${BYTES_IN}" "${BYTES_OUT}" "0"
        
        # Guardar estado da sessão
        echo "${USERNAME}|${FRAMED_IP}|${BYTES_IN}|${BYTES_OUT}|${CONNECTED_SINCE}" > "${SESSION_FILE}"
        logger -t "${LOG_TAG}" "Nova sessão: ${USERNAME} (${FRAMED_IP})"
    else
        # Sessão existente - ler estado anterior
        OLD_STATE=$(cat "${SESSION_FILE}")
        OLD_IP=$(echo "${OLD_STATE}" | cut -d'|' -f2)
        
        # Verificar mudança de IP (reconexão)
        if [ "${OLD_IP}" != "${FRAMED_IP}" ]; then
            # IP mudou - enviar Acct-Stop para IP antigo e Acct-Start para novo IP
            logger -t "${LOG_TAG}" "Mudança de IP detectada: ${USERNAME} (${OLD_IP} → ${FRAMED_IP})"
            
            OLD_BYTES_IN=$(echo "${OLD_STATE}" | cut -d'|' -f3)
            OLD_BYTES_OUT=$(echo "${OLD_STATE}" | cut -d'|' -f4)
            
            send_radius_accounting "${USERNAME}" "${SESSION_ID}" "Stop" "${OLD_IP}" "${OLD_BYTES_IN}" "${OLD_BYTES_OUT}" "${SESSION_TIME}"
            send_radius_accounting "${USERNAME}" "${SESSION_ID}" "Start" "${FRAMED_IP}" "${BYTES_IN}" "${BYTES_OUT}" "0"
            
            # Atualizar estado
            echo "${USERNAME}|${FRAMED_IP}|${BYTES_IN}|${BYTES_OUT}|${CONNECTED_SINCE}" > "${SESSION_FILE}"
        else
            # Mesma sessão - enviar Acct-Interim-Update
            send_radius_accounting "${USERNAME}" "${SESSION_ID}" "Interim-Update" "${FRAMED_IP}" "${BYTES_IN}" "${BYTES_OUT}" "${SESSION_TIME}"
            
            # Atualizar estado
            echo "${USERNAME}|${FRAMED_IP}|${BYTES_IN}|${BYTES_OUT}|${CONNECTED_SINCE}" > "${SESSION_FILE}"
        fi
    fi
}

# Processa desconexões (clientes que não estão mais no status log)
process_disconnections() {
    # Lista de sessões ativas
    ACTIVE_SESSIONS=$(mktemp)
    
    # Ler status log e extrair session IDs ativos
    if [ -f "${STATUS_LOG}" ]; then
        grep -E "^CLIENT_LIST" "${STATUS_LOG}" | while read line; do
            USERNAME=$(echo "$line" | cut -d',' -f2)
            CONNECTED_SINCE=$(echo "$line" | cut -d',' -f8)
            SESSION_ID=$(echo "${USERNAME}_${CONNECTED_SINCE}" | md5)
            echo "${SESSION_ID}" >> "${ACTIVE_SESSIONS}"
        done
    fi
    
    # Verificar sessões guardadas
    for SESSION_FILE in "${SESSIONS_DIR}"/*; do
        if [ -f "${SESSION_FILE}" ]; then
            SESSION_ID=$(basename "${SESSION_FILE}")
            
            # Se sessão não está ativa, cliente desconectou
            if ! grep -q "${SESSION_ID}" "${ACTIVE_SESSIONS}"; then
                # Ler estado da sessão
                OLD_STATE=$(cat "${SESSION_FILE}")
                USERNAME=$(echo "${OLD_STATE}" | cut -d'|' -f1)
                FRAMED_IP=$(echo "${OLD_STATE}" | cut -d'|' -f2)
                BYTES_IN=$(echo "${OLD_STATE}" | cut -d'|' -f3)
                BYTES_OUT=$(echo "${OLD_STATE}" | cut -d'|' -f4)
                CONNECTED_SINCE=$(echo "${OLD_STATE}" | cut -d'|' -f5)
                
                # Calcular tempo total de sessão
                CURRENT_TIME=$(date +%s)
                CONNECTED_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M:%S" "${CONNECTED_SINCE}" +%s 2>/dev/null || echo "${CURRENT_TIME}")
                SESSION_TIME=$((CURRENT_TIME - CONNECTED_TIMESTAMP))
                
                # Enviar Acct-Stop
                send_radius_accounting "${USERNAME}" "${SESSION_ID}" "Stop" "${FRAMED_IP}" "${BYTES_IN}" "${BYTES_OUT}" "${SESSION_TIME}"
                
                # Remover sessão
                rm -f "${SESSION_FILE}"
                logger -t "${LOG_TAG}" "Sessão terminada: ${USERNAME} (${FRAMED_IP}) - Duração: ${SESSION_TIME}s"
            fi
        fi
    done
    
    # Limpar ficheiro temporário
    rm -f "${ACTIVE_SESSIONS}"
}

# ===========================
# LOOP PRINCIPAL
# ===========================

while true; do
    # Verificar se arquivo de status existe
    if [ ! -f "${STATUS_LOG}" ]; then
        logger -t "${LOG_TAG}" "AVISO: Status log não encontrado: ${STATUS_LOG}"
        sleep "${INTERIM_INTERVAL}"
        continue
    fi
    
    # Processar clientes conectados
    grep -E "^CLIENT_LIST" "${STATUS_LOG}" | while IFS=',' read -r marker username real_address virtual_address bytes_in bytes_out connected_since common_name real_address_ipv6 virtual_address_ipv6; do
        # Ignorar cabeçalho
        if [ "${username}" = "Common Name" ]; then
            continue
        fi
        
        # Processar cliente
        process_client "${username}" "${virtual_address}" "${bytes_in}" "${bytes_out}" "${connected_since}"
    done
    
    # Processar desconexões
    process_disconnections
    
    # Aguardar intervalo
    sleep "${INTERIM_INTERVAL}"
done
