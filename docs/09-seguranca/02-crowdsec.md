# 🚨 CrowdSec - Proteção Interna Colaborativa

> **Sistema IDS/IPS Colaborativo Distribuído em 4 Servidores**  
>  
> Documentação completa do CrowdSec na infraestrutura FSociety.pt, consolidando informações anteriormente dispersas nas pastas 04, 05 e 06.

---

## 📋 Informação da Organização

| Campo | Valor |
|-------|-------|
| **Nome da Organização** | fsociety |
| **Tipo** | Organization (community) |
| **IP Público** | 188.81.65.191 |
| **Engines Ativos** | 4 servidores |
| **Total Scenarios** | 132 |
| **Total Alerts (7 dias)** | 92 |
| **Total Bouncers** | 6 |
| **Blocklists Subscritas** | 4 |

---

## 🏗️ Arquitetura CrowdSec

O CrowdSec funciona através de uma arquitetura distribuída com múltiplos componentes:

```
┌─────────────────────────────────────────────────────────────────┐
│                  CrowdSec Organization (fsociety)               │
│                      IP Público: 188.81.65.191                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐    ┌──────────┐
    │   Web    │     │   File   │    │  Domain  │
    │  Server  │     │  Server  │    │  Server  │
    │  (56)    │     │  (55)    │    │  (11)    │
    │ 92 alerts│     │ 0 alerts │    │ 0 alerts │
    └────┬─────┘     └────┬─────┘    └────┬─────┘
         │                │                │
         │           ┌────▼────┐           │
         │           │ mailcow │           │
         │           │  (10)   │           │
         │           │0 alerts │           │
         │           └────┬────┘           │
         │                │                │
         └────────────────┼────────────────┘
                          │
              ┌───────────▼───────────┐
              │   CrowdSec CAPI       │
              │ (Community Blocklist) │
              │    Global Threat      │
              │    Intelligence       │
              └───────────────────────┘
                          │
                ┌─────────┴─────────┐
                │                   │
         ┌──────▼──────┐    ┌──────▼──────┐
         │  Firewall   │    │  Cloudflare │
         │  Bouncers   │    │   Bouncer   │
         │   (iptables)│    │  (edge WAF) │
         └─────────────┘    └─────────────┘
```

### Como Funciona

1. **Security Engines** → Analisam logs em tempo real
2. **Parsers** → Extraem informação relevante dos logs
3. **Scenarios** → Detectam padrões de comportamento malicioso
4. **Decisions** → Geram decisões de ban (IP, range, etc)
5. **LAPI** → API local que sincroniza decisões
6. **Bouncers** → Executam as decisões (firewall, WAF, etc)
7. **CAPI** → Partilha ameaças com comunidade global

---

## 🖥️ Engines Registados (4 Servidores)

### Visão Geral Consolidada

| Engine | IP | Scenarios | Alerts (7d) | Bouncers | Blocklists | Última Atividade |
|--------|-----|-----------|-------------|----------|------------|------------------|
| **Web Server** | 188.81.65.191 | 56 | 92 | 3 | 1 | ✅ Ativo |
| **File Server** | 188.81.65.191 | 55 | 0 | 1 | 1 | ✅ Ativo |
| **Domain Server** | 188.81.65.191 | 11 | 0 | 1 | 1 | ✅ Ativo |
| **mailcow** | 188.81.65.191 | 10 | 0 | 1 | 1 | ✅ Ativo |

**Totais Globais**:
- 📊 **132 scenarios** instalados
- 🚨 **92 alerts** gerados (últimos 7 dias)
- 🛡️ **6 bouncers** ativos
- 📋 **4 blocklists** subscritas
- 🌍 **16.3k ataques** prevenidos
- 🚫 **15 IPs** atualmente banidos

---

### 1️⃣ Web Server (Servidor Principal)

**O mais crítico** - Enfrenta a internet diretamente e gera a maioria dos alerts.

```
┌─────────────────────────────────────────────────┐
│            Web Server (188.81.65.191)           │
├─────────────────────────────────────────────────┤
│ Scenarios: 56                                   │
│ Alerts: 92 (últimos 7 dias)                     │
│ Bouncers: 3                                     │
├─────────────────────────────────────────────────┤
│ Scenarios Principais:                           │
│  • http-bad-user-agent (×7 triggers)            │
│  • http-probing (×7 triggers)                   │
│  • http-cve-2021-41773 (×5 triggers)            │
│  • http-cve-2021-42013                          │
│  • vmware-cve-2022-22954                        │
│  • http-sensitive-files                         │
│  • http-open-proxy                              │
│  • http-bruteforce                              │
│  • http-crawl                                   │
├─────────────────────────────────────────────────┤
│ Bouncers Instalados:                            │
│  ✅ cs-firewall-bouncer v0.0.34                 │
│  ✅ cs-cloudflare-bouncer v0.3.0                │
│  ✅ crowdsec-nginx-bouncer v1.1.3               │
└─────────────────────────────────────────────────┘
```

**Logs Monitorados**:
- `/var/log/nginx/access.log`
- `/var/log/nginx/error.log`
- `/var/log/auth.log`
- `/var/log/syslog`

---

### 2️⃣ File Server

**Proteção de dados** - Monitora acessos ao servidor de ficheiros Samba.

```
┌─────────────────────────────────────────────────┐
│           File Server (188.81.65.191)           │
├─────────────────────────────────────────────────┤
│ Scenarios: 55                                   │
│ Alerts: 0 (últimos 7 dias)                      │
│ Bouncers: 1                                     │
├─────────────────────────────────────────────────┤
│ Scenarios Principais:                           │
│  • smb-bruteforce                               │
│  • smb-enum-shares                              │
│  • linux-ssh-bruteforce                         │
│  • http-probing                                 │
│  • http-sensitive-files                         │
├─────────────────────────────────────────────────┤
│ Bouncers Instalados:                            │
│  ✅ cs-firewall-bouncer v0.0.34                 │
└─────────────────────────────────────────────────┘
```

**Logs Monitorados**:
- `/var/log/samba/log.*`
- `/var/log/auth.log`
- `/var/log/syslog`

---

### 3️⃣ Domain Server (Active Directory)

**Proteção do AD** - Monitora tentativas de ataque ao controlador de domínio.

```
┌─────────────────────────────────────────────────┐
│         Domain Server (188.81.65.191)           │
├─────────────────────────────────────────────────┤
│ Scenarios: 11                                   │
│ Alerts: 0 (últimos 7 dias)                      │
│ Bouncers: 1                                     │
├─────────────────────────────────────────────────┤
│ Scenarios Principais:                           │
│  • samba-bruteforce                             │
│  • samba-dc-enum                                │
│  • ldap-bruteforce                              │
│  • kerberos-bruteforce                          │
│  • linux-ssh-bruteforce                         │
├─────────────────────────────────────────────────┤
│ Bouncers Instalados:                            │
│  ✅ cs-firewall-bouncer v0.0.34                 │
└─────────────────────────────────────────────────┘
```

**Logs Monitorados**:
- `/var/log/samba/log.*`
- `/var/log/auth.log`
- `/var/log/syslog`

---

### 4️⃣ mailcow (Servidor de Email)

**Proteção de email** - Monitora tentativas de spam, bruteforce e exploits.

```
┌─────────────────────────────────────────────────┐
│            mailcow (188.81.65.191)              │
├─────────────────────────────────────────────────┤
│ Scenarios: 10                                   │
│ Alerts: 0 (últimos 7 dias)                      │
│ Bouncers: 1                                     │
├─────────────────────────────────────────────────┤
│ Scenarios Principais:                           │
│  • postfix-spam                                 │
│  • postfix-bruteforce                           │
│  • dovecot-bruteforce                           │
│  • sogo-bruteforce                              │
│  • http-probing                                 │
├─────────────────────────────────────────────────┤
│ Bouncers Instalados:                            │
│  ✅ cs-firewall-bouncer v0.0.34                 │
└─────────────────────────────────────────────────┘
```

**Logs Monitorados**:
- `/opt/mailcow-dockerized/data/logs/postfix/*.log`
- `/opt/mailcow-dockerized/data/logs/dovecot/*.log`
- `/opt/mailcow-dockerized/data/logs/sogo/*.log`

---

## 📊 Métricas de Remediação (Últimos 7 Dias)

### Tráfego Malicioso Descartado

| Métrica | Valor | Impacto |
|---------|-------|---------|
| **Bytes Dropped** | 2.53 MB | Largura de banda poupada |
| **Packets Dropped** | 6.61k | Pacotes maliciosos bloqueados |
| **Requests Dropped** | 4.59k | Requisições HTTP bloqueadas |

### Origem do Bloqueio

| Fonte | Quantidade | Percentagem |
|-------|------------|-------------|
| **CrowdSec Security Engine** | 1.36 MB | 53.8% |
| **Community Blocklist (CAPI)** | 1.17 MB | 46.2% |

**Análise**: 46.2% dos bloqueios vêm da inteligência colaborativa da comunidade CrowdSec, demonstrando a eficácia do sistema de partilha de ameaças.

---

### Recursos Poupados (Projetado)

| Recurso | Valor | Descrição |
|---------|-------|-----------|
| **Outgoing Traffic Dropped** | 360.51 MB | Tráfego de resposta não enviado |
| **Log Lines Saved** | 11.2k lines | Logs não gerados |
| **Storage Saved** | 1.82 MB | Espaço em disco poupado |

---

## 🎯 Ataques Prevenidos (16.3k Total)

### Distribuição por Tipo de Ataque

| Tipo de Ataque | Quantidade | Percentagem | Descrição |
|----------------|------------|-------------|-----------|
| **HTTP Scan** | 3.37k | 20.8% | Scanners procurando vulnerabilidades |
| **HTTP Exploit** | 3.03k | 18.6% | Tentativas de exploração de CVEs |
| **HTTP Bruteforce** | 2.95k | 18.1% | Ataques de força bruta a logins |
| **HTTP Crawl** | 2.73k | 16.8% | Crawlers e bots não autorizados |
| **VM Management Exploit** | 2.13k | 13.1% | Exploits VMware/vSphere |
| **Outros** | 2.09k | 12.6% | Diversos tipos de ataques |

```
 Distribuição Visual:
 ┌─────────────────────────────────────────────────┐
 │ HTTP Scan          ████████████ 20.8%           │
 │ HTTP Exploit       ███████████ 18.6%            │
 │ HTTP Bruteforce    ██████████ 18.1%             │
 │ HTTP Crawl         █████████ 16.8%              │
 │ VM Exploit         ███████ 13.1%                │
 │ Outros             ███████ 12.6%                │
 └─────────────────────────────────────────────────┘
```

---

## 🚫 Decisões Ativas (15 IPs Banidos)

### Lista Completa de Bans Ativos

| # | IP | País | ASN/Provedor | Target | Duração | Razão | Perigo |
|---|-----|------|--------------|--------|---------|-------|--------|
| 1 | 87.121.94.116 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 24h | vmware-cve-2022-22954 | 🔴 Alto |
| 2 | 89.117.22.183 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 22h | http-cve-2021-41773 | 🔴 Alto |
| 3 | 52.55.15.171 | 🇺🇸 US | AMAZON-AES | Web Server | 22h | http-probing | 🟡 Médio |
| 4 | 111.250.126.111 | 🇹🇼 TW | HINET | Web Server | 21h | http-cve-2021-41773 | 🔴 Alto |
| 5 | 149.102.148.136 | 🇩🇪 DE | HETZNER | Web Server | 18h | http-cve-2021-42013 | 🔴 Alto |
| 6 | 45.148.10.245 | 🇳🇱 NL | Techoff Srv | Web Server | 17h | http-probing | 🟡 Médio |
| 7 | 167.94.146.49 | 🇺🇸 US | VULTR | Web Server | 16h | http-bad-user-agent | 🟡 Médio |
| 8 | 185.91.127.97 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 16h | http-open-proxy | 🟠 Médio-Alto |
| 9 | 66.132.153.123 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 15h | http-bad-user-agent | 🟡 Médio |
| 10 | 121.91.235.186 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 15h | http-open-proxy | 🟠 Médio-Alto |
| 11 | 35.84.139.62 | 🇺🇸 US | AMAZON-02 | Web Server | 14h | http-probing | 🟡 Médio |
| 12 | 20.163.59.190 | 🇺🇸 US | MICROSOFT | Web Server | 14h | http-cve-probing | 🔴 Alto |
| 13 | 194.180.49.176 | 🇺🇸 US | CENSYS-ARIN-01 | Web Server | 14h | http-sensitive-files | 🟠 Médio-Alto |
| 14 | 167.94.138.177 | 🇺🇸 US | VULTR | Web Server | 14h | http-bad-user-agent | 🟡 Médio |
| 15 | 103.4.250.198 | 🇺🇸 US | Techoff Srv | Web Server | 13h | http-probing | 🟡 Médio |

### Top ASNs de Origem

| ASN | Organização | Quantidade | Percentagem |
|-----|-------------|------------|-------------|
| CENSYS-ARIN-01 | Censys Inc. | 5 | 33.3% |
| MICROSOFT-CORP-MSN-AS-BLOCK | Microsoft | 4 | 26.7% |
| Techoff Srv Limited | Techoff | 3 | 20.0% |
| AMAZON-AES / AMAZON-02 | Amazon AWS | 2 | 13.3% |
| VULTR | Vultr Holdings | 1 | 6.7% |

**Análise**: A maioria dos ataques vem de serviços de scanning (Censys) e infraestruturas cloud (AWS, Microsoft, Vultr), frequentemente usadas por atacantes.

---

## 🔍 CVEs Detectados e Mitigados

### Vulnerabilidades Críticas Bloqueadas

| CVE | CVSS | Descrição | Impacto | Detecções |
|-----|------|-----------|---------|-----------|
| **CVE-2022-22954** | 9.8 | VMware Workspace ONE Access RCE | Remote Code Execution | ×1 |
| **CVE-2021-41773** | 7.5 | Apache Path Traversal | Acesso não autorizado a ficheiros | ×5 |
| **CVE-2021-42013** | 9.8 | Apache Path Traversal (bypass) | RCE através de path traversal | ×1 |

#### CVE-2022-22954 (VMware RCE)

**Descrição**: Vulnerabilidade crítica no VMware Workspace ONE Access que permite execução remota de código através de Server-Side Template Injection (SSTI).

**Scenario CrowdSec**: `vmware-cve-2022-22954`

**Exemplo de ataque bloqueado**:
```
GET /catalog-portal/ui/oauth/verify?error=&deviceUdid=$
{%23_memberAccess[%23_memberAccess...}
```

---

#### CVE-2021-41773 (Apache Path Traversal)

**Descrição**: Vulnerabilidade no Apache HTTP Server 2.4.49 que permite path traversal e potencial RCE.

**Scenario CrowdSec**: `http-cve-2021-41773`

**Exemplo de ataque bloqueado**:
```
GET /cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh
```

---

#### CVE-2021-42013 (Apache Path Traversal Bypass)

**Descrição**: Bypass da correção do CVE-2021-41773 no Apache 2.4.50, permitindo novamente path traversal e RCE.

**Scenario CrowdSec**: `http-cve-2021-42013`

**Exemplo de ataque bloqueado**:
```
POST /cgi-bin/.%%32%65/.%%32%65/.%%32%65/bin/sh
```

---

## 🎭 Top Scenarios Acionados

### Rankings de Detecções (Últimos 7 Dias)

| Posição | Scenario | Triggers | Tipo | Descrição |
|---------|----------|----------|------|-----------|
| 🥇 | **http-bad-user-agent** | ×7 | Detection | User-agents suspeitos (scanners) |
| 🥈 | **http-probing** | ×7 | Detection | Tentativas de descoberta de vulnerabilidades |
| 🥉 | **http-cve-2021-41773** | ×5 | Exploit | Exploração Apache Path Traversal |
| 4 | **http-sensitive-files** | ×2 | Detection | Acesso a ficheiros sensíveis (.env, .git) |
| 5 | **http-open-proxy** | ×2 | Detection | Tentativas de usar servidor como proxy |
| 6 | **vmware-cve-2022-22954** | ×1 | Exploit | Exploração VMware RCE |
| 7 | **http-cve-2021-42013** | ×1 | Exploit | Bypass Apache Path Traversal |
| 8 | **http-cve-probing** | ×1 | Detection | Scanning de múltiplas CVEs |

---

## 🛡️ Bouncers (Executores de Decisões)

### Tabela de Bouncers por Servidor

| Servidor | Bouncer | Versão | Tipo | Função |
|----------|---------|--------|------|--------|
| **Web Server** | cs-firewall-bouncer | v0.0.34 | Firewall | iptables - bloqueio nível OS |
| **Web Server** | cs-cloudflare-bouncer | v0.3.0 | Edge WAF | Cloudflare - bloqueio na edge |
| **Web Server** | crowdsec-nginx-bouncer | v1.1.3 | Web Server | NGINX - bloqueio aplicacional |
| **File Server** | cs-firewall-bouncer | v0.0.34 | Firewall | iptables - bloqueio nível OS |
| **Domain Server** | cs-firewall-bouncer | v0.0.34 | Firewall | iptables - bloqueio nível OS |
| **mailcow** | cs-firewall-bouncer | v0.0.34 | Firewall | iptables - bloqueio nível OS |

### Descrição dos Bouncers

#### 1. cs-firewall-bouncer (iptables)

**Função**: Bloqueia IPs maliciosos diretamente no firewall do sistema operativo usando iptables/nftables.

**Localização**: Todos os 4 servidores

**Configuração**: `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`

**Comandos úteis**:
```bash
# Ver IPs banidos
sudo iptables -L DOCKER-USER -n -v

# Reiniciar bouncer
sudo systemctl restart crowdsec-firewall-bouncer

# Ver logs
sudo journalctl -u crowdsec-firewall-bouncer -f
```

---

#### 2. cs-cloudflare-bouncer

**Função**: Sincroniza decisões de ban com o Cloudflare WAF, bloqueando atacantes na edge (antes de chegarem ao servidor).

**Localização**: Web Server apenas

**Configuração**: `/etc/crowdsec/bouncers/crowdsec-cloudflare-bouncer.yaml`

**Vantagens**:
- Bloqueio acontece antes do tráfego chegar ao servidor
- Reduz carga no servidor origin
- Aproveitamento da rede global Cloudflare

**Comandos úteis**:
```bash
# Forçar sincronização
sudo crowdsec-cloudflare-bouncer -c /etc/crowdsec/bouncers/crowdsec-cloudflare-bouncer.yaml

# Ver status
sudo systemctl status crowdsec-cloudflare-bouncer
```

---

#### 3. crowdsec-nginx-bouncer (Lua)

**Função**: Módulo NGINX que verifica IPs banidos antes de processar requisições HTTP.

**Localização**: Web Server apenas

**Configuração**: `/etc/nginx/conf.d/crowdsec_nginx.conf`

**Vantagens**:
- Bloqueio a nível de aplicação
- Pode mostrar páginas personalizadas de ban
- Integração nativa com NGINX

---

## 📚 Blocklists Disponíveis

### Blocklists Sugeridas (Não Instaladas)

O CrowdSec Console sugere 3 blocklists adicionais que poderiam reduzir ainda mais os alerts:

| Blocklist | IPs | Redução Estimada | Recomendação |
|-----------|-----|------------------|--------------|
| **Firehol greensnow.co list** | 5.09k | -29% alerts | ✅ Altamente recomendado |
| **Public Internet Scanners** | 8.25k | -21% alerts | ✅ Recomendado |
| **CrowdSec CVE-2024-4577** | 1.90k | -19% alerts | ⚠️ Avaliar |

#### Como Subscrever Blocklists

```bash
# Instalar blocklist collection
sudo cscli collections install crowdsecurity/seo-bots-whitelist

# Instalar blocklist específica
sudo cscli parsers install crowdsecurity/whitelists

# Listar blocklists disponíveis
sudo cscli hub list -t blocklists

# Verificar blocklists instaladas
sudo cscli blocklists list
```

---

## 🔧 Gestão e Manutenção

### Comandos Essenciais

#### Verificar Status

```bash
# Status do serviço CrowdSec
sudo systemctl status crowdsec

# Métricas em tempo real
sudo cscli metrics

# Ver decisões ativas
sudo cscli decisions list

# Ver alerts recentes
sudo cscli alerts list

# Ver bouncers registados
sudo cscli bouncers list
```

---

#### Gestão de Decisões

```bash
# Adicionar ban manual (24 horas)
sudo cscli decisions add --ip 1.2.3.4 --duration 24h --reason "Manual ban"

# Remover ban específico
sudo cscli decisions delete --ip 1.2.3.4

# Limpar todas as decisões
sudo cscli decisions delete --all

# Adicionar IP à whitelist
sudo cscli decisions add --ip 192.168.1.10 --type whitelist
```

---

#### Gestão de Scenarios e Collections

```bash
# Listar scenarios instalados
sudo cscli scenarios list

# Instalar scenario
sudo cscli scenarios install crowdsecurity/http-bruteforce

# Atualizar scenarios
sudo cscli scenarios upgrade --all

# Listar collections instaladas
sudo cscli collections list

# Instalar collection completa
sudo cscli collections install crowdsecurity/linux
```

---

#### Gestão de Parsers

```bash
# Listar parsers instalados
sudo cscli parsers list

# Testar parser
sudo cscli parsers test crowdsecurity/nginx-logs

# Instalar parser
sudo cscli parsers install crowdsecurity/postfix-logs
```

---

### Atualizar CrowdSec

```bash
# Atualizar hub (scenarios, parsers, collections)
sudo cscli hub update

# Atualizar todos os componentes instalados
sudo cscli hub upgrade

# Atualizar CrowdSec engine
sudo apt update && sudo apt upgrade crowdsec

# Reiniciar após atualização
sudo systemctl restart crowdsec
sudo systemctl restart crowdsec-firewall-bouncer
```

---

### Backup da Configuração

```bash
# Backup da base de dados local
sudo sqlite3 /var/lib/crowdsec/data/crowdsec.db ".backup /backup/crowdsec-$(date +%Y%m%d).db"

# Backup da configuração
sudo tar -czf /backup/crowdsec-config-$(date +%Y%m%d).tar.gz \
  /etc/crowdsec/ \
  /var/lib/crowdsec/data/

# Exportar decisões ativas
sudo cscli decisions list -o json > /backup/decisions-$(date +%Y%m%d).json
```

---

## 🐛 Troubleshooting

### Problema 1: Engine não aparece no Console

**Sintomas**: Engine registado localmente mas não visível em app.crowdsec.net

**Diagnóstico**:
```bash
# Verificar registro no LAPI
sudo cscli machines list

# Verificar conectividade com CAPI
sudo cscli capi status

# Ver logs de sincronização
sudo tail -f /var/log/crowdsec.log | grep -i capi
```

**Solução**:
```bash
# Re-registar engine
sudo cscli console enroll <enrollment-key>

# Reiniciar serviço
sudo systemctl restart crowdsec
```

---

### Problema 2: Bouncers não bloqueiam IPs

**Sintomas**: Decisões criadas mas IPs não são bloqueados

**Diagnóstico**:
```bash
# Verificar status do bouncer
sudo systemctl status crowdsec-firewall-bouncer

# Ver decisões do bouncer
sudo cscli bouncers list

# Verificar iptables
sudo iptables -L DOCKER-USER -n -v | grep DROP
```

**Solução**:
```bash
# Reiniciar bouncer
sudo systemctl restart crowdsec-firewall-bouncer

# Verificar API key do bouncer
sudo cat /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml

# Re-gerar API key se necessário
sudo cscli bouncers add firewall-bouncer
```

---

### Problema 3: Falsos Positivos

**Sintomas**: IPs legítimos sendo banidos

**Diagnóstico**:
```bash
# Ver razão do ban
sudo cscli decisions list --ip <IP>

# Ver alerts associados
sudo cscli alerts list --ip <IP>

# Ver scenario que gerou o ban
sudo cscli alerts inspect <alert-id>
```

**Solução**:
```bash
# Remover ban imediatamente
sudo cscli decisions delete --ip <IP>

# Adicionar à whitelist permanentemente
sudo cscli decisions add --ip <IP> --type whitelist --reason "Serviço legítimo"

# Desativar scenario problemático (temporariamente)
sudo cscli scenarios remove <scenario-name>
```

---

### Problema 4: Alta Utilização de CPU

**Sintomas**: CrowdSec consumindo muitos recursos

**Diagnóstico**:
```bash
# Ver processos CrowdSec
ps aux | grep crowdsec

# Ver uso de recursos
top -p $(pgrep crowdsec)

# Ver scenarios ativos
sudo cscli metrics
```

**Solução**:
```bash
# Reduzir frequência de parsing (não recomendado)
# Editar /etc/crowdsec/config.yaml e aumentar poll_interval

# Desativar scenarios não essenciais
sudo cscli scenarios list
sudo cscli scenarios remove <scenario-menos-importante>

# Limpar decisões antigas
sudo cscli decisions delete --all
```

---

### Problema 5: Logs não sendo parseados

**Sintomas**: Zero alerts mesmo com tráfego suspeito

**Diagnóstico**:
```bash
# Verificar status dos parsers
sudo cscli metrics

# Testar parsing de log
echo '<linha-de-log>' | sudo cscli parsers test crowdsecurity/nginx-logs

# Ver logs de erro
sudo tail -f /var/log/crowdsec.log | grep -i error
```

**Solução**:
```bash
# Verificar caminho dos logs em /etc/crowdsec/acquis.yaml
sudo cat /etc/crowdsec/acquis.yaml

# Corrigir permissões
sudo chmod 644 /var/log/nginx/*.log
sudo usermod -aG adm crowdsec

# Reiniciar CrowdSec
sudo systemctl restart crowdsec
```

---

## 📊 Dashboards e Monitorização

### CrowdSec Console (Web)

**URL**: https://app.crowdsec.net

**Funcionalidades**:
- Visão global de todos os engines
- Métricas de ataques prevenidos
- Timeline de eventos
- Gestão de blocklists
- Alertas e notificações

---

### Metabase Dashboard (Local)

CrowdSec oferece um dashboard Metabase para visualização local:

```bash
# Instalar Metabase
sudo cscli dashboard setup

# Iniciar dashboard
sudo cscli dashboard start

# Aceder ao dashboard
# http://localhost:3000
# Credenciais padrão: crowdsec / !!Cr0wdS3c_M3t4b4s3??
```

**Gráficos disponíveis**:
- Alerts por tipo ao longo do tempo
- Top IPs atacantes
- Top países de origem
- Decisões ativas vs expiradas
- Scenarios mais acionados

---

### Integração com Prometheus/Grafana

```yaml
# /etc/crowdsec/config.yaml
prometheus:
  enabled: true
  level: full
  listen_addr: 127.0.0.1
  listen_port: 6060
```

Métricas disponíveis em `http://localhost:6060/metrics`

---

## 🔗 Integrações

### Cloudflare WAF

```
┌─────────────┐     Decisions     ┌─────────────┐
│  CrowdSec   │ ─────────────── → │ Cloudflare  │
│   Engine    │   API Sync (5min) │     WAF     │
│ (Web Server)│ ← ─────────────── │   (Edge)    │
└─────────────┘   Ban Lists       └─────────────┘
```

**Configuração**: `/etc/crowdsec/bouncers/crowdsec-cloudflare-bouncer.yaml`

**Benefícios**:
- Bloqueio antes do tráfego chegar ao servidor
- Redução de carga no origin
- Aproveitamento da rede global Cloudflare

---

### NGINX Web Server

```
┌──────────┐     Check IP       ┌──────────┐
│  Client  │ ───────────────── →│  NGINX   │
│          │                    │          │
│          │                    │    ↓     │
│          │                    │ CrowdSec │
│          │                    │  Lua     │
│          │                    │ Module   │
│          │                    │    ↓     │
│          │ ← ──────────────── │ 403 Ban  │
└──────────┘   ou Allow Request └──────────┘
```

**Configuração**: Módulo Lua carregado automaticamente pelo NGINX

---

### Firewall (iptables)

Todas as decisões são automaticamente adicionadas ao iptables:

```bash
# Ver regras CrowdSec
sudo iptables -L DOCKER-USER -n -v | grep crowdsec

# Exemplo de regra
DROP all -- 87.121.94.116 0.0.0.0/0
```

---

## 📖 Boas Práticas

### 1. Manutenção Regular

✅ **Fazer**:
- Atualizar hub semanalmente (`cscli hub update && cscli hub upgrade`)
- Revisar decisões ativas mensalmente
- Monitorizar falsos positivos
- Manter bouncers atualizados

❌ **Evitar**:
- Desativar scenarios sem entender impacto
- Ignorar updates de segurança
- Confiar cegamente em todas as decisões CAPI

---

### 2. Tuning de Scenarios

- Começar com collections padrão
- Adicionar scenarios específicos conforme necessidade
- Testar scenarios em modo "simulation" antes de production
- Documentar mudanças e razões

---

### 3. Gestão de Whitelist

```bash
# Sempre adicionar IPs internos à whitelist
sudo cscli decisions add --ip 192.168.1.0/24 --type whitelist
sudo cscli decisions add --ip 10.0.0.0/8 --type whitelist

# Adicionar serviços conhecidos (Cloudflare, monitoring, etc)
sudo cscli decisions add --ip <cloudflare-ip-range> --type whitelist
```

---

### 4. Monitorização Proativa

- Configurar alertas no Console para picos de ataques
- Revisar semanalmente top atacantes
- Investigar novos CVEs detectados
- Subscrever a blocklists recomendadas

---

## 📚 Recursos Adicionais

### Documentação Oficial

- [CrowdSec Docs](https://docs.crowdsec.net/)
- [Hub (Scenarios/Parsers)](https://hub.crowdsec.net/)
- [Community Forum](https://discourse.crowdsec.net/)
- [GitHub Repository](https://github.com/crowdsecurity/crowdsec)

---

### Collections Recomendadas

| Collection | Descrição |
|------------|-----------|
| `crowdsecurity/linux` | Proteção base para servidores Linux |
| `crowdsecurity/nginx` | Scenarios específicos para NGINX |
| `crowdsecurity/apache2` | Scenarios para Apache (se aplicável) |
| `crowdsecurity/sshd` | Proteção contra bruteforce SSH |
| `crowdsecurity/postfix` | Proteção para servidores de email |
| `crowdsecurity/smb` | Proteção Samba/SMB |

---

## 🔗 Ver Também

- [README.md](README.md) - Visão geral de segurança perimetral
- [01-cloudflare.md](01-cloudflare.md) - Proteção externa com Cloudflare
- [../08-mailcow/](../08-mailcow/) - Integração com servidor de email
- [../05-web-server/](../05-web-server/) - Configuração no servidor web

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

<div align="center">

**[⬅️ Voltar: Cloudflare](01-cloudflare.md)** | **[🏠 Documentação Principal](README.md)**

</div>

---

*Última atualização: Dezembro 2025*
