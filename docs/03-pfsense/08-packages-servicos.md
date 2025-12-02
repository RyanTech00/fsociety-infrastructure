# 📦 Packages e Serviços

> Documentação dos packages instalados e serviços ativos no pfSense.

---

## 📋 Packages Instalados

```
System → Package Manager → Installed Packages
```

| Package | Versão | Descrição | Status |
|---------|--------|-----------|--------|
| **Cron** | 0.3.8_6 | Agendamento de tarefas | ✅ Ativo |
| **FreeRADIUS3** | 0.15.14 | RADIUS server (backup local) | ⚠️ Standby |
| **HAProxy** | 0.63_11 | Load Balancer / Reverse Proxy | ❌ Stopped |
| **iperf** | 3.0.5 | Testes de desempenho de rede | 📊 On-demand |
| **ntopng** | 6.2.0 | Monitorização de tráfego | ✅ Ativo |
| **openvpn-client-export** | 1.9.5 | Exportação de configs VPN | 🔧 Utility |
| **Shellcmd** | 1.0.5_4 | Scripts de inicialização | ✅ Ativo |

---

## 🔧 Detalhes dos Packages

### 1. Cron

**Função**: Agendamento automático de tarefas periódicas.

**Localização**: `Services → Cron`

#### Tarefas Configuradas

| Tarefa | Frequência | Comando | Descrição |
|--------|-----------|---------|-----------|
| **Config Backup** | Diário (03:00) | `/etc/rc.config_backup` | Backup automático da configuração |
| **Package Update Check** | Semanal (Dom 02:00) | `/usr/local/sbin/pfSense-upgrade -c` | Verificar updates |
| **Filter Reload** | Horário | `/etc/rc.filter_configure` | Reload regras firewall |

#### Adicionar Nova Tarefa

```
Services → Cron → Add

Minute: 0
Hour: 3
Day of month: *
Month: *
Day of week: *
User: root
Command: /usr/local/bin/example-script.sh

Save
```

---

### 2. FreeRADIUS3

**Função**: RADIUS server local (backup, não usado em produção).

**Status**: ⚠️ Instalado mas desativado (usamos RADIUS do DC)

**Localização**: `Services → FreeRADIUS`

#### Configuração (Backup)

```
Interfaces: LAN
Authentication Port: 1812
Accounting Port: 1813
Status: ❌ Disabled

Nota: Em produção, usamos RADIUS do DC (192.168.1.10)
      Este package serve apenas como backup de emergência
```

#### Quando Usar

- **Emergência**: Se DC estiver offline
- **Testes**: Validar configurações localmente
- **Desenvolvimento**: Testar novos setups

#### Ativar em Emergência

```
1. Services → FreeRADIUS → Enable
2. System → User Manager → Authentication Servers
   - Criar servidor RADIUS local (127.0.0.1)
3. VPN → OpenVPN → Servers → Edit
   - Mudar backend para RADIUS local
4. Restart OpenVPN
```

---

### 3. HAProxy

**Função**: Load Balancer e Reverse Proxy HTTP/HTTPS.

**Status**: ❌ Stopped (não utilizado atualmente)

**Localização**: `Services → HAProxy`

#### Caso de Uso Futuro

```
Cenário: Load balancing para múltiplos webservers

Frontend:
- Bind: WAN:80, WAN:443
- Mode: HTTP
- Backend: webserver_pool

Backend webserver_pool:
- Mode: HTTP
- Balance: roundrobin
- Servers:
  - web1: 10.0.0.30:80
  - web2: 10.0.0.31:80
  - web3: 10.0.0.32:80

Health Check:
- Check: GET /health
- Interval: 5s
```

#### Configuração SSL Termination

```
Frontend HTTPS:
- SSL Offloading: ✅
- Certificate: (import SSL cert)
- Backend: HTTP (unencrypted to internal servers)

Vantagens:
- SSL/TLS centralizado
- Reduz carga dos backends
- Facilita gestão de certificados
```

---

### 4. iperf

**Função**: Ferramenta de teste de desempenho de rede.

**Status**: 📊 On-demand (usa quando necessário)

**Localização**: CLI apenas

#### Usar iperf

**Servidor (no pfSense)**:
```bash
# SSH no pfSense
iperf3 -s -p 5201

Server listening on 5201
```

**Cliente (outro host)**:
```bash
# Teste TCP
iperf3 -c 192.168.1.1 -p 5201 -t 30

# Teste UDP
iperf3 -c 192.168.1.1 -p 5201 -u -b 100M -t 30

# Reverse mode (download)
iperf3 -c 192.168.1.1 -p 5201 -R
```

#### Casos de Uso

- **Troubleshooting**: Identificar bottlenecks
- **Validação**: Verificar throughput após mudanças
- **Baseline**: Estabelecer performance esperada
- **VPN Performance**: Testar throughput VPN

#### Exemplo: Testar VPN

```bash
# No pfSense (servidor)
iperf3 -s

# Cliente VPN conectado (10.8.0.15)
iperf3 -c 192.168.1.1 -t 60

# Resultado esperado: 50-200 Mbps dependendo de:
# - CPU encryption performance
# - Internet bandwidth
# - Latência
```

---

### 5. ntopng

**Função**: Monitorização avançada de tráfego de rede.

**Status**: ✅ Running

**Localização**: `Services → ntopng`

#### Configuração

```
Enable ntopng: ✅

Interfaces to Monitor:
- ✅ WAN (vtnet0)
- ✅ LAN (vtnet1)
- ✅ DMZ (vtnet2)
- ✅ OpenVPN (ovpns1, ovpns2)

Local Networks:
192.168.1.0/24, 10.0.0.0/24, 10.8.0.0/24, 10.9.0.0/24

Listen Port: 3000
Redis Server: 127.0.0.1:6379
DNS Mode: Decode DNS responses
```

#### Acesso

```
URL: http://192.168.1.1:3000
Username: admin
Password: (definido na instalação)
```

#### Features Principais

**1. Dashboard**:
- Tráfego total por interface
- Top talkers (hosts mais ativos)
- Protocols distribution
- Alertas em tempo real

**2. Flows**:
- Conexões ativas
- Source/Destination
- Bytes transferred
- Duration

**3. Hosts**:
- Lista de hosts ativos
- Traffic analysis por host
- Geolocalização
- Historical data

**4. Alerts**:
- Suspicious activities
- Port scans
- DDoS attempts
- Anomalias de tráfego

#### Exemplos de Análise

**Top 10 Hosts por Tráfego**:
```
Dashboard → Hosts → Sort by Traffic

1. 10.0.0.20 (Mailcow) - 5.2 GB ↓ / 1.8 GB ↑
2. 10.0.0.30 (Webserver) - 12.5 GB ↓ / 850 MB ↑
3. 192.168.1.40 (Nextcloud) - 2.1 GB ↓ / 3.5 GB ↑
```

**Protocolos Mais Usados**:
```
Dashboard → Protocols

1. HTTPS (443) - 75%
2. HTTP (80) - 12%
3. SMTP (25) - 8%
4. SSH (22) - 3%
5. Others - 2%
```

**Alertas Recentes**:
```
Alerts → View Alerts

[HIGH] Port scan detected from 203.0.113.50
[MEDIUM] Unusual traffic spike on WAN
[INFO] New device joined network: 192.168.1.150
```

---

### 6. openvpn-client-export

**Função**: Gerar e exportar configurações de cliente OpenVPN.

**Status**: 🔧 Utility (sempre disponível)

**Localização**: `VPN → OpenVPN → Client Export`

#### Utilização

```
VPN → OpenVPN → Client Export

1. Selecionar servidor OpenVPN
2. Configurar opções:
   - Host Name Resolution: Other
   - Host Name: vpn.fsociety.pt
3. Escolher tipo de export:
   - Inline Configuration (.ovpn)
   - Windows Installer (.exe)
   - Viscosity (macOS)
   - Archive (multiple configs)
4. Selecionar utilizador (se aplicável)
5. Download
```

#### Tipos de Export

| Tipo | Formato | Plataforma | Inclui |
|------|---------|------------|--------|
| **Inline Config** | .ovpn | Todas | Certificados embedidos |
| **Windows Installer** | .exe | Windows | Auto-install + config |
| **Viscosity Bundle** | .visc | macOS | Importar direto |
| **Archive** | .zip | Todas | Múltiplos arquivos |

#### Personalização

```
VPN → OpenVPN → Client Export → Advanced

Custom Options:
- Use Random Local Port: ✅
- Use TLS-Authentication: ✅
- Block Outside DNS: ✅
- Legacy Client Support: ❌
- Silent Installer: ✅ (Windows)
```

---

### 7. Shellcmd

**Função**: Executar comandos shell durante boot do sistema.

**Status**: ✅ Ativo

**Localização**: `Services → Shellcmd`

#### Comandos Configurados

| Comando | Timing | Descrição |
|---------|--------|-----------|
| `/usr/local/bin/custom-firewall-init.sh` | Early | Inicialização firewall custom |
| `/usr/local/bin/backup-to-remote.sh` | Late | Backup remoto após boot |

#### Adicionar Comando

```
Services → Shellcmd → Add

Command: /usr/local/bin/example.sh
Shellcmd Type: shellcmd (bootup)
Description: Example startup script

Save
```

#### Exemplo: Script de Backup Automático

```bash
#!/bin/sh
# /usr/local/bin/backup-to-remote.sh

# Backup config to remote server
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="/tmp/config-backup-${DATE}.xml"

# Export config
/usr/local/bin/php -r "require_once('config.inc'); \$config['system']['backupcount'] = 30; write_config();"

# Copy to remote (via SCP)
scp /cf/conf/backup/config-*.xml backup@192.168.1.30:/backups/pfsense/

# Cleanup old local backups (keep 7 days)
find /cf/conf/backup/ -name "config-*.xml" -mtime +7 -delete
```

---

## 🔄 Serviços do Sistema

```
Status → Services
```

### Serviços Ativos

| Serviço | Status | PID | Descrição |
|---------|--------|-----|-----------|
| **dhcpd** | ✅ Running | 1234 | DHCP Server |
| **dpinger** | ✅ Running | 1235 | Gateway monitoring |
| **ntopng** | ✅ Running | 1236 | Network traffic monitoring |
| **ntpd** | ✅ Running | 1237 | NTP time sync |
| **openvpn** (server1) | ✅ Running | 1238 | OpenVPN Local (1194) |
| **openvpn** (server2) | ✅ Running | 1239 | OpenVPN RADIUS (1195) |
| **sshd** | ✅ Running | 1240 | SSH daemon |
| **syslogd** | ✅ Running | 1241 | System logging |
| **unbound** | ✅ Running | 1242 | DNS resolver |

### Gerir Serviços

#### Restart Serviço

```
Status → Services → Restart (ícone)

Ou via CLI:
/usr/local/etc/rc.d/[service].sh restart

Exemplos:
/usr/local/etc/rc.d/ntopng.sh restart
/usr/local/etc/rc.d/openvpn.sh restart
```

#### Ver Logs de Serviço

```
Status → System Logs → [Service Tab]

Ou via CLI:
clog /var/log/[service].log | tail -50

Exemplos:
clog /var/log/dhcpd.log
clog /var/log/openvpn.log
```

---

## 📊 Monitorização de Packages

### Ver Utilização de Recursos

```
Status → Dashboard

Widgets:
- System Information (CPU, Memory, Disk)
- Services Status
- Interfaces (Bandwidth)
- Gateway (Latency, Loss)
```

### CPU Usage por Serviço

```bash
# Via SSH
top -P

# Ver específico
ps aux | grep [service]

# Exemplo: ver OpenVPN
ps aux | grep openvpn
```

### Memory Usage

```bash
# Ver uso total
top

# Ver por processo
ps aux --sort=-%mem | head -10

# Serviços que mais consomem:
# 1. ntopng (~200-300 MB)
# 2. unbound (~50-100 MB)
# 3. openvpn (~30-50 MB por servidor)
```

---

## 🔄 Updates e Manutenção

### Verificar Updates de Packages

```
System → Package Manager → Available Packages

- Refresh para ver atualizações disponíveis
- Update para atualizar individual
- Update All para atualizar todos
```

### Update via CLI

```bash
# Atualizar package específico
pkg-static upgrade -y ntopng

# Atualizar todos
pkg-static upgrade -y

# Ver packages instalados
pkg info

# Ver dependências
pkg info -d ntopng
```

### Desinstalar Package

```
System → Package Manager → Installed Packages → Delete

⚠️ Aviso: Desinstalar remove configurações

Backup antes:
Diagnostics → Backup & Restore → Backup
```

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

## 📖 Referências

- [pfSense Packages](https://docs.netgate.com/pfsense/en/latest/packages/index.html)
- [ntopng Documentation](https://www.ntop.org/guides/ntopng/)
- [HAProxy Documentation](https://www.haproxy.org/#docs)

---

<div align="center">

**[⬅️ Voltar: Integração RADIUS](07-radius-integracao.md)** | **[Índice](README.md)** | **[Próximo: Manutenção ➡️](09-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2024*
