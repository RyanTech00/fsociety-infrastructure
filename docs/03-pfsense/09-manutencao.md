# 🔧 Manutenção

> Guia completo de manutenção, backup, atualização, monitorização e troubleshooting do pfSense.

---

## 💾 Backup da Configuração

### Backup Manual

```
Diagnostics → Backup & Restore → Backup
```

#### Opções de Backup

| Opção | Valor | Descrição |
|-------|-------|-----------|
| **Backup area** | ALL | Toda a configuração |
| **Skip RRD data** | ✅ | Excluir gráficos (reduz tamanho) |
| **Skip package info** | ❌ | Incluir info de packages |
| **Encrypt** | ✅ Recomendado | Cifrar com password |

**Procedimento**:
```
1. Diagnostics → Backup & Restore
2. Backup area: ALL
3. Skip RRD data: ✅
4. Encryption: ✅
5. Password: (senha forte)
6. Download configuration

Resultado: config-pfSense.fsociety.pt-[timestamp].xml
```

### Backup Automático

#### Via Cron (Diário)

```
Services → Cron → Add

Minute: 0
Hour: 3
Day of month: *
Month: *
Day of week: *
User: root
Command: /usr/local/bin/php -r "require_once('config.inc'); write_config('Auto backup - daily');"

Description: Daily config backup
```

#### Backup para Servidor Remoto

```bash
#!/bin/sh
# /usr/local/bin/backup-pfsense-remote.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="/cf/conf/backup/config-${DATE}.xml"
REMOTE_SERVER="192.168.1.30"
REMOTE_USER="backup"
REMOTE_PATH="/backups/pfsense"

# Criar backup
/usr/local/bin/php -r "require_once('config.inc'); write_config('Remote backup');"

# Copiar último backup para servidor remoto
LATEST_BACKUP=$(ls -t /cf/conf/backup/config-*.xml | head -1)
scp ${LATEST_BACKUP} ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_PATH}/

# Cleanup local (manter 30 dias)
find /cf/conf/backup/ -name "config-*.xml" -mtime +30 -delete

# Enviar notificação (opcional)
echo "pfSense backup completed: ${DATE}" | mail -s "pfSense Backup" admin@fsociety.pt
```

**Adicionar ao Shellcmd**:
```
Services → Shellcmd → Add

Command: /usr/local/bin/backup-pfsense-remote.sh
Shellcmd Type: shellcmd
Description: Remote backup at boot
```

### Versões de Backup

```
Diagnostics → Backup & Restore → Config History

Lista as últimas 30 versões (configurável):
- config-1701518400.xml (2024-12-02 10:00:00)
- config-1701432000.xml (2024-12-01 10:00:00)
...

Actions:
- View: Ver configuração
- Restore: Restaurar versão
- Download: Download do arquivo
- Delete: Eliminar versão
```

### Restaurar Backup

```
Diagnostics → Backup & Restore → Restore

1. Browse: Selecionar arquivo config.xml
2. Encryption Password: (se cifrado)
3. Restore área: ALL
4. Restore Configuration

⚠️ AVISO: Sistema reiniciará após restore
```

---

## 🔄 Atualizações do pfSense

### Verificar Updates

```
System → Update

Status atual: 2.8.1-RELEASE
Branch: Stable

Check for Updates → Verificar atualizações disponíveis
```

### Update via WebGUI

```
System → Update

Se update disponível:
1. Ver release notes
2. Fazer backup (SEMPRE!)
3. Confirmar update
4. Aguardar download + instalação
5. Sistema reinicia automaticamente
6. Verificar versão após reboot
```

### Update via CLI

```bash
# SSH no pfSense
pfSense-upgrade -d

# Ver versão atual
cat /etc/version

# Ver updates disponíveis
pkg-static upgrade -n

# Fazer update
pfSense-upgrade

# Reboot
shutdown -r now
```

### Rollback de Update

Se update causar problemas:

```
1. Boot no modo Single User
2. Pressionar 4 (Single User Mode)
3. Montar filesystem:
   mount -u /
   mount -a

4. Restaurar backup anterior:
   pfSsh.php playback restorebackup /cf/conf/backup/config-[timestamp].xml

5. Reboot:
   reboot
```

---

## 📊 Monitorização

### Dashboard

```
Status → Dashboard

Widgets principais:
- System Information
- Interfaces
- Services Status
- Gateways
- Traffic Graphs
```

#### Adicionar Widgets

```
Status → Dashboard → Available Widgets

Úteis:
- ✅ System Information
- ✅ Interfaces
- ✅ Services Status
- ✅ Gateways
- ✅ Traffic Graphs
- ✅ OpenVPN
- ✅ IPsec
- ✅ Firewall Logs
```

### Métricas Importantes

#### CPU Usage

```
Status → Dashboard → System Information

CPU usage: Normal < 30%
Alerta se > 80% sustained
```

**Causas comuns de CPU alto**:
- Tráfego elevado
- Regras de firewall complexas
- ntopng ativo
- Cryptografia VPN

#### Memory Usage

```
Status → Dashboard → System Information

Memory usage: Normal < 50%
Alerta se > 85%

Total: 1991 MiB
Used: ~800 MiB (40%)
Free: ~1191 MiB (60%)
```

#### Disk Usage

```
Status → Dashboard → System Information

Disk usage: Normal < 70%
Alerta se > 85%

Total: 42 GB
Used: 2.5 GB (6%)
Free: 39.5 GB (94%)
```

**Limpar espaço**:
```bash
# Limpar logs antigos
rm /var/log/*.log.*

# Limpar package cache
pkg-static clean

# Limpar RRD old data
rm /var/db/rrd/*-old.rrd
```

#### Temperatura (se disponível)

```bash
# Ver temperatura CPU
sysctl dev.cpu | grep temperature

# Ou via sensors
smbios-ctl --list
```

### ntopng - Monitorização Avançada

```
Services → ntopng
URL: http://192.168.1.1:3000
```

**Dashboards**:
- **Traffic**: Bandwidth por interface
- **Hosts**: Top talkers, geolocalização
- **Flows**: Conexões ativas
- **Alerts**: Anomalias, port scans
- **Statistics**: Protocolos, apps

**Alertas Úteis**:
- Port scan detected
- Syn flooding
- Suspicious traffic pattern
- New device on network

---

## 📝 Logs

### Logs Principais

| Log | Localização | Descrição |
|-----|------------|-----------|
| **System** | Status → System Logs → System | Logs gerais do sistema |
| **Firewall** | Status → System Logs → Firewall | Tráfego bloqueado/permitido |
| **DHCP** | Status → System Logs → DHCP | Leases DHCP |
| **DNS** | Status → System Logs → Resolver | Queries DNS (unbound) |
| **OpenVPN** | Status → System Logs → OpenVPN | Conexões VPN |
| **NTP** | Status → System Logs → NTP | Sincronização de tempo |

### Configurar Logging

```
Status → System Logs → Settings

General Logging Options:
- Reverse: ✅ Show log entries in reverse order
- GUI Log Entries: 500
- Log Firewall Default Blocks: ✅

Firewall Logging:
- Log packets matched from default block: ✅
- Log packets matched from default pass: ❌
- Log bogon blocked: ✅
```

### Remote Syslog

```
Status → System Logs → Settings → Remote Logging

Remote Logging Options:
- Enable: ✅
- Source Address: (auto)
- IP Protocol: IPv4
- Remote log servers:
  - Server 1: 192.168.1.50:514 (Wazuh)
  - Server 2: (opcional)

Remote Syslog Contents:
- ✅ System events
- ✅ Firewall events
- ✅ DHCP service events
- ✅ OpenVPN events
```

### Ver Logs via CLI

```bash
# System log
clog /var/log/system.log | tail -50

# Firewall log
clog /var/log/filter.log | tail -100

# OpenVPN log
clog /var/log/openvpn.log | tail -50

# Logs em tempo real
tail -f /var/log/system.log

# Filtrar por IP
clog /var/log/filter.log | grep 192.168.1.10

# Filtrar por porta
clog /var/log/filter.log | grep "DPT:443"
```

---

## 🔍 Troubleshooting Comum

### 1. Sem conectividade à Internet

**Sintomas**:
- LAN não acede Internet
- DNS não resolve

**Diagnóstico**:
```
1. Ping gateway WAN:
   Diagnostics → Ping → 192.168.31.1

2. Ping DNS público:
   Diagnostics → Ping → 1.1.1.1

3. Ver regras LAN:
   Firewall → Rules → LAN
   (verificar regra permitindo Internet)

4. Ver estados:
   Diagnostics → States
   (procurar conexões LAN → Internet)
```

**Soluções**:
- Verificar gateway WAN online
- Verificar regras de firewall LAN
- Verificar NAT outbound ativo
- Verificar DNS servers

### 2. Firewall bloqueia tráfego legítimo

**Sintomas**:
- Aplicação não funciona
- Serviço não acessível

**Diagnóstico**:
```
1. Ver logs firewall:
   Status → System Logs → Firewall
   (procurar por blocked)

2. Identificar:
   - Source IP
   - Destination IP
   - Port
   - Protocol

3. Ver regras da interface:
   Firewall → Rules → [Interface]
```

**Solução**:
```
Adicionar regra de pass:
Firewall → Rules → [Interface] → Add

Action: Pass
Protocol: [TCP/UDP]
Source: [IP origem]
Destination: [IP destino]
Port: [porta]

Save → Apply Changes
```

### 3. VPN não conecta

**Sintomas**:
- Connection timeout
- Authentication failed

**Diagnóstico**:
```
1. Verificar serviço:
   Status → OpenVPN
   (deve estar "up")

2. Verificar porta WAN:
   Firewall → Rules → WAN
   (regra UDP 1194/1195)

3. Ver logs:
   Status → System Logs → OpenVPN

4. Testar RADIUS (se aplicável):
   Diagnostics → Authentication
```

**Soluções**:
- Verificar serviço OpenVPN ativo
- Verificar porta firewall
- Verificar certificados válidos
- Verificar RADIUS server

### 4. Alta utilização CPU

**Sintomas**:
- CPU > 80% sustained
- Interface lenta

**Diagnóstico**:
```bash
# Via SSH
top -P

# Ver processos
ps aux | sort -nrk 3,3 | head -10
```

**Causas comuns**:
- ntopng (desativar se não necessário)
- Tráfego VPN elevado
- Port scan / ataque
- Regras de firewall muito complexas

**Soluções**:
- Otimizar regras de firewall
- Desativar ntopng temporariamente
- Bloquear IPs atacantes
- Aumentar CPU/RAM da VM

### 5. Espaço em disco cheio

**Sintomas**:
- Disk usage > 90%
- Cannot write to disk

**Diagnóstico**:
```bash
# Ver uso
df -h

# Ver ficheiros grandes
du -sh /* | sort -h
```

**Solução**:
```bash
# Limpar logs
rm /var/log/*.log.*

# Limpar cache packages
pkg-static clean

# Limpar backups antigos
find /cf/conf/backup/ -name "*.xml" -mtime +90 -delete
```

---

## 🛠️ Comandos Úteis

### pfctl (Firewall Control)

```bash
# Ver regras ativas
pfctl -sr

# Ver NAT rules
pfctl -sn

# Ver estados
pfctl -ss

# Ver estatísticas
pfctl -si

# Reload regras (cuidado!)
pfctl -F all -f /tmp/rules.debug

# Ver tabelas
pfctl -t -T show

# Reset estados (CUIDADO!)
pfctl -F states
```

### Rede

```bash
# Ver interfaces
ifconfig

# Ver rotas
netstat -rn

# Ver conexões ativas
sockstat -4

# Ver portas em escuta
sockstat -4l

# Ping com source específico
ping -S 192.168.1.1 8.8.8.8

# Traceroute
traceroute 8.8.8.8
```

### Sistema

```bash
# Ver versão
cat /etc/version

# Ver uptime
uptime

# Ver processos
ps aux

# Ver uso de recursos
top

# Ver logs em tempo real
tail -f /var/log/system.log

# Reiniciar serviço
/etc/rc.restart_webgui
/etc/rc.restart_dhcpd

# Reboot sistema
shutdown -r now

# Halt sistema
shutdown -h now
```

### Backup e Restore

```bash
# Backup config
cp /cf/conf/config.xml /tmp/config-backup-$(date +%Y%m%d).xml

# Restore config
cp /tmp/config-backup.xml /cf/conf/config.xml
/etc/rc.reload_all

# Ver configurações anteriores
ls -lh /cf/conf/backup/
```

---

## 📋 Checklist de Manutenção

### Diário

- [ ] Verificar Dashboard (CPU, Memory, Disk)
- [ ] Verificar Services Status (todos ✅)
- [ ] Ver Firewall Logs (procurar anomalias)
- [ ] Verificar OpenVPN clients conectados

### Semanal

- [ ] Verificar updates disponíveis
- [ ] Revisar logs de firewall
- [ ] Verificar espaço em disco
- [ ] Testar backup restore (ambiente teste)
- [ ] Verificar alertas ntopng

### Mensal

- [ ] Fazer backup completo
- [ ] Aplicar updates (se disponíveis)
- [ ] Limpar logs antigos (> 30 dias)
- [ ] Revisar regras de firewall (remover não usadas)
- [ ] Testar VPN (Local e RADIUS)
- [ ] Verificar certificados (expiração)
- [ ] Auditar utilizadores VPN

### Trimestral

- [ ] Testar disaster recovery
- [ ] Atualizar documentação
- [ ] Revisar aliases (remover não usados)
- [ ] Otimizar performance
- [ ] Auditar logs de segurança

---

## 🚨 Plano de Disaster Recovery

### Cenário 1: pfSense Falha

**Ação**:
```
1. Verificar VM no Proxmox
2. Tentar restart: qm start [vmid]
3. Se não arrancar:
   - Criar nova VM
   - Instalar pfSense fresh
   - Restore último backup
4. Verificar todas as interfaces
5. Testar conectividade
```

### Cenário 2: Configuração Corrompida

**Ação**:
```
1. Boot em Safe Mode
2. Restore backup anterior:
   Diagnostics → Backup & Restore
3. Ou via CLI:
   pfSsh.php playback restorebackup /path/to/backup.xml
4. Verificar funcionalidade
```

### Cenário 3: Perda Total

**Ação**:
```
1. Reinstalar pfSense (ver instalação.md)
2. Configurar interfaces básicas
3. Restore backup mais recente
4. Verificar:
   - Interfaces
   - Regras firewall
   - NAT
   - OpenVPN
   - Services
5. Testar tudo funciona
```

### RTO/RPO

| Métrica | Objetivo | Descrição |
|---------|----------|-----------|
| **RTO** | < 1 hora | Recovery Time Objective |
| **RPO** | < 24 horas | Recovery Point Objective |
| **Backup Frequency** | Diário | Automático via cron |
| **Backup Retention** | 30 dias | Local + remoto |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

## 📖 Referências

- [pfSense Backup & Restore](https://docs.netgate.com/pfsense/en/latest/backup/index.html)
- [pfSense Upgrades](https://docs.netgate.com/pfsense/en/latest/install/upgrade-guide.html)
- [pfSense Troubleshooting](https://docs.netgate.com/pfsense/en/latest/troubleshooting/index.html)
- [pfctl Command Reference](https://docs.netgate.com/pfsense/en/latest/firewall/pfctl.html)

---

<div align="center">

**[⬅️ Voltar: Packages e Serviços](08-packages-servicos.md)** | **[Índice](README.md)**

</div>

---

*Última atualização: Dezembro 2025*
