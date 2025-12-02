# 🛡️ CrowdSec - Sistema de Deteção de Intrusões

> **Configuração do CrowdSec v1.7.3 para proteção do Domain Controller**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Instalação](#-instalação)
3. [Configuração Base](#-configuração-base)
4. [Collections e Parsers](#-collections-e-parsers)
5. [Bouncer de Firewall](#-bouncer-de-firewall)
6. [CAPI e Blocklists](#-capi-e-blocklists)
7. [Monitorização](#-monitorização)
8. [Verificação e Testes](#-verificação-e-testes)
9. [Referências](#-referências)

---

## 📖 Visão Geral

### O que é o CrowdSec?

O CrowdSec é um sistema de deteção e prevenção de intrusões (IDS/IPS) colaborativo e open-source. Utiliza análise comportamental de logs para detetar ameaças e partilha inteligência de ameaças com a comunidade através da CAPI (Central API).

### Características Principais

| Característica | Descrição |
|----------------|-----------|
| **Análise de Logs** | Parsing em tempo real de múltiplos formatos |
| **Cenários** | Regras de deteção baseadas em comportamentos |
| **Bouncers** | Componentes de remediação (firewall, nginx, etc.) |
| **CAPI** | Blocklist comunitária de IPs maliciosos |
| **Dashboard** | Interface web para monitorização |

### Informação do Serviço

| Parâmetro | Valor |
|-----------|-------|
| **Versão CrowdSec** | v1.7.3 |
| **Versão Bouncer** | cs-firewall-bouncer v0.0.34 |
| **CAPI Blocklist** | ~16.19k IPs |
| **Servidor** | dc.fsociety.pt (192.168.1.10) |

### Arquitetura CrowdSec

```
                    ┌─────────────────────────────────────┐
                    │            CAPI (Cloud)              │
                    │     Central API da CrowdSec          │
                    │  ┌─────────────┐  ┌─────────────┐   │
                    │  │  Blocklists │  │  Telemetry  │   │
                    │  │  ~70k IPs   │  │   Reports   │   │
                    │  └─────────────┘  └─────────────┘   │
                    └─────────────┬───────────────────────┘
                                  │
                    ┌─────────────▼───────────────────────┐
                    │        CrowdSec Engine               │
                    │        (dc.fsociety.pt)              │
                    ├─────────────────────────────────────┤
                    │  ┌───────────┐  ┌───────────────┐   │
                    │  │  Parsers  │  │   Scenarios   │   │
                    │  │  (syslog, │  │  (brute-force,│   │
                    │  │  auth,etc)│  │   scan, etc)  │   │
                    │  └─────┬─────┘  └───────┬───────┘   │
                    │        │                │           │
                    │        ▼                ▼           │
                    │  ┌─────────────────────────────┐    │
                    │  │     Local API (LAPI)        │    │
                    │  │     Port 8080               │    │
                    │  └─────────────┬───────────────┘    │
                    └─────────────────┼───────────────────┘
                                      │
                    ┌─────────────────▼───────────────────┐
                    │         Firewall Bouncer            │
                    │    cs-firewall-bouncer v0.0.34      │
                    │                                     │
                    │  ┌───────────┐  ┌───────────────┐   │
                    │  │ iptables  │  │   nftables    │   │
                    │  │   DROP    │  │     DROP      │   │
                    │  └───────────┘  └───────────────┘   │
                    └─────────────────────────────────────┘
```

---

## 📦 Instalação

### Adicionar Repositório

```bash
# Adicionar chave GPG
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
```

### Instalar CrowdSec

```bash
# Instalar CrowdSec Engine
sudo apt install -y crowdsec

# Verificar versão
cscli version
```

### Instalar Firewall Bouncer

```bash
# Instalar bouncer de firewall
sudo apt install -y crowdsec-firewall-bouncer-iptables

# Verificar versão
sudo dpkg -l | grep crowdsec-firewall
```

---

## ⚙️ Configuração Base

### Ficheiro de Configuração Principal

**Localização:** `/etc/crowdsec/config.yaml`

```yaml
common:
  daemonize: true
  log_media: file
  log_level: info
  log_dir: /var/log/crowdsec/
  log_max_size: 20
  log_max_files: 3
  log_max_age: 7
  compress_logs: true
  working_dir: .

config_paths:
  config_dir: /etc/crowdsec/
  data_dir: /var/lib/crowdsec/data/
  simulation_path: /etc/crowdsec/simulation.yaml
  hub_dir: /etc/crowdsec/hub/
  index_path: /etc/crowdsec/hub/.index.json
  notification_dir: /etc/crowdsec/notifications/
  plugin_dir: /usr/lib/crowdsec/plugins/

crowdsec_service:
  acquisition_path: /etc/crowdsec/acquis.yaml
  acquisition_dir: /etc/crowdsec/acquis.d/
  parser_routines: 1
  buckets_routines: 1
  output_routines: 1

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
    credentials_path: /etc/crowdsec/local_api_credentials.yaml
  server:
    log_level: info
    listen_uri: 127.0.0.1:8080
    profiles_path: /etc/crowdsec/profiles.yaml
    console_path: /etc/crowdsec/console.yaml
    online_client:
      credentials_path: /etc/crowdsec/online_api_credentials.yaml

prometheus:
  enabled: true
  level: full
  listen_addr: 127.0.0.1
  listen_port: 6060
```

### Configurar Acquisition (Fontes de Log)

**Ficheiro:** `/etc/crowdsec/acquis.yaml`

```yaml
# Syslog - Logs do sistema
filenames:
  - /var/log/syslog
  - /var/log/messages
labels:
  type: syslog
---
# Auth - Logs de autenticação
filenames:
  - /var/log/auth.log
labels:
  type: syslog
---
# Samba - Logs do Active Directory
filenames:
  - /var/log/samba/log.*
labels:
  type: smb
---
# DHCP Server
filenames:
  - /var/log/dhcpd.log
labels:
  type: syslog
---
# FreeRADIUS
filenames:
  - /var/log/freeradius/radius.log
labels:
  type: syslog
```

---

## 📚 Collections e Parsers

### Instalar Collections

```bash
# Collection Linux (base)
sudo cscli collections install crowdsecurity/linux

# Collection SSH
sudo cscli collections install crowdsecurity/sshd

# Collection Samba/SMB
sudo cscli collections install crowdsecurity/smb

# Collection MySQL (se aplicável)
sudo cscli collections install crowdsecurity/mysql

# Collection Postfix (para logs de email)
sudo cscli collections install crowdsecurity/postfix

# Whitelist de IPs conhecidos como seguros
sudo cscli collections install crowdsecurity/whitelist-good-actors
```

### Listar Collections Instaladas

```bash
# Ver collections
sudo cscli collections list

# Ver parsers
sudo cscli parsers list

# Ver scenarios
sudo cscli scenarios list
```

### Collections Ativas

| Collection | Descrição | Scenarios |
|------------|-----------|-----------|
| crowdsecurity/linux | Base para Linux | iptables-scan, etc. |
| crowdsecurity/sshd | Proteção SSH | ssh-bf, ssh-slow-bf |
| crowdsecurity/smb | Proteção Samba | smb-bf |
| crowdsecurity/mysql | Proteção MySQL | mysql-bf |
| crowdsecurity/postfix | Proteção email | postfix-spam |
| crowdsecurity/whitelist-good-actors | IPs seguros | - |

### Atualizar Hub

```bash
# Atualizar índice do hub
sudo cscli hub update

# Atualizar collections
sudo cscli hub upgrade
```

---

## 🔥 Bouncer de Firewall

### Configuração do Bouncer

**Ficheiro:** `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`

```yaml
# CrowdSec Firewall Bouncer Configuration

mode: iptables
pid_dir: /var/run/
update_frequency: 10s
daemonize: true
log_mode: file
log_dir: /var/log/
log_level: info
log_compression: true
log_max_size: 100
log_max_backups: 3
log_max_age: 30

api_url: http://127.0.0.1:8080/
api_key: <BOUNCER_API_KEY>

# Desativar IPv6 se não utilizado
disable_ipv6: true

# Negar tráfego (DROP em vez de REJECT)
deny_action: DROP
deny_log: true
deny_log_prefix: "crowdsec: "

# Blacklist estática adicional (opcional)
blacklists_ipv4: /etc/crowdsec/bouncers/blacklists/blacklist_ipv4.txt
# blacklists_ipv6: /etc/crowdsec/bouncers/blacklists/blacklist_ipv6.txt

# iptables settings
iptables_chains:
  - INPUT
  - FORWARD
```

### Registar Bouncer

```bash
# Gerar API key para o bouncer
sudo cscli bouncers add firewall-bouncer

# Copiar a chave gerada para o ficheiro de configuração
# api_key: <CHAVE_GERADA>

# Reiniciar bouncer
sudo systemctl restart crowdsec-firewall-bouncer
```

### Verificar Bouncer

```bash
# Listar bouncers registados
sudo cscli bouncers list

# Verificar estado
sudo systemctl status crowdsec-firewall-bouncer
```

---

## 🌐 CAPI e Blocklists

### Registar na CAPI

```bash
# Registar instância na Central API
sudo cscli capi register

# Verificar registo
sudo cscli capi status
```

### Blocklists Disponíveis

| Blocklist | IPs | Descrição |
|-----------|-----|-----------|
| CAPI Community | ~16.19k | Blocklist comunitária |
| Fire | ~50k | IPs maliciosos (premium) |

### Ver Decisões da CAPI

```bash
# Ver decisões ativas (IPs bloqueados)
sudo cscli decisions list

# Estatísticas
sudo cscli metrics
```

### Adicionar Blocklist Manual

```bash
# Adicionar IP à blocklist
sudo cscli decisions add --ip 1.2.3.4 --duration 24h --reason "Manual block"

# Adicionar range
sudo cscli decisions add --range 1.2.3.0/24 --duration 24h --reason "Manual block"
```

### Remover da Blocklist

```bash
# Remover IP
sudo cscli decisions delete --ip 1.2.3.4

# Remover todas as decisões de um IP
sudo cscli decisions delete --all --ip 1.2.3.4
```

---

## 📊 Monitorização

### Dashboard Console

```bash
# Instalar console (dashboard web)
sudo cscli console enroll <ENROLLMENT_KEY>

# Aceder em: https://app.crowdsec.net
```

### Métricas Prometheus

```bash
# Verificar métricas
curl http://127.0.0.1:6060/metrics

# Métricas do CrowdSec
sudo cscli metrics
```

### Exemplo de Output de Métricas

```
Acquisition Metrics:
╭─────────────────────────────────────┬────────────────┬──────────────┬────────────────────╮
│                Source               │ Lines read     │ Lines parsed │ Lines unparsed     │
├─────────────────────────────────────┼────────────────┼──────────────┼────────────────────┤
│ file:/var/log/auth.log              │ 1.52k          │ 1.52k        │ -                  │
│ file:/var/log/syslog                │ 3.24k          │ 2.18k        │ 1.06k              │
│ file:/var/log/samba/log.*           │ 856            │ 856          │ -                  │
╰─────────────────────────────────────┴────────────────┴──────────────┴────────────────────╯

Local Api Metrics:
╭──────────────────────┬────────┬──────╮
│       Route          │ Method │ Hits │
├──────────────────────┼────────┼──────┤
│ /v1/decisions/stream │ GET    │ 324  │
│ /v1/alerts           │ POST   │ 12   │
╰──────────────────────┴────────┴──────╯

Local Api Decisions:
╭──────────────┬────────┬────────────╮
│    Reason    │ Origin │   Count    │
├──────────────┼────────┼────────────┤
│ ssh-bf       │ cscli  │ 3          │
│ ssh-slow-bf  │ crowdsec│ 2         │
│ ban          │ CAPI   │ 16,190     │
╰──────────────┴────────┴────────────╯
```

### Logs

```bash
# Logs do CrowdSec Engine
sudo tail -f /var/log/crowdsec/crowdsec.log

# Logs do Bouncer
sudo tail -f /var/log/crowdsec-firewall-bouncer.log
```

---

## ✅ Verificação e Testes

### Verificar Serviços

```bash
# Estado do CrowdSec
sudo systemctl status crowdsec

# Estado do Bouncer
sudo systemctl status crowdsec-firewall-bouncer
```

### Testar Detecção

```bash
# Simular ataque SSH brute-force (CUIDADO: IP será bloqueado)
# Executar de outro servidor:
for i in {1..10}; do ssh invalid@192.168.1.10; done

# Verificar se foi detetado
sudo cscli alerts list
sudo cscli decisions list
```

### Verificar iptables

```bash
# Ver regras do CrowdSec
sudo iptables -L CROWDSEC_CHAIN -n

# Ver IPs bloqueados
sudo iptables -L INPUT -n | grep -i drop
```

### Script de Diagnóstico

```bash
#!/bin/bash
# Diagnóstico CrowdSec

echo "=== CrowdSec Status ==="
sudo systemctl status crowdsec --no-pager | head -10

echo -e "\n=== Bouncer Status ==="
sudo systemctl status crowdsec-firewall-bouncer --no-pager | head -10

echo -e "\n=== Collections Instaladas ==="
sudo cscli collections list

echo -e "\n=== Bouncers Registados ==="
sudo cscli bouncers list

echo -e "\n=== Decisões Ativas ==="
sudo cscli decisions list | head -20

echo -e "\n=== Métricas ==="
sudo cscli metrics | head -30

echo -e "\n=== Últimos Alertas ==="
sudo cscli alerts list | head -10
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Bouncer não conecta | API key inválida | Regenerar API key |
| Logs não processados | Acquisition errado | Verificar acquis.yaml |
| IP não bloqueado | Bouncer não ativo | Verificar systemctl |
| Falsos positivos | Cenário agressivo | Ajustar ou whitelist |

### Whitelist de IPs

**Ficheiro:** `/etc/crowdsec/parsers/s02-enrich/whitelist-local.yaml`

```yaml
name: crowdsecurity/whitelist-local
description: "Whitelist IPs internos"
whitelist:
  reason: "Internal IPs"
  ip:
    - "192.168.1.0/24"
    - "10.0.0.0/24"
    - "10.8.0.0/24"
```

```bash
# Recarregar configuração
sudo systemctl reload crowdsec
```

### Reinstalar Bouncer

```bash
# Remover bouncer
sudo cscli bouncers delete firewall-bouncer

# Reinstalar
sudo apt reinstall crowdsec-firewall-bouncer-iptables

# Registar novamente
sudo cscli bouncers add firewall-bouncer
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| CrowdSec Documentation | https://docs.crowdsec.net/ |
| CrowdSec Hub | https://hub.crowdsec.net/ |
| CrowdSec GitHub | https://github.com/crowdsecurity/crowdsec |

### Artigos Técnicos

1. **CrowdSec for Linux Servers** - CrowdSec Blog
2. **Protecting Samba with CrowdSec** - CrowdSec Hub
3. **Firewall Bouncer Setup** - CrowdSec Docs

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 🔗 Navegação

| Anterior | Índice | Próximo |
|----------|--------|---------|
| [← FreeRADIUS + LDAP](06-freeradius-ldap.md) | [📚 Índice](README.md) | [Shares e Permissões →](08-shares-permissoes.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#️-crowdsec---sistema-de-deteção-de-intrusões)**

---

*Última atualização: Dezembro 2024*

</div>
