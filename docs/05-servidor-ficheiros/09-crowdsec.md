# 🛡️ CrowdSec - Sistema de Deteção de Intrusões

> **Configuração do CrowdSec IDS/IPS no Servidor de Ficheiros**

---

## 📋 Índice

1. [Instalação](#-instalação)
2. [Configuração](#-configuração)
3. [Collections e Scenarios](#-collections-e-scenarios)
4. [Bouncer Firewall](#-bouncer-firewall)
5. [Monitorização](#-monitorização)
6. [Referências](#-referências)

---

## 📥 Instalação

### Adicionar Repositório

```bash
# Download do script de instalação
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
```

### Instalar CrowdSec

```bash
# Instalar agente CrowdSec
sudo apt install -y crowdsec

# Verificar versão
sudo cscli version
```

**Versão esperada:** v1.7.3

---

## ⚙️ Configuração

### Configuração Principal

Ficheiro: `/etc/crowdsec/config.yaml`

```yaml
common:
  daemonize: true
  pid_dir: /var/run/
  log_media: file
  log_level: info
  log_dir: /var/log/
  working_dir: .

config_paths:
  config_dir: /etc/crowdsec/
  data_dir: /var/lib/crowdsec/data/
  simulation_path: /etc/crowdsec/simulation.yaml
  hub_dir: /etc/crowdsec/hub/
  index_path: /etc/crowdsec/hub/.index.json

crowdsec_service:
  acquisition_path: /etc/crowdsec/acquis.yaml
  parser_routines: 1

cscli:
  output: human

db_config:
  log_level: info
  type: sqlite
  db_path: /var/lib/crowdsec/data/crowdsec.db
  flush:
    max_items: 5000
    max_age: 7d

api:
  client:
    insecure_skip_verify: false
  server:
    log_level: info
    listen_uri: 127.0.0.1:8080
    profiles_path: /etc/crowdsec/profiles.yaml
    online_client:
      credentials_path: /etc/crowdsec/online_api_credentials.yaml
```

### Aquisição de Logs

Ficheiro: `/etc/crowdsec/acquis.yaml`

```yaml
---
# Apache/Nextcloud logs
filenames:
  - /var/log/apache2/nextcloud_access.log
labels:
  type: apache2

---
# Apache error log
filenames:
  - /var/log/apache2/nextcloud_error.log
labels:
  type: apache2-error

---
# Nginx/Zammad logs
filenames:
  - /var/log/nginx/zammad_access.log
labels:
  type: nginx

---
# Nginx error log
filenames:
  - /var/log/nginx/zammad_error.log
labels:
  type: nginx-error

---
# SSH logs
filenames:
  - /var/log/auth.log
labels:
  type: syslog

---
# PostgreSQL logs
filenames:
  - /var/log/postgresql/postgresql-*.log
labels:
  type: postgres
```

### Aplicar Configuração

```bash
# Reiniciar CrowdSec
sudo systemctl restart crowdsec

# Verificar status
sudo systemctl status crowdsec
```

---

## 📦 Collections e Scenarios

### Instalar Collections

```bash
# Linux base
sudo cscli collections install crowdsecurity/linux

# Apache
sudo cscli collections install crowdsecurity/apache2

# Nginx
sudo cscli collections install crowdsecurity/nginx

# SSH
sudo cscli collections install crowdsecurity/sshd

# PostgreSQL
sudo cscli collections install crowdsecurity/pgsql

# HTTP/Web
sudo cscli collections install crowdsecurity/base-http-scenarios

# Nextcloud
sudo cscli scenarios install crowdsecurity/nextcloud-bf
```

### Listar Collections Instaladas

```bash
sudo cscli collections list
```

**Expected output:**
```
NAME                                  STATUS    VERSION  DESCRIPTION
crowdsecurity/apache2                 ✔️        0.2      Apache2 collection
crowdsecurity/linux                   ✔️        0.3      Linux base collection
crowdsecurity/nginx                   ✔️        0.2      Nginx collection
crowdsecurity/pgsql                   ✔️        0.1      PostgreSQL collection
crowdsecurity/sshd                    ✔️        0.2      SSH bruteforce detection
crowdsecurity/base-http-scenarios     ✔️        0.7      HTTP base scenarios
```

### Scenarios Ativos

```bash
# Listar scenarios
sudo cscli scenarios list

# Ver detalhes de um scenario
sudo cscli scenarios inspect crowdsecurity/http-probing
```

**Scenarios principais:**
- SSH brute-force
- HTTP scanning
- HTTP sensitive files
- Apache/Nginx CVEs
- Nextcloud brute-force
- SQL injection attempts

---

## 🔥 Bouncer Firewall

### Instalar Firewall Bouncer

```bash
# Instalar bouncer
sudo apt install -y crowdsec-firewall-bouncer-iptables

# Verificar versão
sudo crowdsec-firewall-bouncer -version
```

**Versão esperada:** v0.0.34

### Configuração do Bouncer

Ficheiro: `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`

```yaml
mode: iptables
pid_dir: /var/run/
update_frequency: 10s
daemonize: true
log_mode: file
log_dir: /var/log/
log_level: info
api_url: http://localhost:8080
api_key: <gerado_automaticamente>

# Blacklist rules
deny_action: DROP
deny_log: false

# Prometheus metrics
prometheus:
  enabled: true
  listen_addr: 127.0.0.1
  listen_port: 60601

# iptables settings
iptables_chains:
  - INPUT
  - FORWARD
```

### Registar Bouncer

```bash
# Listar bouncers
sudo cscli bouncers list

# Ver API key do bouncer
sudo cscli bouncers list -o json | jq '.[] | select(.name=="crowdsec-firewall-bouncer")'
```

### Reiniciar Bouncer

```bash
sudo systemctl restart crowdsec-firewall-bouncer
sudo systemctl status crowdsec-firewall-bouncer
```

### Verificar Regras iptables

```bash
# Ver chains do CrowdSec
sudo iptables -L crowdsec-chain -n -v

# Ver IPs bloqueados
sudo iptables -L crowdsec-chain -n | grep DROP
```

---

## 📊 Monitorização

### Ver Alertas

```bash
# Alertas recentes
sudo cscli alerts list

# Alertas de um IP específico
sudo cscli alerts list --ip 1.2.3.4

# Alertas por scenario
sudo cscli alerts list --scenario crowdsecurity/ssh-bf
```

### Decisões Ativas

```bash
# Ver decisões (bans) ativas
sudo cscli decisions list

# Decisões por tipo
sudo cscli decisions list --type ban

# Decisões por origem
sudo cscli decisions list --origin cscli
sudo cscli decisions list --origin crowdsec
```

### Métricas

```bash
# Métricas do agente
sudo cscli metrics

# Ver parsers
sudo cscli metrics --parsers

# Ver scenarios
sudo cscli metrics --scenarios
```

### Logs

```bash
# Logs do CrowdSec
sudo tail -f /var/log/crowdsec.log

# Logs do bouncer
sudo tail -f /var/log/crowdsec-firewall-bouncer.log

# Ver logs de decisões
sudo journalctl -u crowdsec -f | grep decision
```

---

## 🛡️ Gestão de IPs

### Banir IP Manualmente

```bash
# Ban por 4 horas
sudo cscli decisions add --ip 1.2.3.4 --duration 4h --reason "Manual ban - suspicious activity"

# Ban permanente
sudo cscli decisions add --ip 1.2.3.4 --duration 0 --reason "Permanent ban"

# Ban de range
sudo cscli decisions add --range 1.2.3.0/24 --duration 24h --reason "Ban subnet"
```

### Remover Ban

```bash
# Unban IP
sudo cscli decisions delete --ip 1.2.3.4

# Unban range
sudo cscli decisions delete --range 1.2.3.0/24

# Remover todas as decisões
sudo cscli decisions delete --all
```

### Whitelist

Ficheiro: `/etc/crowdsec/parsers/s02-enrich/whitelist.yaml`

```yaml
name: crowdsecurity/whitelists
description: "Whitelist trusted IPs"
whitelist:
  reason: "Trusted internal networks"
  ip:
    - "192.168.1.0/24"    # LAN
    - "10.0.0.0/24"       # DMZ
    - "10.8.0.0/24"       # VPN
    - "10.9.0.0/24"       # VPN Backup
    - "127.0.0.1"         # Localhost
```

Aplicar:

```bash
sudo systemctl reload crowdsec
```

---

## 🌐 Integração CAPI

### Registar na Community API

```bash
# Registar (primeira vez)
sudo cscli capi register

# Verificar status
sudo cscli capi status
```

### Pull de Blocklists

```bash
# Download manual de blocklists
sudo cscli capi pull

# Ver decisões da CAPI
sudo cscli decisions list --origin capi
```

### Configurar Auto-Pull

O CrowdSec faz pull automático a cada hora.

Verificar em `/etc/crowdsec/config.yaml`:

```yaml
api:
  server:
    online_client:
      credentials_path: /etc/crowdsec/online_api_credentials.yaml
```

---

## 📝 Checklist

- [x] CrowdSec v1.7.3 instalado
- [x] Logs configurados (Apache, Nginx, SSH, PostgreSQL)
- [x] Collections instaladas (linux, apache2, nginx, sshd, pgsql)
- [x] Scenarios ativos (40+ scenarios)
- [x] Firewall bouncer v0.0.34 instalado e a funcionar
- [x] iptables rules ativas
- [x] CAPI registado
- [x] Whitelist configurada para redes internas
- [x] Métricas a funcionar

---

## 🔍 Comandos Úteis

```bash
# Status geral
sudo cscli hub list

# Atualizar hub
sudo cscli hub update

# Upgrade de parsers/scenarios
sudo cscli hub upgrade

# Ver máquinas registadas
sudo cscli machines list

# Ver bouncers
sudo cscli bouncers list

# Dashboard (se instalado)
sudo cscli dashboard setup
```

---

## 📖 Referências

- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [CrowdSec Hub](https://hub.crowdsec.net/)
- [Firewall Bouncer](https://docs.crowdsec.net/docs/bouncers/firewall/)

---

<div align="center">

**[⬅️ Voltar: PostgreSQL e Redis](08-postgresql-redis.md)** | **[Próximo: Manutenção ➡️](10-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2024*
