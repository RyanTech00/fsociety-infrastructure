# 🔐 OpenVPN

> Documentação completa dos servidores OpenVPN configurados no pfSense, incluindo OpenVPN Local (backup) e OpenVPN RADIUS (principal).

---

## 📋 Visão Geral

### Servidores OpenVPN

| Servidor | Porta | Protocolo | Tunnel Network | Autenticação | Função |
|----------|-------|-----------|----------------|--------------|--------|
| **OpenVPN Local** | 1194 | UDP | 10.9.0.0/24 | Local Database | VPN Backup (emergência) |
| **OpenVPN RADIUS** | 1195 | UDP | 10.8.0.0/24 | RADIUS + LDAP | VPN Principal (produção) |

### Arquitetura

```
                    ┌──────────────────────┐
                    │      Internet        │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │   pfSense WAN        │
                    │  192.168.31.100      │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
      ┌───────▼──────┐  ┌──────▼──────┐       │
      │ OpenVPN 1194 │  │OpenVPN 1195 │       │
      │ (Local Auth) │  │(RADIUS Auth)│       │
      │ 10.9.0.0/24  │  │ 10.8.0.0/24 │       │
      └──────┬───────┘  └──────┬──────┘       │
             │                 │               │
             │          ┌──────▼──────┐        │
             │          │   RADIUS    │        │
             │          │   Server    │        │
             │          │192.168.1.10 │        │
             │          └──────┬──────┘        │
             │                 │               │
             │          ┌──────▼──────┐        │
             │          │Active       │        │
             │          │Directory    │        │
             │          │(Samba AD)   │        │
             │          └─────────────┘        │
             │                                 │
             └─────────────────┬───────────────┘
                               │
                    ┌──────────▼───────────┐
                    │   LAN / DMZ          │
                    │   192.168.1.0/24     │
                    │   10.0.0.0/24        │
                    └──────────────────────┘
```

---

## 🔧 Server 1: OpenVPN Local (Backup)

```
VPN → OpenVPN → Servers → OpenVPN Server 1 (UDP:1194)
```

### Informação Geral

| Parâmetro | Valor |
|-----------|-------|
| **Server Mode** | Remote Access (SSL/TLS + User Auth) |
| **Backend for authentication** | Local Database |
| **Protocol** | UDP on IPv4 only |
| **Interface** | WAN |
| **Local Port** | 1194 |
| **Description** | OpenVPN Server Local - Backup VPN |

### Configuração Detalhada

#### General Information

```
Server mode: Remote Access (SSL/TLS + User Auth)
Backend for authentication: Local Database
Protocol: UDP on IPv4 only
Device mode: tun
Interface: WAN
Local port: 1194
Description: OpenVPN Server Local - Backup VPN
```

#### Cryptographic Settings

```
TLS Configuration:
- TLS Key: ✅ Automatically generate a TLS Key
- TLS Key Usage Mode: TLS Authentication
- Peer Certificate Authority: OpenVPN CA (auto-created)
- Peer Certificate Revocation List: None
- Server Certificate: OpenVPN Server Cert (auto-created)
- DH Parameter Length: 2048 bit
- ECDH Curve: none
- Data Encryption Algorithms:
  ✅ CHACHA20-POLY1305
  ✅ AES-256-CBC
- Fallback Data Encryption Algorithm: AES-256-CBC
- Auth digest algorithm: SHA256 (256-bit)
- Hardware Crypto: No Hardware Crypto Acceleration
```

#### Tunnel Settings

```
IPv4 Tunnel Network: 10.9.0.0/24
IPv6 Tunnel Network: (blank)
Redirect IPv4 Gateway: ✅ Force all client traffic through tunnel
Redirect IPv6 Gateway: ❌
IPv4 Local network(s): 192.168.1.0/24, 10.0.0.0/24
IPv6 Local network(s): (blank)
Concurrent connections: 254
Compression: ✅ Adaptive LZO Compression
Type-of-Service: ❌
Inter-Client Communication: ✅ Allow communication between clients
Duplicate Connections: ✅ Allow multiple concurrent connections
```

#### Client Settings

```
Dynamic IP: ✅ Allow connected clients to retain their connections
Topology: Subnet
DNS Servers:
- Server 1: 192.168.1.10 (DC)
- Server 2: 1.1.1.1 (Cloudflare)
DNS Search Domain: fsociety.pt
NTP Servers:
- Server 1: 192.168.1.1 (pfSense)
NetBIOS Options: ❌ Disable NetBIOS
NetBIOS Node Type: none
```

#### Advanced Configuration

```
Custom options:
push "route 192.168.1.0 255.255.255.0"
push "route 10.0.0.0 255.255.255.0"

Verbosity level: 3 (recommended)
```

### Utilizadores Locais

```
System → User Manager → Users
```

| Username | Password | Groups | Descrição |
|----------|----------|--------|-----------|
| admin-emergency | (strong password) | admins | Conta de emergência |
| vpn-backup-1 | (strong password) | vpn-users | Backup user 1 |
| vpn-backup-2 | (strong password) | vpn-users | Backup user 2 |

**Certificados**:
```
System → Cert Manager → Certificates → User Certificates

Para cada utilizador:
- Method: Create an internal Certificate
- Descriptive name: [username]-cert
- Certificate authority: OpenVPN CA
- Key type: RSA
- Key length: 2048 bits
- Lifetime: 3650 days (10 years)
```

### Exportar Configuração Cliente

```
VPN → OpenVPN → Client Export

Server: OpenVPN Server Local (UDP:1194)
Remote Access Server: (auto)
Host Name Resolution: Other
Host Name: vpn.fsociety.pt

Export type:
- Most Clients: Download arquivo .ovpn
- Windows Installer: Download .exe

Para utilizador específico:
- Selecionar utilizador
- Download Configuration
```

**Exemplo ficheiro .ovpn**:
```
client
dev tun
proto udp
remote vpn.fsociety.pt 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
tls-auth ta.key 1
cipher AES-256-CBC
auth SHA256
auth-user-pass
comp-lzo adaptive
verb 3
```

---

## 🌍 Server 2: OpenVPN RADIUS (Principal)

```
VPN → OpenVPN → Servers → OpenVPN Server 2 (UDP:1195)
```

### Informação Geral

| Parâmetro | Valor |
|-----------|-------|
| **Server Mode** | Remote Access (SSL/TLS + User Auth) |
| **Backend for authentication** | RADIUS (DC FSociety) |
| **Protocol** | UDP on IPv4 only |
| **Interface** | WAN |
| **Local Port** | 1195 |
| **Description** | OpenVPN Server Radius - Production VPN |

### Configuração Detalhada

#### General Information

```
Server mode: Remote Access (SSL/TLS + User Auth)
Backend for authentication: RADIUS (DC FSociety)
Protocol: UDP on IPv4 only
Device mode: tun
Interface: WAN
Local port: 1195
Description: OpenVPN Server Radius - Production VPN with AD Auth
```

#### Cryptographic Settings

```
(Idêntico ao Server 1)

TLS Configuration:
- TLS Key: ✅ Automatically generate a TLS Key
- TLS Key Usage Mode: TLS Authentication
- Peer Certificate Authority: OpenVPN CA
- Server Certificate: OpenVPN Server Cert 2
- DH Parameter Length: 2048 bit
- Data Encryption Algorithms:
  ✅ CHACHA20-POLY1305
  ✅ AES-256-CBC
- Auth digest algorithm: SHA256
```

#### Tunnel Settings

```
IPv4 Tunnel Network: 10.8.0.0/24
Redirect IPv4 Gateway: ✅ Force all client traffic through tunnel
IPv4 Local network(s): 192.168.1.0/24, 10.0.0.0/24
Concurrent connections: 254
Compression: ✅ Adaptive LZO Compression
Inter-Client Communication: ❌ Block communication between clients (segurança)
Duplicate Connections: ❌ Disallow multiple connections (uma sessão por user)
```

#### Client Settings

```
Dynamic IP: ✅ Allow connected clients to retain their connections
Topology: Subnet
DNS Servers:
- Server 1: 192.168.1.10 (DC - internal DNS)
- Server 2: 1.1.1.1 (Cloudflare)
DNS Search Domain: fsociety.pt
NTP Servers:
- Server 1: 192.168.1.1 (pfSense)
```

#### Advanced Configuration - Address Pool by Group

```
Custom options:

# RADIUS Framed-IP-Address support
client-config-dir /var/etc/openvpn/server2/ccd

# Push routes
push "route 192.168.1.0 255.255.255.0"
push "route 10.0.0.0 255.255.255.0"

# Keepalive
keepalive 10 60

Verbosity level: 3
```

### Integração RADIUS

**Servidor RADIUS**:
```
System → User Manager → Authentication Servers

Server: RADIUS-DC-FSociety
Type: RADIUS
Hostname or IP: 192.168.1.10
Shared Secret: (configurado no FreeRADIUS)
Services offered: Authentication and Accounting
Auth port: 1812
Acct port: 1813
Protocol: PAP
```

**Fluxo de Autenticação**:

```
1. Cliente conecta com username/password
   ↓
2. pfSense OpenVPN recebe credenciais
   ↓
3. pfSense envia RADIUS Access-Request para DC (192.168.1.10:1812)
   ↓
4. FreeRADIUS no DC valida contra LDAP/AD
   ↓
5. RADIUS retorna:
   - Access-Accept + Framed-IP-Address (IP do pool)
   - Access-Reject (credenciais inválidas)
   ↓
6. pfSense:
   - Atribui IP do pool apropriado ao grupo AD
   - Aplica regras de firewall baseadas no IP/alias
   ↓
7. Cliente recebe IP e rotas
```

### Address Pools por Grupo AD

| Grupo AD | Pool FreeRADIUS | Range IP | Alias pfSense | Nível |
|----------|-----------------|----------|---------------|-------|
| GRP_TI | ti_pool | 10.8.0.10-59 | Alias_VPN_TI | L1 - Admin |
| GRP_Gestores | gestores_pool | 10.8.0.60-109 | Alias_VPN_Gestores | L2 - Gestão |
| GRP_Financeiro | financeiro_pool | 10.8.0.110-159 | Alias_VPN_Financeiro | L3 - Dept |
| GRP_Comercial | comercial_pool | 10.8.0.160-209 | Alias_VPN_Comercial | L3 - Dept |
| GRP_VPN_Users | vpn_users_pool | 10.8.0.210-254 | Alias_VPN_VPN_Users | L4 - Users |

**Configuração no FreeRADIUS** (no DC):
```
# /etc/freeradius/3.0/mods-available/ldap
```
Ver documentação: [Integração RADIUS](07-radius-integracao.md)

### Exportar Configuração Cliente

```
VPN → OpenVPN → Client Export

Server: OpenVPN Server Radius (UDP:1195)
Host Name: vpn.fsociety.pt

Para utilizador AD:
- Username: usuario@fsociety.pt
- Download: Inline Configuration
```

**Exemplo ficheiro .ovpn**:
```
client
dev tun
proto udp
remote vpn.fsociety.pt 1195
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
tls-auth ta.key 1
cipher AES-256-CBC
auth SHA256
auth-user-pass
# Username: usuario@fsociety.pt
# Password: (AD password)
comp-lzo adaptive
verb 3
```

---

## 📊 Monitorização e Status

### Ver Clientes Conectados

```
Status → OpenVPN
```

**Server 1 (Local)**:
```
Server: OpenVPN server Local (UDP:1194)
Status: up

Connected Clients:
| Name | Real Address | Virtual Address | Connected Since | Bytes Sent | Bytes Received |
|------|--------------|-----------------|-----------------|------------|----------------|
| admin-emergency | 203.0.113.50:54321 | 10.9.0.2 | 2024-12-02 10:30 | 5.2 MB | 15.8 MB |
```

**Server 2 (RADIUS)**:
```
Server: OpenVPN server Radius (UDP:1195)
Status: up

Connected Clients:
| Common Name | Real Address | Virtual Address | Group | Bytes Sent | Bytes Received |
|-------------|--------------|-----------------|-------|------------|----------------|
| ryan@fsociety.pt | 203.0.113.100:45678 | 10.8.0.15 | GRP_TI | 25.5 MB | 102.3 MB |
| hugo@fsociety.pt | 198.51.100.25:12345 | 10.8.0.70 | GRP_Gestores | 10.2 MB | 35.7 MB |
```

### Ver Logs

```
Status → System Logs → OpenVPN
```

**Filtrar por**:
- Server (1194 ou 1195)
- Client IP
- Timestamp

**Eventos importantes**:
```
Dec 02 10:30:15 openvpn[12345]: ryan@fsociety.pt/203.0.113.100:45678 MULTI: Learn: 10.8.0.15
Dec 02 10:30:16 openvpn[12345]: ryan@fsociety.pt/203.0.113.100:45678 MULTI: primary virtual IP for ryan@fsociety.pt: 10.8.0.15
```

### CLI Commands

```bash
# Ver processo OpenVPN
ps aux | grep openvpn

# Ver portas
sockstat -l | grep openvpn

# Ver interfaces virtuais
ifconfig | grep ovpns

# Ver estados de conexão
pfctl -ss | grep -E '10.8.0|10.9.0'

# Ver logs em tempo real
clog /var/log/openvpn.log | tail -f
```

---

## 🔒 Segurança

### Certificados e Chaves

#### CA (Certificate Authority)

```
System → Cert Manager → CAs

Name: OpenVPN CA
Key type: RSA
Key length: 2048 bits
Digest Algorithm: SHA256
Lifetime: 3650 days (10 years)

Common Name: openvpn-ca.fsociety.pt
```

#### Server Certificates

```
System → Cert Manager → Certificates

Server 1:
- Descriptive name: OpenVPN Server Cert 1
- Method: Create an internal Certificate
- Certificate authority: OpenVPN CA
- Key type: RSA (2048 bits)
- Lifetime: 3650 days
- Common Name: openvpn-server1.fsociety.pt

Server 2:
- Descriptive name: OpenVPN Server Cert 2
- Common Name: openvpn-server2.fsociety.pt
```

#### Revogar Certificado de Cliente

```
System → Cert Manager → Certificates

1. Encontrar certificado do cliente
2. Clicar em "Revoke Certificate"
3. Adicionar à CRL (Certificate Revocation List)
4. Recarregar OpenVPN

Status → OpenVPN → Restart Server
```

### TLS Authentication

**TLS Auth Key** protege contra:
- DoS attacks
- Port scanning
- SSL/TLS vulnerabilities

```
VPN → OpenVPN → Servers → Edit

TLS Configuration:
- TLS Key: (auto-generated)
- TLS Key Usage Mode: TLS Authentication

O conteúdo da chave TLS é incluído no ficheiro .ovpn exportado
```

### Cipher Suites

**Preferência**:
1. **CHACHA20-POLY1305** - Rápido, seguro, resistente a timing attacks
2. **AES-256-CBC** - Fallback, amplamente suportado

**Digest**: SHA256 (256-bit)

### Hardening Adicional

#### Limitar Taxa de Conexão

```
Firewall → Rules → WAN → Edit (OpenVPN rules)

Advanced Options:
- Max connections: 10 (por source IP)
- Max connection rate: 5/second
- State timeout: 300
```

#### Fail2Ban Integration (Opcional)

```
# No servidor DC com FreeRADIUS
# Configurar Fail2Ban para bloquear IPs após X tentativas falhadas

[freeradius]
enabled = true
port = 1812,1813
filter = freeradius
logpath = /var/log/freeradius/radius.log
maxretry = 5
findtime = 600
bantime = 3600
```

---

## 🐛 Troubleshooting

### Cliente não consegue conectar

**Sintoma**: Connection timeout ou authentication failed

**Diagnóstico**:
```
1. Verificar porta aberta:
   Firewall → Rules → WAN
   (deve existir regra UDP 1194 ou 1195)

2. Verificar serviço ativo:
   Status → OpenVPN
   (Status deve ser "up")

3. Ver logs:
   Status → System Logs → OpenVPN
   (procurar mensagens de erro)

4. Testar conectividade:
   # De fora
   nc -u vpn.fsociety.pt 1195
```

**Soluções**:
- Verificar DNS do hostname
- Verificar firewall cliente
- Verificar certificados válidos
- Verificar credenciais RADIUS

### Autenticação RADIUS falha

**Sintoma**: Authentication failed (Server 2)

**Diagnóstico**:
```
1. Testar RADIUS:
   Diagnostics → Authentication
   Server: RADIUS-DC-FSociety
   Username: usuario@fsociety.pt
   Password: (senha AD)

2. Ver logs RADIUS:
   # No DC
   tail -f /var/log/freeradius/radius.log

3. Verificar comunicação:
   # Do pfSense
   ping 192.168.1.10
   telnet 192.168.1.10 1812
```

**Soluções**:
- Verificar shared secret
- Verificar FreeRADIUS ativo no DC
- Verificar grupos AD do utilizador

### Cliente recebe IP errado

**Sintoma**: Utilizador do GRP_TI recebe IP do pool errado

**Diagnóstico**:
```
1. Verificar grupo AD:
   # No DC
   ldapsearch -x -LLL -b "dc=fsociety,dc=pt" "(sAMAccountName=usuario)" memberOf

2. Ver configuração FreeRADIUS:
   # No DC
   cat /etc/freeradius/3.0/mods-available/ldap
   cat /etc/freeradius/3.0/sites-available/default
```

**Solução**:
- Adicionar utilizador ao grupo correto no AD
- Verificar mapeamento FreeRADIUS → Pool

### Regras de firewall não aplicam

**Sintoma**: Cliente VPN tem mais/menos acesso que deveria

**Diagnóstico**:
```
1. Verificar IP atribuído:
   Status → OpenVPN
   (verificar Virtual Address)

2. Verificar alias pfSense:
   Firewall → Aliases
   (verificar se IP está no alias correto)

3. Ver regras OpenVPN:
   Firewall → Rules → OpenVPN
   (ordem das regras, aliases corretos)

4. Ver estados:
   Diagnostics → States
   (filtrar por IP do cliente)
```

**Solução**:
- Ajustar aliases
- Reordenar regras (mais específico primeiro)
- Verificar hierarquia de níveis

---

## 📈 Performance

### Otimizações

#### 1. Cipher Selection

```
Preferir CHACHA20-POLY1305:
- Mais rápido em CPUs sem AES-NI
- Menos overhead
- Resistente a timing attacks
```

#### 2. Compression

```
Adaptive LZO Compression:
- ✅ Ativado para conexões lentas
- ❌ Pode ser desativado em conexões rápidas (overhead CPU)
```

#### 3. MTU/MSS

```
VPN → OpenVPN → Servers → Advanced

Custom options:
mssfix 1400
fragment 1400

# Previne fragmentação e melhora performance
```

#### 4. Keepalive

```
Custom options:
keepalive 10 60

# Ping a cada 10s, timeout após 60s
# Mantém NAT traversal e deteta conexões mortas
```

### Monitorização Performance

```
Status → OpenVPN

Ver:
- Bytes Sent/Received
- Throughput estimado
- Número de clientes

Services → ntopng
- Filtrar por interface ovpns1/ovpns2
- Ver bandwidth usage
- Top protocols
```

---

## 📊 RADIUS Accounting Daemon

### Visão Geral

Para além da autenticação RADIUS, o OpenVPN Server 2 (RADIUS) está integrado com um **daemon de contabilização RADIUS** que implementa o protocolo RFC 2866 (RADIUS Accounting).

Este daemon regista automaticamente:
- ✅ **Início de sessão** (Acct-Start)
- 🔄 **Atualizações periódicas** (Acct-Interim-Update a cada 30s)
- ❌ **Fim de sessão** (Acct-Stop)
- 📊 **Estatísticas de tráfego** (bytes enviados/recebidos)
- ⏱️ **Duração da sessão**

### Arquitetura

```
Cliente OpenVPN
       ↓
pfSense OpenVPN (Autenticação via RADIUS)
       ↓
Accounting Daemon (Monitoriza /var/log/openvpn-status.log)
       ↓
FreeRADIUS DC (192.168.1.10:1813)
       ↓
Logs de Accounting (/var/log/freeradius/radacct/)
```

### Funcionalidades

| Evento | Ação | Atributos RADIUS |
|--------|------|------------------|
| **Cliente conecta** | Envia Acct-Start | Username, IP, Session-ID |
| **Atualização (30s)** | Envia Acct-Interim-Update | Bytes In/Out, Session Time |
| **Cliente desconecta** | Envia Acct-Stop | Totais finais, Duração |
| **Mudança de IP** | Acct-Stop + Acct-Start | Fecha sessão antiga, inicia nova |

### Benefícios

- 📊 **Auditoria**: Rastreabilidade completa de acessos VPN
- 📈 **Estatísticas**: Consumo de dados por utilizador
- ⏱️ **Billing**: Duração de sessões para faturação
- 🔒 **Compliance**: RGPD, ISO 27001, requisitos regulatórios
- 🚨 **Deteção de Anomalias**: Identificação de padrões suspeitos

### Informação Detalhada

Para documentação completa do RADIUS Accounting Daemon, incluindo:
- Instalação e configuração
- Estrutura do código
- Atributos RADIUS enviados
- Troubleshooting
- Casos de uso

Consultar: **[OpenVPN RADIUS Accounting Daemon](10-accounting-daemon.md)**

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

- [pfSense OpenVPN Documentation](https://docs.netgate.com/pfsense/en/latest/vpn/openvpn/index.html)
- [OpenVPN Community](https://openvpn.net/community-resources/)
- [OpenVPN Hardening](https://community.openvpn.net/openvpn/wiki/Hardening)

---

<div align="center">

**[⬅️ Voltar: NAT e Port Forwarding](05-nat-port-forwarding.md)** | **[Índice](README.md)** | **[Próximo: Integração RADIUS ➡️](07-radius-integracao.md)**

</div>

---

*Última atualização: Dezembro 2024*
