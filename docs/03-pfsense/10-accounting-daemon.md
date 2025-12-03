# 📊 OpenVPN RADIUS Accounting Daemon

> Daemon de contabilização RADIUS para OpenVPN no pfSense, implementando RFC 2866 (RADIUS Accounting).

---

## 📋 Visão Geral

### O que é RADIUS Accounting?

**RADIUS Accounting** (RFC 2866) é um protocolo que permite registar informações detalhadas sobre sessões de utilizadores, incluindo:

- ✅ **Início de sessão** (Acct-Start)
- 🔄 **Atualizações periódicas** (Acct-Interim-Update)
- ❌ **Fim de sessão** (Acct-Stop)
- 📊 **Estatísticas de tráfego** (bytes enviados/recebidos)
- ⏱️ **Duração da sessão**

### Arquitetura

```
┌─────────────────────┐
│  Cliente OpenVPN    │  1. Conecta ao OpenVPN
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  pfSense OpenVPN    │  2. Autentica via RADIUS (port 1812)
│   192.168.1.1       │  3. Cliente conecta e recebe IP
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Accounting Daemon   │  4. Lê /var/log/openvpn-status.log
│  (Este Script)      │  5. Deteta eventos (connect/update/disconnect)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  FreeRADIUS         │  6. Recebe pacotes Accounting (port 1813)
│   192.168.1.10      │  7. Regista no radius.log e base de dados
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   RADIUS Logs       │  8. Armazena histórico de sessões
│   /var/log/radius/  │     - Auditoria
│   radius.log        │     - Faturação
│                     │     - Compliance
└─────────────────────┘
```

---

## 🔧 Funcionamento

### Fluxo de Eventos

#### 1. Cliente Conecta (Acct-Start)

```
1. Cliente OpenVPN conecta
   ↓
2. pfSense autentica via RADIUS (port 1812)
   ↓
3. Cliente aparece em /var/log/openvpn-status.log
   ↓
4. Daemon deteta nova entrada no log
   ↓
5. Cria session file: /var/openvpn/accounting/<SESSION_ID>
   ↓
6. Envia RADIUS Acct-Start para 192.168.1.10:1813
   Atributos enviados:
   - User-Name: ryan@fsociety.pt
   - Acct-Session-Id: <MD5_HASH>
   - Acct-Status-Type: Start
   - Framed-IP-Address: 10.8.0.15
   - NAS-IP-Address: 192.168.1.1
   - Acct-Input-Octets: 0
   - Acct-Output-Octets: 0
   - Acct-Session-Time: 0
```

#### 2. Atualizações Periódicas (Acct-Interim-Update)

```
1. A cada 30 segundos (INTERIM_INTERVAL)
   ↓
2. Daemon lê openvpn-status.log
   ↓
3. Compara com estado guardado em /var/openvpn/accounting/
   ↓
4. Se cliente ainda conectado com mesmo IP:
   ↓
5. Envia RADIUS Acct-Interim-Update
   Atributos atualizados:
   - Acct-Status-Type: Interim-Update
   - Acct-Input-Octets: <bytes recebidos>
   - Acct-Output-Octets: <bytes enviados>
   - Acct-Session-Time: <tempo em segundos>
```

#### 3. Cliente Desconecta (Acct-Stop)

```
1. Cliente desconecta do OpenVPN
   ↓
2. Entrada desaparece de openvpn-status.log
   ↓
3. Daemon deteta ausência no próximo ciclo
   ↓
4. Lê estado final de /var/openvpn/accounting/<SESSION_ID>
   ↓
5. Envia RADIUS Acct-Stop
   Atributos finais:
   - Acct-Status-Type: Stop
   - Acct-Input-Octets: <total bytes recebidos>
   - Acct-Output-Octets: <total bytes enviados>
   - Acct-Session-Time: <duração total>
   ↓
6. Remove session file
```

#### 4. Mudança de IP (Acct-Stop + Acct-Start)

```
1. Cliente perde conexão e reconecta
   ↓
2. Recebe novo IP do pool RADIUS
   ↓
3. Daemon deteta mudança de IP comparando com estado guardado
   ↓
4. Envia Acct-Stop para IP antigo
   ↓
5. Envia Acct-Start para novo IP
   ↓
6. Atualiza session file com novo IP
```

---

## 📥 Instalação

### 1. Copiar Script para pfSense

**Via WebUI**:

```
Diagnostics → Command Prompt → Upload File
File: accounting-daemon.sh
Destination: /usr/local/bin/
```

**Via SSH**:

```bash
# Conectar ao pfSense
ssh admin@192.168.1.1

# Mudar para root
sudo su -

# Criar ficheiro
vi /usr/local/bin/openvpn-accounting-daemon.sh

# Colar conteúdo do script (docs/03-pfsense/scripts/accounting-daemon.sh)

# Tornar executável
chmod +x /usr/local/bin/openvpn-accounting-daemon.sh
```

### 2. Configurar RADIUS Secret

Editar o script e substituir `<RADIUS_SECRET>`:

```bash
vi /usr/local/bin/openvpn-accounting-daemon.sh
```

Alterar linha:

```bash
RADIUS_SECRET="<RADIUS_SECRET>"
```

Para:

```bash
RADIUS_SECRET="Str0ng!R4d1u5$ecret#2024"
```

**IMPORTANTE**: O secret deve ser o mesmo configurado em:
- FreeRADIUS: `/etc/freeradius/3.0/clients.conf`
- pfSense: `System → User Manager → Authentication Servers → RADIUS-DC-FSociety`

### 3. Verificar Dependências

```bash
# Verificar se radclient está instalado
which radclient

# Se não estiver, instalar FreeRADIUS package no pfSense
# System → Package Manager → Available Packages → FreeRADIUS
```

### 4. Configurar Shellcmd para Auto-Start

```
System → Shellcmd → Add
```

| Campo | Valor |
|-------|-------|
| **Command** | `/usr/local/bin/openvpn-accounting-daemon.sh &` |
| **Shellcmd Type** | shellcmd |
| **Description** | OpenVPN RADIUS Accounting Daemon |

**NOTA**: O `&` no final é importante para executar em background.

### 5. Iniciar Daemon Manualmente

```bash
# Iniciar daemon
/usr/local/bin/openvpn-accounting-daemon.sh &

# Verificar processo
ps aux | grep accounting

# Ver logs
clog /var/log/system.log | grep openvpn-accounting
```

---

## 🔍 Atributos RADIUS Enviados

### Acct-Start

| Atributo | Valor Exemplo | Descrição |
|----------|---------------|-----------|
| **User-Name** | ryan@fsociety.pt | Username do cliente VPN |
| **Acct-Session-Id** | a1b2c3d4e5f6... | Hash MD5 (username + timestamp) |
| **Acct-Status-Type** | Start | Tipo de evento |
| **NAS-IP-Address** | 192.168.1.1 | IP do pfSense |
| **NAS-Identifier** | pfSense-OpenVPN | Identificador do NAS |
| **NAS-Port-Type** | Virtual | Tipo de porta (VPN) |
| **Service-Type** | Framed-User | Tipo de serviço |
| **Framed-IP-Address** | 10.8.0.15 | IP VPN atribuído ao cliente |
| **Framed-Protocol** | PPP | Protocolo de enquadramento |
| **Acct-Input-Octets** | 0 | Bytes recebidos (inicial) |
| **Acct-Output-Octets** | 0 | Bytes enviados (inicial) |
| **Acct-Session-Time** | 0 | Tempo de sessão (inicial) |

### Acct-Interim-Update

| Atributo | Valor Exemplo | Descrição |
|----------|---------------|-----------|
| **Acct-Status-Type** | Interim-Update | Tipo de evento |
| **Acct-Input-Octets** | 15728640 | Bytes recebidos (~15 MB) |
| **Acct-Output-Octets** | 52428800 | Bytes enviados (~50 MB) |
| **Acct-Session-Time** | 1800 | Tempo de sessão (30 min) |

**Outros atributos**: Idênticos ao Acct-Start

### Acct-Stop

| Atributo | Valor Exemplo | Descrição |
|----------|---------------|-----------|
| **Acct-Status-Type** | Stop | Tipo de evento |
| **Acct-Input-Octets** | 104857600 | Total bytes recebidos (~100 MB) |
| **Acct-Output-Octets** | 524288000 | Total bytes enviados (~500 MB) |
| **Acct-Session-Time** | 7200 | Duração total (2 horas) |

**Outros atributos**: Idênticos ao Acct-Start

---

## 📊 Estrutura de Ficheiros

### Diretório de Sessões

```
/var/openvpn/accounting/
├── a1b2c3d4e5f6...    # Session file (hash MD5)
├── b2c3d4e5f6a1...    # Outro session file
└── c3d4e5f6a1b2...    # Outro session file
```

### Formato do Session File

```
ryan@fsociety.pt|10.8.0.15|15728640|52428800|2024-12-02 14:30:15
```

**Campos** (separados por `|`):

1. **Username**: ryan@fsociety.pt
2. **Framed-IP-Address**: 10.8.0.15
3. **Bytes In**: 15728640
4. **Bytes Out**: 52428800
5. **Connected Since**: 2024-12-02 14:30:15

### Logs

```
/var/log/system.log
```

Filtrar por tag `openvpn-accounting`:

```bash
clog /var/log/system.log | grep openvpn-accounting
```

**Exemplos de logs**:

```
Dec 02 14:30:00 pfsense openvpn-accounting[12345]: Daemon iniciado - Intervalo de atualização: 30s
Dec 02 14:30:15 pfsense openvpn-accounting[12345]: Nova sessão: ryan@fsociety.pt (10.8.0.15)
Dec 02 14:30:15 pfsense openvpn-accounting[12345]: RADIUS Acct enviado: ryan@fsociety.pt (Start) - IP: 10.8.0.15
Dec 02 14:30:45 pfsense openvpn-accounting[12345]: RADIUS Acct enviado: ryan@fsociety.pt (Interim-Update) - IP: 10.8.0.15
Dec 02 15:45:30 pfsense openvpn-accounting[12345]: Sessão terminada: ryan@fsociety.pt (10.8.0.15) - Duração: 4500s
Dec 02 15:45:30 pfsense openvpn-accounting[12345]: RADIUS Acct enviado: ryan@fsociety.pt (Stop) - IP: 10.8.0.15
```

---

## 🔍 Configuração FreeRADIUS (DC)

### 1. Ativar Módulo Accounting

```bash
# No Domain Controller (192.168.1.10)
sudo nano /etc/freeradius/3.0/sites-enabled/default
```

**Seção `accounting`**:

```
accounting {
    # Detalhes de contabilização
    detail
    
    # Atributos Unix (opcional)
    unix
    
    # SQL (se configurado)
    # sql
    
    # Responder OK
    exec
    attr_filter.accounting_response
}
```

### 2. Configurar Detail File

```bash
sudo nano /etc/freeradius/3.0/mods-enabled/detail
```

```
detail {
    filename = ${radacctdir}/%{%{Packet-Src-IP-Address}:-%{Packet-Src-IPv6-Address}}/detail-%Y%m%d
    header = "%t"
    permissions = 0600
    locking = no
    escape_filenames = no
    log_packet_header = no
}
```

**Logs gerados**:

```
/var/log/freeradius/radacct/192.168.1.1/detail-20241202
```

### 3. Testar Accounting

```bash
# Enviar Acct-Start de teste
echo "User-Name = test@fsociety.pt, Acct-Session-Id = test123, Acct-Status-Type = Start" | \
radclient -x 192.168.1.10:1813 acct Str0ng!R4d1u5$ecret#2024
```

**Resultado esperado**:

```
Sent Accounting-Request Id 1 from 0.0.0.0:54321 to 192.168.1.10:1813 length 76
Received Accounting-Response Id 1 from 192.168.1.10:1813 to 0.0.0.0:54321 length 20
```

### 4. Ver Logs de Accounting

```bash
# Logs principais
sudo tail -f /var/log/freeradius/radius.log | grep Accounting

# Detail files
sudo cat /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d)
```

**Exemplo de entrada**:

```
Tue Dec  2 14:30:15 2024
    Packet-Type = Accounting-Request
    Acct-Status-Type = Start
    User-Name = "ryan@fsociety.pt"
    Acct-Session-Id = "a1b2c3d4e5f6789"
    NAS-IP-Address = 192.168.1.1
    NAS-Identifier = "pfSense-OpenVPN"
    Framed-IP-Address = 10.8.0.15
    Acct-Input-Octets = 0
    Acct-Output-Octets = 0
    Acct-Session-Time = 0
    Timestamp = 1701522615
```

---

## 📈 Casos de Uso

### 1. Auditoria de Acessos

**Questão**: Quem acedeu à VPN nas últimas 24 horas?

```bash
# No DC
sudo grep "Acct-Status-Type = Start" /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d) | \
grep "User-Name"
```

### 2. Tempo de Sessão por Utilizador

**Questão**: Quanto tempo o ryan@fsociety.pt esteve conectado?

```bash
# Procurar Acct-Stop do utilizador
sudo grep -A 10 "ryan@fsociety.pt" /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d) | \
grep "Acct-Session-Time"
```

### 3. Consumo de Dados

**Questão**: Quantos dados o utilizador transferiu?

```bash
# Procurar último Acct-Stop
sudo grep -A 15 "ryan@fsociety.pt" /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d) | \
grep -E "Acct-Input-Octets|Acct-Output-Octets"
```

### 4. Deteção de Anomalias

**Questão**: Algum utilizador com consumo anormal de dados?

```bash
# Listar utilizadores com mais de 1 GB de dados
sudo grep "Acct-Stop" /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d) -A 15 | \
awk '/User-Name/{user=$3} /Acct-Input-Octets/{in=$3} /Acct-Output-Octets/{out=$3; if((in+out)>1073741824) print user, in+out}'
```

### 5. Compliance (RGPD/ISO 27001)

- ✅ Registo de todos os acessos VPN
- ✅ Rastreabilidade de sessões (Session ID único)
- ✅ Timestamp de início/fim
- ✅ IP atribuído e origem
- ✅ Retenção de logs para auditoria

---

## 🐛 Troubleshooting

### Daemon não inicia

**Sintoma**: Processo não aparece em `ps aux`

**Diagnóstico**:

```bash
# Verificar erro na execução
sh -x /usr/local/bin/openvpn-accounting-daemon.sh

# Verificar permissões
ls -la /usr/local/bin/openvpn-accounting-daemon.sh

# Verificar sintaxe
sh -n /usr/local/bin/openvpn-accounting-daemon.sh
```

**Solução**:

```bash
# Tornar executável
chmod +x /usr/local/bin/openvpn-accounting-daemon.sh

# Verificar shebang
head -1 /usr/local/bin/openvpn-accounting-daemon.sh
# Deve ser: #!/bin/sh
```

### RADIUS Accounting não chega ao servidor

**Sintoma**: Logs pfSense mostram envio, mas FreeRADIUS não recebe

**Diagnóstico**:

```bash
# No pfSense - testar conectividade
ping 192.168.1.10

# Testar porta UDP 1813
nc -u -v 192.168.1.10 1813

# No DC - verificar porta aberta
sudo netstat -ulpn | grep 1813

# Capturar pacotes
sudo tcpdump -i any port 1813 -vv
```

**Solução**:

- Verificar firewall pfSense permite saída para 1813/UDP
- Verificar firewall DC permite entrada de 192.168.1.1:1813/UDP
- Verificar FreeRADIUS a escutar na porta 1813

### Secret incorreto

**Sintoma**: Logs mostram "Invalid shared secret"

**Diagnóstico**:

```bash
# No pfSense
grep "RADIUS_SECRET" /usr/local/bin/openvpn-accounting-daemon.sh

# No DC
sudo grep "secret" /etc/freeradius/3.0/clients.conf | grep pfsense -A 3
```

**Solução**:

```bash
# Atualizar secret no script
vi /usr/local/bin/openvpn-accounting-daemon.sh

# Deve corresponder exatamente ao configurado no FreeRADIUS
```

### Status log não existe

**Sintoma**: Log mostra "Status log não encontrado"

**Diagnóstico**:

```bash
# Verificar se OpenVPN está a escrever status log
ls -la /var/log/openvpn-status.log

# Verificar configuração OpenVPN
grep -r "status" /var/etc/openvpn/
```

**Solução**:

```
VPN → OpenVPN → Servers → Edit

Advanced Configuration:
status /var/log/openvpn-status.log 30

Restart OpenVPN:
Status → OpenVPN → Restart
```

### Sessões não terminam (Acct-Stop não enviado)

**Sintoma**: Session files acumulam em `/var/openvpn/accounting/`

**Diagnóstico**:

```bash
# Listar session files
ls -la /var/openvpn/accounting/

# Verificar idade dos ficheiros
find /var/openvpn/accounting/ -type f -mmin +60
```

**Solução**:

```bash
# Limpeza manual de sessões antigas (>1 hora)
find /var/openvpn/accounting/ -type f -mmin +60 -delete

# Verificar lógica de deteção de desconexão no script
```

### Interim-Update muito frequente

**Sintoma**: Servidor RADIUS sobrecarregado

**Solução**:

```bash
# Aumentar intervalo de atualização
vi /usr/local/bin/openvpn-accounting-daemon.sh

# Alterar de 30 para 60 segundos
INTERIM_INTERVAL=60

# Reiniciar daemon
pkill -f openvpn-accounting-daemon
/usr/local/bin/openvpn-accounting-daemon.sh &
```

---

## 🔒 Segurança

### Proteção do RADIUS Secret

```bash
# Permissões restritas
chmod 700 /usr/local/bin/openvpn-accounting-daemon.sh

# Apenas root pode ler
chown root:wheel /usr/local/bin/openvpn-accounting-daemon.sh
```

### Rate Limiting no FreeRADIUS

```bash
# Limitar número de pacotes Accounting por segundo
sudo nano /etc/freeradius/3.0/radiusd.conf
```

```
# Security settings
security {
    max_requests_per_client = 1000
}
```

### Rotação de Logs

```bash
# No DC - configurar logrotate
sudo nano /etc/logrotate.d/freeradius
```

```
/var/log/freeradius/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /bin/kill -HUP `cat /var/run/freeradius/freeradius.pid`
    endscript
}

/var/log/freeradius/radacct/*/* {
    monthly
    rotate 12
    missingok
    notifempty
    compress
}
```

---

## 📊 Monitorização

### Dashboard Grafana (Opcional)

Se integrar FreeRADIUS com SQL:

```sql
-- Sessões ativas
SELECT User_Name, Framed_IP_Address, Acct_Session_Time
FROM radacct
WHERE Acct_Stop_Time IS NULL;

-- Top 10 utilizadores por dados transferidos
SELECT User_Name, 
       SUM(Acct_Input_Octets + Acct_Output_Octets) as total_bytes
FROM radacct
WHERE Acct_Start_Time > DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY User_Name
ORDER BY total_bytes DESC
LIMIT 10;

-- Tempo médio de sessão
SELECT AVG(Acct_Session_Time) as avg_session_time
FROM radacct
WHERE Acct_Stop_Time IS NOT NULL
AND Acct_Start_Time > DATE_SUB(NOW(), INTERVAL 7 DAY);
```

### Alertas

```bash
# Script para alertar sobre sessões longas (>8 horas)
sudo nano /usr/local/bin/check-long-sessions.sh
```

```bash
#!/bin/bash
THRESHOLD=28800  # 8 horas em segundos

grep "Interim-Update" /var/log/freeradius/radacct/192.168.1.1/detail-$(date +%Y%m%d) -A 15 | \
awk '/User-Name/{user=$3} /Acct-Session-Time/{time=$3; if(time>'"$THRESHOLD"') print user, time}' | \
while read user time; do
    echo "ALERTA: Sessão longa detectada - ${user} - ${time}s" | \
    mail -s "VPN Session Alert" admin@fsociety.pt
done
```

---

## 🎓 Informação Académica

### Contexto Académico

Este daemon foi desenvolvido como parte do projeto FSociety.pt no âmbito da Unidade Curricular de **Administração de Sistemas II**.

### Objetivos de Aprendizagem

- ✅ Implementar protocolo RADIUS Accounting (RFC 2866)
- ✅ Parsing e processamento de logs em shell script
- ✅ Gestão de estado e persistência de dados
- ✅ Integração entre sistemas (pfSense + FreeRADIUS)
- ✅ Auditoria e compliance em infraestruturas VPN

### Competências Desenvolvidas

| Competência | Descrição |
|-------------|-----------|
| **Shell Scripting** | Daemon robusto com gestão de estado |
| **Protocolos de Rede** | RADIUS Accounting, UDP |
| **Segurança** | Auditoria, rastreabilidade, compliance |
| **Integração** | OpenVPN, FreeRADIUS, LDAP |
| **Troubleshooting** | Diagnóstico e resolução de problemas |

---

## 📄 Informação do Projeto

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |
| **Desenvolvedor do Daemon** | Hugo Correia |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

## 📖 Referências

### RFCs

- [RFC 2865 - RADIUS Authentication](https://www.rfc-editor.org/rfc/rfc2865)
- [RFC 2866 - RADIUS Accounting](https://www.rfc-editor.org/rfc/rfc2866)
- [RFC 2869 - RADIUS Extensions](https://www.rfc-editor.org/rfc/rfc2869)

### Documentação Técnica

- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [FreeRADIUS Accounting](https://wiki.freeradius.org/guide/Accounting)
- [OpenVPN Management Interface](https://openvpn.net/community-resources/management-interface/)
- [pfSense OpenVPN](https://docs.netgate.com/pfsense/en/latest/vpn/openvpn/)

### Ferramentas Utilizadas

- [radclient](https://freeradius.org/radiusd/man/radclient.html) - Cliente RADIUS de linha de comandos
- [tcpdump](https://www.tcpdump.org/) - Análise de tráfego de rede
- [logger](https://man.freebsd.org/cgi/man.cgi?query=logger) - Envio de mensagens para syslog

---

<div align="center">

**[⬅️ Voltar: Manutenção](09-manutencao.md)** | **[Índice](README.md)**

</div>

---

*Última atualização: Dezembro 2024*
