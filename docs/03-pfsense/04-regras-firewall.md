# 🛡️ Regras de Firewall

> Documentação completa das regras de firewall configuradas no pfSense, organizadas por zona de segurança (WAN, LAN, DMZ, VPN).

---

## 📋 Filosofia de Segurança

### Princípios Aplicados

- **Default Deny All**: Tudo bloqueado por padrão
- **Least Privilege**: Apenas o necessário é permitido
- **Zone-Based Security**: Segmentação em 4 zonas isoladas
- **Stateful Inspection**: Controlo de sessões TCP/UDP
- **Logging**: Registo de tráfego negado para auditoria

### Ordem de Processamento

```
┌──────────────────────────────────────────────────────┐
│  1. Regras da Interface (top-to-bottom)              │
│     - Primeira match = ação aplicada                 │
│     - Sem match = default deny (implícito)           │
├──────────────────────────────────────────────────────┤
│  2. Regras de Saída (Outbound)                       │
│     - Processadas após inbound                       │
├──────────────────────────────────────────────────────┤
│  3. NAT (Port Forward/Outbound NAT)                  │
│     - Processado antes das regras de firewall        │
└──────────────────────────────────────────────────────┘
```

---

## 🌐 Regras WAN (Interface Externa)

```
Firewall → Rules → WAN
```

### Estratégia WAN

- ❌ **Default Deny All** (implícito)
- ✅ Port forwarding apenas para serviços públicos
- ✅ OpenVPN para acesso VPN
- ✅ Gestão remota limitada (apenas Proxmox host)

### Lista de Regras

| # | Ação | Proto | Origem | Porta Origem | Destino | Porta Destino | Descrição |
|---|------|-------|--------|--------------|---------|---------------|-----------|
| 1 | ✅ Pass | TCP | 192.168.31.34 | * | WAN address | 8007 | Proxmox → PBS UI |
| 2 | ✅ Pass | TCP | * | * | MAIL_IP | 25 | SMTP → Mailcow |
| 3 | ✅ Pass | TCP | * | * | MAIL_IP | 110 | POP3 → Mailcow |
| 4 | ✅ Pass | TCP | * | * | MAIL_IP | 143 | IMAP → Mailcow |
| 5 | ✅ Pass | TCP | * | * | MAIL_IP | 465 | SMTPS → Mailcow |
| 6 | ✅ Pass | TCP | * | * | MAIL_IP | 587 | Submission → Mailcow |
| 7 | ✅ Pass | TCP | * | * | MAIL_IP | 993 | IMAPS → Mailcow |
| 8 | ✅ Pass | TCP | * | * | MAIL_IP | 995 | POP3S → Mailcow |
| 9 | ✅ Pass | TCP | * | * | MAIL_IP | 4190 | Sieve → Mailcow |
| 10 | ✅ Pass | TCP | * | * | WEB_IP | 80 | HTTP → Webserver |
| 11 | ✅ Pass | TCP | * | * | WEB_IP | 443 | HTTPS → Webserver |
| 12 | ✅ Pass | UDP | * | * | WAN address | 1194 | OpenVPN Local |
| 13 | ✅ Pass | UDP | * | * | WAN address | 1195 | OpenVPN RADIUS |
| - | ❌ Block | * | * | * | * | * | Default Deny (implícito) |

### Configuração Detalhada

#### Regra 1: Proxmox → PBS

```
Action: Pass
Interface: WAN
Address Family: IPv4
Protocol: TCP

Source:
- Type: Single host or alias
- Address: 192.168.31.34 (PROXMOX_HOST)

Destination:
- Type: WAN address
- Port: 8007 (PBS UI)

Extra Options:
- Log: ✅ Log packets that are handled by this rule
- Description: Proxmox VE → PBS Management UI
```

#### Regra 2-9: Mailcow Services

```
Action: Pass
Interface: WAN
Address Family: IPv4
Protocol: TCP

Source:
- Type: any

Destination:
- Type: Single host or alias
- Address: MAIL_IP (10.0.0.20)
- Port: [25|110|143|465|587|993|995|4190]

Extra Options:
- Log: ❌ (muito tráfego)
- Description: Public Mail - [SMTP|POP3|IMAP|SMTPS|Submission|IMAPS|POP3S|Sieve]
```

#### Regra 10-11: Web Services

```
Action: Pass
Interface: WAN
Address Family: IPv4
Protocol: TCP

Source:
- Type: any

Destination:
- Type: Single host or alias
- Address: WEB_IP (10.0.0.30)
- Port: [80|443]

Extra Options:
- Log: ❌
- Description: Public Web - [HTTP|HTTPS]
```

#### Regra 12-13: OpenVPN

```
Action: Pass
Interface: WAN
Address Family: IPv4
Protocol: UDP

Source:
- Type: any

Destination:
- Type: WAN address
- Port: [1194|1195]

Extra Options:
- Log: ✅ Log packets (útil para troubleshooting)
- Description: OpenVPN Server - [Local Auth|RADIUS Auth]
```

---

## 🏠 Regras LAN (Rede Interna)

```
Firewall → Rules → LAN
```

### Estratégia LAN

- ✅ Acesso total à Internet
- ✅ Acesso controlado aos serviços internos (DC, PBS, Files)
- ✅ Acesso limitado à DMZ (apenas serviços autorizados)
- ❌ Bloqueio do resto da DMZ

### Lista de Regras

| # | Ação | Proto | Origem | Porta Origem | Destino | Porta Destino | Descrição |
|---|------|-------|--------|--------------|---------|---------------|-----------|
| 1 | ✅ Pass | TCP | LAN net | * | LAN address | 8009, 80, 22 | Anti-Lockout Rule |
| 2 | ✅ Pass | TCP/UDP | LAN net | * | * | 53 | DNS |
| 3 | ✅ Pass | TCP | LAN net | * | * | 80, 443 | HTTP/HTTPS Internet |
| 4 | ✅ Pass | UDP | LAN net | * | * | 123 | NTP |
| 5 | ✅ Pass | ICMP | LAN net | * | * | * | ICMP (ping) |
| 6 | ✅ Pass | TCP/UDP | LAN net | * | DC_IP | AD_PORTS | LAN → DC (AD/LDAP) |
| 7 | ✅ Pass | TCP | LAN net | * | DC_IP | SMB_PORTS | LAN → DC (SMB) |
| 8 | ✅ Pass | TCP | LAN net | * | DC_IP | RPC_PORTS | LAN → DC (RPC) |
| 9 | ✅ Pass | TCP/UDP | LAN net | * | DC_IP | 53 | LAN → DC (DNS) |
| 10 | ✅ Pass | UDP | LAN net | * | DC_IP | 67, 68 | LAN → DC (DHCP) |
| 11 | ✅ Pass | TCP | LAN net | * | FILESERVER_IP | 80, 443 | LAN → Nextcloud |
| 12 | ✅ Pass | TCP | LAN net | * | FILESERVER_IP | 22 | LAN → Files (SSH) |
| 13 | ✅ Pass | TCP | LAN net | * | PBS_IP | 8007 | LAN → PBS UI |
| 14 | ✅ Pass | TCP | LAN net | * | PBS_IP | 22 | LAN → PBS (SSH) |
| 15 | ✅ Pass | TCP | LAN net | * | LAN address | 443 | LAN → pfSense WebUI |
| 16 | ✅ Pass | TCP | LAN net | * | WEB_IP | 80, 443 | LAN → DMZ Web |
| 17 | ✅ Pass | TCP | FILESERVER_IP | * | MAIL_IP | 80, 443 | Nextcloud → Mailcow |
| 18 | ❌ Reject | * | LAN net | * | DMZ_NET | * | Block LAN → DMZ (rest) |

### Configuração Detalhada

#### Regra 1: Anti-Lockout

```
Action: Pass
Interface: LAN
Protocol: TCP

Source: LAN net

Destination:
- Type: LAN address
- Port Range: 8009, 80, 22

Description: Anti-Lockout Rule - Management Access
```

#### Regra 2-5: Internet Access

```
# DNS
Action: Pass | Protocol: TCP/UDP
Source: LAN net | Destination: any | Port: 53

# HTTP/HTTPS
Action: Pass | Protocol: TCP
Source: LAN net | Destination: any | Port: 80, 443

# NTP
Action: Pass | Protocol: UDP
Source: LAN net | Destination: any | Port: 123

# ICMP
Action: Pass | Protocol: ICMP
Source: LAN net | Destination: any
```

#### Regra 6-10: LAN → Domain Controller

```
# Active Directory Ports
Action: Pass
Protocol: TCP/UDP
Source: LAN net
Destination: DC_IP (192.168.1.10)
Port: AD_PORTS (88, 389, 464, 636, 3268, 3269)
Description: LAN → DC - Active Directory Services

# SMB
Port: SMB_PORTS (139, 445)
Description: LAN → DC - File Sharing

# RPC
Port: RPC_PORTS (135, 49152-49154)
Description: LAN → DC - Remote Procedure Call

# DNS
Port: 53
Description: LAN → DC - DNS Queries

# DHCP
Protocol: UDP
Port: 67, 68
Description: LAN → DC - DHCP Requests
```

#### Regra 11-14: LAN → Internal Services

```
# Nextcloud
Action: Pass | Protocol: TCP
Source: LAN net
Destination: FILESERVER_IP (192.168.1.40)
Port: 80, 443
Description: LAN → Nextcloud Web Interface

# SSH to Files
Port: 22
Description: LAN → Files Server (SSH Management)

# PBS
Destination: PBS_IP (192.168.1.30)
Port: 8007
Description: LAN → Proxmox Backup Server UI

# SSH to PBS
Port: 22
Description: LAN → PBS (SSH Management)
```

#### Regra 15: LAN → pfSense

```
Action: Pass
Protocol: TCP
Source: LAN net
Destination: LAN address (192.168.1.1)
Port: 443
Description: LAN → pfSense WebUI
```

#### Regra 16-17: LAN → DMZ (Selective)

```
# Web Server
Action: Pass | Protocol: TCP
Source: LAN net
Destination: WEB_IP (10.0.0.30)
Port: 80, 443
Description: LAN → DMZ Webserver

# Nextcloud → Mailcow (for integrations)
Action: Pass | Protocol: TCP
Source: FILESERVER_IP (192.168.1.40)
Destination: MAIL_IP (10.0.0.20)
Port: 80, 443
Description: Nextcloud → Mailcow Integration
```

#### Regra 18: Block LAN → DMZ (Rest)

```
Action: Reject
Protocol: Any
Source: LAN net
Destination: DMZ_NET (10.0.0.0/24)
Port: Any

Extra Options:
- Log: ✅ Log packets
- Description: Block LAN → DMZ - Default Deny Remaining Traffic
```

---

## 🔒 Regras DMZ (Zona Desmilitarizada)

```
Firewall → Rules → DMZ
```

### Estratégia DMZ

- ✅ Acesso limitado à Internet (DNS, SMTP, HTTP/HTTPS, NTP)
- ✅ Acesso ao DC para autenticação (LDAP, Kerberos)
- ✅ Comunicação específica entre servidores DMZ
- ❌ Bloqueio geral inter-server DMZ
- ❌ Bloqueio de acesso à LAN (exceto necessário)

### Lista de Regras

| # | Ação | Proto | Origem | Porta Origem | Destino | Porta Destino | Descrição |
|---|------|-------|--------|--------------|---------|---------------|-----------|
| 1 | ✅ Pass | TCP | DMZ net | * | !LAN_NET | 443 | Force HTTPS through proxy |
| 2 | ✅ Pass | ICMP | DMZ net | * | * | * | DMZ → Internet (ICMP) |
| 3 | ✅ Pass | TCP | DMZ net | * | !LAN_NET | 25 | DMZ → Internet (SMTP) |
| 4 | ✅ Pass | TCP/UDP | DMZ net | * | !LAN_NET | 53 | DMZ → Internet (DNS) |
| 5 | ✅ Pass | TCP | DMZ net | * | !LAN_NET | 80, 443 | DMZ → Internet (HTTP/HTTPS) |
| 6 | ✅ Pass | UDP | DMZ net | * | !LAN_NET | 123 | DMZ → Internet (NTP) |
| 7 | ✅ Pass | TCP | DMZ net | * | WAZUH_IP | 1514, 1515 | DMZ → Wazuh Manager |
| 8 | ✅ Pass | TCP/UDP | DMZ net | * | DC_IP | 389, 636 | DMZ → DC (LDAP/LDAPS) |
| 9 | ✅ Pass | TCP/UDP | DMZ net | * | DC_IP | 88 | DMZ → DC (Kerberos) |
| 10 | ✅ Pass | TCP | DMZ net | * | DC_IP | 445 | DMZ → DC (MS-DS) |
| 11 | ✅ Pass | TCP | DMZ net | * | DC_IP | RPC_PORTS | DMZ → DC (RPC) |
| 12 | ✅ Pass | TCP/UDP | DMZ net | * | DC_IP | 53 | DMZ → DC (DNS) |
| 13 | ✅ Pass | TCP/UDP | DMZ net | * | DC_IP | 464 | DMZ → DC (KDC) |
| 14 | ✅ Pass | UDP | DMZ net | * | DC_IP | 123 | DMZ → DC (NTP) |
| 15 | ✅ Pass | ICMP | DMZ net | * | DC_IP | * | DMZ → DC (PING) |
| 16 | ✅ Pass | TCP | MAIL_IP | * | FILESERVER_IP | 80, 443 | Mail → Nextcloud |
| 17 | ✅ Pass | TCP | FILESERVER_IP | * | MAIL_IP | 80, 443 | Nextcloud → Mail |
| 18 | ✅ Pass | TCP | FILESERVER_IP | * | DC_IP | 389, 636 | Files → DC (LDAP) |
| 19 | ✅ Pass | TCP | WEB_IP | * | MAIL_IP | 993 | Web → Mail (IMAPS Z-Push) |
| 20 | ✅ Pass | TCP | WEB_IP | * | MAIL_IP | 25, 587 | Web → Mail (SMTP) |
| 21 | ❌ Reject | * | DMZ net | * | DMZ_SERVERS | * | Block DMZ Inter-Server |
| 22 | ❌ Reject | * | DMZ net | * | LAN_NET | * | Block DMZ → LAN |

### Configuração Detalhada

#### Regra 1: Force HTTPS Proxy

```
Action: Pass
Protocol: TCP
Source: DMZ net
Destination: Invert match - LAN_NET
Port: 443

Description: Force DMZ HTTPS through proxy/inspection
```

#### Regra 2-6: DMZ → Internet (Limited)

```
# ICMP
Action: Pass | Protocol: ICMP
Source: DMZ net | Destination: !LAN_NET

# SMTP (sending mail)
Action: Pass | Protocol: TCP
Source: DMZ net | Destination: !LAN_NET | Port: 25

# DNS
Action: Pass | Protocol: TCP/UDP
Source: DMZ net | Destination: !LAN_NET | Port: 53

# HTTP/HTTPS (updates, packages)
Action: Pass | Protocol: TCP
Source: DMZ net | Destination: !LAN_NET | Port: 80, 443

# NTP (time sync)
Action: Pass | Protocol: UDP
Source: DMZ net | Destination: !LAN_NET | Port: 123
```

#### Regra 7: DMZ → Wazuh

```
Action: Pass
Protocol: TCP
Source: DMZ net
Destination: WAZUH_IP (192.168.1.50)
Port: 1514, 1515

Description: DMZ Servers → Wazuh Manager (Agent Communication)
```

#### Regra 8-15: DMZ → DC (Authentication)

```
# LDAP/LDAPS
Action: Pass | Protocol: TCP/UDP
Source: DMZ net | Destination: DC_IP
Port: 389, 636
Description: DMZ → DC - LDAP Authentication

# Kerberos
Port: 88
Description: DMZ → DC - Kerberos KDC

# SMB
Protocol: TCP | Port: 445
Description: DMZ → DC - SMB/CIFS

# RPC
Port: RPC_PORTS
Description: DMZ → DC - RPC

# DNS
Protocol: TCP/UDP | Port: 53
Description: DMZ → DC - DNS Resolution

# Kpasswd
Protocol: TCP/UDP | Port: 464
Description: DMZ → DC - Password Changes

# NTP
Protocol: UDP | Port: 123
Description: DMZ → DC - Time Synchronization

# ICMP
Protocol: ICMP
Description: DMZ → DC - PING
```

#### Regra 16-20: DMZ Inter-Server (Specific)

```
# Mail ↔ Nextcloud (bidirectional)
Action: Pass | Protocol: TCP
Source: MAIL_IP <-> FILESERVER_IP
Destination: FILESERVER_IP <-> MAIL_IP
Port: 80, 443
Description: Mailcow ↔ Nextcloud Integration

# Nextcloud → DC LDAP
Action: Pass | Protocol: TCP
Source: FILESERVER_IP
Destination: DC_IP
Port: 389, 636
Description: Nextcloud → DC LDAP Auth

# Webserver → Mail (Z-Push ActiveSync)
Action: Pass | Protocol: TCP
Source: WEB_IP
Destination: MAIL_IP
Port: 993 (IMAPS), 25, 587 (SMTP)
Description: Webserver → Mail (Z-Push, Contact sync)
```

#### Regra 21-22: DMZ Isolation

```
# Block Inter-Server
Action: Reject
Protocol: Any
Source: DMZ net
Destination: DMZ_SERVERS
Port: Any
Log: ✅
Description: Block DMZ Inter-Server Communication (except specific rules above)

# Block DMZ → LAN
Action: Reject
Protocol: Any
Source: DMZ net
Destination: LAN_NET
Port: Any
Log: ✅
Description: Block DMZ → LAN - Default Deny
```

---

## 🔐 Regras OpenVPN (Hierarquia por Níveis)

```
Firewall → Rules → OpenVPN
```

### Estratégia VPN

- ✅ Hierarquia de acesso por grupos AD (5 níveis)
- ✅ VPN Backup com acesso total (emergência)
- ✅ Regras ordenadas: mais privilegiado primeiro
- ❌ Default Deny no final

### Hierarquia de Níveis

```
L0 - Backup VPN (10.9.0.0/24)     → Acesso Total (emergência)
L1 - Admin (TI)                   → Acesso Total
L2 - Gestão (Gestores)            → LAN + DMZ + Internet
L3 - Departamentos                → DC + Internet
L4 - Users                        → Mail + Nextcloud + Internet
L5 - DEFAULT DENY                 → Block All
```

### Lista de Regras

| # | Ação | Proto | Origem | Porta Origem | Destino | Porta Destino | Descrição |
|---|------|-------|--------|--------------|---------|---------------|-----------|
| **L0 - Backup VPN** |
| 1 | ✅ Pass | * | Alias_VPN_Backup | * | * | * | [L0-BACKUP] VPN Local - Full Access |
| **L1 - Admin (TI)** |
| 2 | ✅ Pass | * | Alias_VPN_TI | * | LAN_NET | * | [L1-Admin] TI → LAN (Full) |
| 3 | ✅ Pass | * | Alias_VPN_TI | * | DMZ_NET | * | [L1-Admin] TI → DMZ (Full) |
| 4 | ✅ Pass | * | Alias_VPN_TI | * | * | * | [L1-Admin] TI → Internet |
| **L2 - Gestão** |
| 5 | ✅ Pass | * | Alias_VPN_Gestores | * | LAN_NET | * | [L2-Gestao] Gestores → LAN |
| 6 | ✅ Pass | * | Alias_VPN_Gestores | * | DMZ_NET | * | [L2-Gestao] Gestores → DMZ |
| 7 | ✅ Pass | * | Alias_VPN_Gestores | * | * | * | [L2-Gestao] Gestores → Internet |
| **L3 - Departamentos** |
| 8 | ✅ Pass | TCP | Alias_VPN_Financeiro | * | DC_IP | SMB_PORTS | [L3-Dept] Financeiro → DC (SMB) |
| 9 | ✅ Pass | TCP/UDP | Alias_VPN_Financeiro | * | DC_IP | 53 | [L3-Dept] Financeiro → DC (DNS) |
| 10 | ✅ Pass | * | Alias_VPN_Financeiro | * | * | * | [L3-Dept] Financeiro → Internet |
| 11 | ✅ Pass | TCP | Alias_VPN_Comercial | * | DC_IP | SMB_PORTS | [L3-Dept] Comercial → DC (SMB) |
| 12 | ✅ Pass | TCP/UDP | Alias_VPN_Comercial | * | DC_IP | 53 | [L3-Dept] Comercial → DC (DNS) |
| 13 | ✅ Pass | * | Alias_VPN_Comercial | * | * | * | [L3-Dept] Comercial → Internet |
| **L4 - Users** |
| 14 | ✅ Pass | TCP | Alias_VPN_VPN_Users | * | MAIL_IP | MAIL_PUBLIC | [L4-Users] VPN → Mail |
| 15 | ✅ Pass | TCP | Alias_VPN_VPN_Users | * | FILESERVER_IP | 80, 443 | [L4-Users] VPN → Nextcloud |
| 16 | ✅ Pass | TCP/UDP | Alias_VPN_VPN_Users | * | * | 53 | [L4-Users] VPN → DNS |
| 17 | ✅ Pass | * | Alias_VPN_VPN_Users | * | * | * | [L4-Users] VPN → Internet |
| **L5 - Security** |
| 18 | ❌ Block | * | * | * | * | * | [L5-Security] DEFAULT DENY - Block All |

### Configuração Detalhada

#### Regra 1: L0 - Backup VPN (Emergency)

```
Action: Pass
Protocol: Any
Source: Alias_VPN_Backup (10.9.0.0/24)
Destination: Any
Port: Any

Extra Options:
- Log: ✅
- Description: [L0-BACKUP] VPN Local - Full Access (Emergency)

Nota: Autenticação local, acesso total para emergências
```

#### Regras 2-4: L1 - Admin (TI)

```
# TI → LAN
Action: Pass | Protocol: Any
Source: Alias_VPN_TI (10.8.0.10-59)
Destination: LAN_NET (192.168.1.0/24)
Description: [L1-Admin] TI → LAN (Full Access)

# TI → DMZ
Destination: DMZ_NET (10.0.0.0/24)
Description: [L1-Admin] TI → DMZ (Full Access)

# TI → Internet
Destination: Any
Description: [L1-Admin] TI → Internet (Full Access)
```

#### Regras 5-7: L2 - Gestão

```
# Gestores → LAN
Action: Pass | Protocol: Any
Source: Alias_VPN_Gestores (10.8.0.60-109)
Destination: LAN_NET
Description: [L2-Gestao] Gestores → LAN

# Gestores → DMZ
Destination: DMZ_NET
Description: [L2-Gestao] Gestores → DMZ

# Gestores → Internet
Destination: Any
Description: [L2-Gestao] Gestores → Internet
```

#### Regras 8-13: L3 - Departamentos

```
# Financeiro → DC (SMB)
Action: Pass | Protocol: TCP
Source: Alias_VPN_Financeiro (10.8.0.110-159)
Destination: DC_IP
Port: SMB_PORTS (139, 445)
Description: [L3-Dept] Financeiro → DC (File Shares)

# Financeiro → DC (DNS)
Protocol: TCP/UDP | Port: 53
Description: [L3-Dept] Financeiro → DC (DNS)

# Financeiro → Internet
Protocol: Any | Destination: Any
Description: [L3-Dept] Financeiro → Internet

# Comercial → DC (SMB)
Source: Alias_VPN_Comercial (10.8.0.160-209)
Port: SMB_PORTS
Description: [L3-Dept] Comercial → DC (File Shares)

# Comercial → DC (DNS)
Protocol: TCP/UDP | Port: 53
Description: [L3-Dept] Comercial → DC (DNS)

# Comercial → Internet
Protocol: Any | Destination: Any
Description: [L3-Dept] Comercial → Internet
```

#### Regras 14-17: L4 - Basic Users

```
# VPN Users → Mail
Action: Pass | Protocol: TCP
Source: Alias_VPN_VPN_Users (10.8.0.210-254)
Destination: MAIL_IP
Port: MAIL_PUBLIC (25, 143, 587, 993)
Description: [L4-Users] VPN → Mail Services

# VPN Users → Nextcloud
Protocol: TCP
Destination: FILESERVER_IP
Port: 80, 443
Description: [L4-Users] VPN → Nextcloud

# VPN Users → DNS
Protocol: TCP/UDP
Destination: Any
Port: 53
Description: [L4-Users] VPN → DNS

# VPN Users → Internet
Protocol: Any
Destination: Any
Description: [L4-Users] VPN → Internet
```

#### Regra 18: L5 - Default Deny

```
Action: Block
Protocol: Any
Source: Any
Destination: Any
Port: Any

Extra Options:
- Log: ✅ Log packets
- Description: [L5-Security] DEFAULT DENY - Block All VPN Traffic Not Explicitly Allowed

Nota: Esta regra garante que apenas o tráfego explicitamente permitido passa
```

---

## 📊 Resumo de Regras

### Estatísticas por Interface

| Interface | Regras Pass | Regras Block/Reject | Total |
|-----------|-------------|---------------------|-------|
| **WAN** | 13 | 1 (implícito) | 14 |
| **LAN** | 17 | 1 | 18 |
| **DMZ** | 20 | 2 | 22 |
| **OpenVPN** | 17 | 1 | 18 |
| **Total** | **67 regras** | **5 regras** | **72 regras** |

### Portas Mais Utilizadas

| Porta(s) | Protocolo | Serviço | Frequência |
|----------|-----------|---------|------------|
| 80, 443 | TCP | HTTP/HTTPS | 15 regras |
| 53 | TCP/UDP | DNS | 8 regras |
| 389, 636 | TCP/UDP | LDAP/LDAPS | 6 regras |
| 25, 587 | TCP | SMTP | 5 regras |
| 88 | TCP/UDP | Kerberos | 4 regras |
| 445 | TCP | SMB | 4 regras |

---

## 🛠️ Gestão de Regras

### Adicionar Nova Regra

```
Firewall → Rules → [Interface] → Add (top/bottom)

1. Action: Pass/Block/Reject
2. Interface: WAN/LAN/DMZ/OpenVPN
3. Protocol: TCP/UDP/ICMP/Any
4. Source: Selecionar origem
5. Destination: Selecionar destino
6. Destination Port Range: Porta(s)
7. Log: Ativar se necessário
8. Description: Descrição clara
9. Save → Apply Changes
```

### Reordenar Regras

```
Firewall → Rules → [Interface]

- Arrastar e largar (drag & drop)
- Ordem: top-to-bottom (primeira match = ação)
- Save → Apply Changes após reordenar
```

### Ativar/Desativar Regra

```
Firewall → Rules → [Interface]

- Clicar no ícone ✅/❌
- Regra desativada = ⚠️ (ignored)
- Apply Changes para efetivar
```

### Ver Estados Ativos

```
Diagnostics → States

Mostra:
- Sessões ativas
- Estados por protocolo
- Source/Destination
- Tempo restante

Filtros:
- Interface
- Protocol
- Source/Destination
```

---

## 🔍 Logs e Troubleshooting

### Ver Logs de Firewall

```
Status → System Logs → Firewall

Tabs:
- Normal View: Tráfego bloqueado
- Dynamic View: Real-time updates
- Summary View: Estatísticas
```

### Logs em Tempo Real

```bash
# Via SSH/Console
clog /var/log/filter.log | tail -f

# Ver apenas bloqueios
clog /var/log/filter.log | grep -i block

# Ver tráfego de IP específico
clog /var/log/filter.log | grep 192.168.1.10
```

### Troubleshooting Common Issues

#### Problema: Tráfego bloqueado inesperadamente

**Diagnóstico**:
1. Verificar logs: `Status → System Logs → Firewall`
2. Identificar regra que bloqueou
3. Verificar ordem das regras

**Solução**:
- Adicionar regra de pass acima da regra de block
- Ou mover regra existente para cima

#### Problema: Regra não funciona

**Diagnóstico**:
1. Verificar ordem (primeira match vence)
2. Verificar aliases corretos
3. Verificar interface correta

**Solução**:
```
- Ativar logging na regra
- Testar tráfego
- Verificar logs para ver se regra foi aplicada
```

#### Problema: Estados antigos persistem

**Solução**:
```
Diagnostics → States → Reset States

Ou via CLI:
pfctl -F states
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

- [pfSense Firewall Rules](https://docs.netgate.com/pfsense/en/latest/firewall/index.html)
- [Understanding Rule Processing](https://docs.netgate.com/pfsense/en/latest/firewall/rule-methodology.html)
- [Troubleshooting Firewall Rules](https://docs.netgate.com/pfsense/en/latest/troubleshooting/firewall.html)

---

<div align="center">

**[⬅️ Voltar: Aliases](03-aliases.md)** | **[Índice](README.md)** | **[Próximo: NAT e Port Forwarding ➡️](05-nat-port-forwarding.md)**

</div>

---

*Última atualização: Dezembro 2024*
