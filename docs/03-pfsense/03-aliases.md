# 📛 Aliases

> Documentação completa dos aliases configurados no pfSense para facilitar a gestão de regras de firewall e NAT.

---

## 📋 O que são Aliases?

Aliases são "apelidos" que representam:
- **Hosts**: IPs individuais de servidores
- **Networks**: Redes inteiras (CIDR)
- **Ports**: Portas ou ranges de portas
- **URLs**: Listas externas de IPs (blocklists, etc.)

**Vantagens**:
- 🎯 Facilita leitura das regras
- 🔧 Simplifica manutenção (alterar uma vez, aplica em todas as regras)
- 📝 Documentação automática
- 🚀 Performance (aliases de rede usam tabelas otimizadas)

---

## 🖥️ Aliases de Hosts

```
Firewall → Aliases → IP → Add
```

### Servidores LAN

| Nome | Endereço IP | Descrição |
|------|-------------|-----------|
| **DC_IP** | 192.168.1.10 | Domain Controller (Samba AD) |
| **PBS_IP** | 192.168.1.30 | Proxmox Backup Server |
| **FILESERVER_IP** | 192.168.1.40 | Nextcloud + Zammad |
| **WAZUH_IP** | 192.168.1.50 | Wazuh Manager (SIEM) |

#### Exemplo de Configuração: DC_IP

```
Name: DC_IP
Description: Domain Controller - Samba AD DC
Type: Host(s)
IP or FQDN: 192.168.1.10
```

### Servidores DMZ

| Nome | Endereço IP | Descrição |
|------|-------------|-----------|
| **MAIL_IP** | 10.0.0.20 | Mailcow Server |
| **WEB_IP** | 10.0.0.30 | Webserver (Nginx) |

#### Exemplo de Configuração: MAIL_IP

```
Name: MAIL_IP
Description: Mailcow - Mail Server
Type: Host(s)
IP or FQDN: 10.0.0.20
```

### Servidores Externos

| Nome | Endereço IP | Descrição |
|------|-------------|-----------|
| **PROXMOX_HOST** | 192.168.31.34 | Proxmox VE Host |

### Aliases por Hostname (FQDN)

| Nome | FQDN | Descrição |
|------|------|-----------|
| **HOST_DC** | dc.fsociety.pt | Domain Controller |
| **HOST_MAIL** | mail.fsociety.pt | Mail Server |
| **HOST_WEB** | web.fsociety.pt | Web Server |

#### Exemplo de Configuração: HOST_DC

```
Name: HOST_DC
Description: Domain Controller FQDN
Type: Host(s)
IP or FQDN: dc.fsociety.pt
```

---

## 🌐 Aliases de Networks

```
Firewall → Aliases → IP → Add (Type: Network)
```

### Redes Principais

| Nome | CIDR | Descrição |
|------|------|-----------|
| **LAN_NET** | 192.168.1.0/24 | Rede Interna |
| **DMZ_NET** | 10.0.0.0/24 | Zona Desmilitarizada |
| **VPN_NET** | 10.8.0.0/24 | OpenVPN RADIUS |
| **VPN_BACKUP** | 10.9.0.0/24 | OpenVPN Local |

#### Exemplo de Configuração: LAN_NET

```
Name: LAN_NET
Description: LAN Network - Internal Network
Type: Network(s)
Network: 192.168.1.0/24
```

### Grupos de Servidores

| Nome | IPs/Range | Descrição |
|------|-----------|-----------|
| **DMZ_SERVERS** | 10.0.0.10<br>10.0.0.20<br>10.0.0.30 | Todos os servidores DMZ |
| **LAN_SERVERS** | 192.168.1.10<br>192.168.1.30<br>192.168.1.40<br>192.168.1.50 | Todos os servidores LAN |
| **ALL_SERVERS** | DC_IP<br>PBS_IP<br>FILESERVER_IP<br>WAZUH_IP<br>MAIL_IP<br>WEB_IP | Todos os servidores (LAN + DMZ) |

#### Exemplo de Configuração: DMZ_SERVERS

```
Name: DMZ_SERVERS
Description: All DMZ Servers
Type: Host(s)
Network or FQDN:
  10.0.0.10
  10.0.0.20
  10.0.0.30
```

---

## 🔐 Aliases VPN por Grupo AD

```
Firewall → Aliases → IP → Add (Type: Network)
```

### Pools VPN RADIUS

| Nome | Range IP | Grupo AD | Nível |
|------|----------|----------|-------|
| **Alias_VPN_TI** | 10.8.0.10 - 10.8.0.59 | GRP_TI | L1 - Admin |
| **Alias_VPN_Gestores** | 10.8.0.60 - 10.8.0.109 | GRP_Gestores | L2 - Gestão |
| **Alias_VPN_Financeiro** | 10.8.0.110 - 10.8.0.159 | GRP_Financeiro | L3 - Dept |
| **Alias_VPN_Comercial** | 10.8.0.160 - 10.8.0.209 | GRP_Comercial | L3 - Dept |
| **Alias_VPN_VPN_Users** | 10.8.0.210 - 10.8.0.254 | GRP_VPN_Users | L4 - Users |

#### Exemplo de Configuração: Alias_VPN_TI

```
Name: Alias_VPN_TI
Description: VPN Pool - TI Department (Level 1 - Admin)
Type: Network(s)
Network: 10.8.0.10 - 10.8.0.59
         (ou 10.8.0.10/26 para maior performance)
```

#### Exemplo de Configuração: Alias_VPN_Gestores

```
Name: Alias_VPN_Gestores
Description: VPN Pool - Gestores (Level 2 - Management)
Type: Network(s)
Network: 10.8.0.60 - 10.8.0.109
```

#### Exemplo de Configuração: Alias_VPN_Financeiro

```
Name: Alias_VPN_Financeiro
Description: VPN Pool - Financeiro (Level 3 - Department)
Type: Network(s)
Network: 10.8.0.110 - 10.8.0.159
```

#### Exemplo de Configuração: Alias_VPN_Comercial

```
Name: Alias_VPN_Comercial
Description: VPN Pool - Comercial (Level 3 - Department)
Type: Network(s)
Network: 10.8.0.160 - 10.8.0.209
```

#### Exemplo de Configuração: Alias_VPN_VPN_Users

```
Name: Alias_VPN_VPN_Users
Description: VPN Pool - VPN Users (Level 4 - Basic Users)
Type: Network(s)
Network: 10.8.0.210 - 10.8.0.254
```

### Alias VPN Backup

| Nome | Range IP | Autenticação | Nível |
|------|----------|--------------|-------|
| **Alias_VPN_Backup** | 10.9.0.0/24 | Local Database | L0 - Emergency |

```
Name: Alias_VPN_Backup
Description: VPN Backup Pool - Emergency Access (Local Auth)
Type: Network(s)
Network: 10.9.0.0/24
```

---

## 🔌 Aliases de Portas

```
Firewall → Aliases → Ports → Add
```

### Active Directory & LDAP

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **AD_PORTS** | 88<br>389<br>464<br>636<br>3268<br>3269 | TCP/UDP | Kerberos<br>LDAP<br>Kpasswd<br>LDAPS<br>GC<br>GC-SSL |

#### Configuração: AD_PORTS

```
Name: AD_PORTS
Description: Active Directory Ports (LDAP, Kerberos, GC)
Type: Port(s)
Port:
  88    # Kerberos
  389   # LDAP
  464   # Kpasswd
  636   # LDAPS
  3268  # Global Catalog
  3269  # Global Catalog SSL
```

### SMB & File Sharing

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **SMB_PORTS** | 139<br>445 | TCP | NetBIOS<br>SMB/CIFS |

```
Name: SMB_PORTS
Description: SMB/CIFS Ports for File Sharing
Type: Port(s)
Port:
  139   # NetBIOS Session
  445   # SMB over TCP
```

### RPC (Remote Procedure Call)

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **RPC_PORTS** | 135<br>49152-49154 | TCP | RPC Endpoint<br>Dynamic RPC |

```
Name: RPC_PORTS
Description: RPC Ports for Windows Services
Type: Port(s)
Port:
  135           # RPC Endpoint Mapper
  49152:49154   # Dynamic RPC Range
```

### Email (Público)

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **MAIL_PUBLIC** | 25<br>143<br>587<br>993 | TCP | SMTP<br>IMAP<br>Submission<br>IMAPS |

```
Name: MAIL_PUBLIC
Description: Public Mail Ports (SMTP, IMAP, Submission)
Type: Port(s)
Port:
  25    # SMTP
  143   # IMAP
  587   # Submission
  993   # IMAPS
```

### Mailcow (Completo)

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **MAILCOW** | 25<br>110<br>143<br>465<br>587<br>993<br>995<br>4190<br>80<br>443 | TCP | SMTP<br>POP3<br>IMAP<br>SMTPS<br>Submission<br>IMAPS<br>POP3S<br>Sieve<br>HTTP<br>HTTPS |

```
Name: MAILCOW
Description: Mailcow - All Mail Ports
Type: Port(s)
Port:
  25    # SMTP
  110   # POP3
  143   # IMAP
  465   # SMTPS
  587   # Submission
  993   # IMAPS
  995   # POP3S
  4190  # Sieve
  80    # HTTP (redirect)
  443   # HTTPS
```

### Web Services

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **WEB_PORTS** | 80<br>443 | TCP | HTTP<br>HTTPS |

```
Name: WEB_PORTS
Description: Web Ports (HTTP, HTTPS)
Type: Port(s)
Port:
  80    # HTTP
  443   # HTTPS
```

### Management Ports

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **MGMT_PORTS** | 22<br>443<br>8006<br>8007 | TCP | SSH<br>HTTPS<br>Proxmox VE<br>PBS |

```
Name: MGMT_PORTS
Description: Management Ports (SSH, Proxmox, PBS)
Type: Port(s)
Port:
  22    # SSH
  443   # HTTPS
  8006  # Proxmox VE
  8007  # Proxmox Backup Server
```

### DNS & NTP

| Nome | Portas | Protocolo | Serviço |
|------|--------|-----------|---------|
| **DNS_PORTS** | 53 | TCP/UDP | DNS |
| **NTP_PORT** | 123 | UDP | NTP |

```
Name: DNS_PORTS
Description: DNS Port
Type: Port(s)
Port: 53

Name: NTP_PORT
Description: NTP Port for Time Synchronization
Type: Port(s)
Port: 123
```

---

## 📊 Resumo de Aliases

### Estatísticas

| Categoria | Quantidade | Descrição |
|-----------|------------|-----------|
| **Hosts** | 10 | IPs individuais de servidores |
| **Networks** | 8 | Redes e ranges |
| **VPN Pools** | 6 | Pools por grupo AD + backup |
| **Ports** | 10 | Grupos de portas por serviço |
| **Total** | **34 aliases** | |

### Hierarquia de Aliases

```
Aliases (34)
├── IP (24)
│   ├── Hosts (10)
│   │   ├── LAN (4): DC, PBS, Files, Wazuh
│   │   ├── DMZ (2): Mail, Web
│   │   ├── External (1): Proxmox Host
│   │   └── FQDN (3): HOST_DC, HOST_MAIL, HOST_WEB
│   │
│   ├── Networks (8)
│   │   ├── Principais (4): LAN_NET, DMZ_NET, VPN_NET, VPN_BACKUP
│   │   └── Grupos (4): DMZ_SERVERS, LAN_SERVERS, ALL_SERVERS
│   │
│   └── VPN Pools (6)
│       ├── TI (10.8.0.10-59)
│       ├── Gestores (10.8.0.60-109)
│       ├── Financeiro (10.8.0.110-159)
│       ├── Comercial (10.8.0.160-209)
│       ├── VPN_Users (10.8.0.210-254)
│       └── Backup (10.9.0.0/24)
│
└── Ports (10)
    ├── AD_PORTS (6 portas)
    ├── SMB_PORTS (2 portas)
    ├── RPC_PORTS (4 portas)
    ├── MAIL_PUBLIC (4 portas)
    ├── MAILCOW (10 portas)
    ├── WEB_PORTS (2 portas)
    ├── MGMT_PORTS (4 portas)
    ├── DNS_PORTS (1 porta)
    └── NTP_PORT (1 porta)
```

---

## 🛠️ Gestão de Aliases

### Criar Alias

```
Firewall → Aliases → Add

1. Escolher tipo: IP, Ports, URLs
2. Definir nome (sem espaços, usar underscore)
3. Adicionar descrição clara
4. Inserir valores
5. Save → Apply Changes
```

### Editar Alias

```
Firewall → Aliases → Edit (ícone de lápis)

⚠️ Aviso: Alterar um alias afeta todas as regras que o usam
```

### Eliminar Alias

```
Firewall → Aliases → Delete (ícone de lixo)

⚠️ Aviso: Não é possível eliminar aliases em uso
```

### Ver Regras que Usam um Alias

```
Firewall → Aliases → View (ícone de referências)

Mostra:
- Regras de firewall
- Regras NAT
- Port Forwards
```

---

## 📝 Boas Práticas

### Nomenclatura

✅ **Bom**:
- `DC_IP` - Claro e conciso
- `Alias_VPN_TI` - Hierarquia e função
- `AD_PORTS` - Categoria identificável

❌ **Mau**:
- `server1` - Não descritivo
- `ports` - Muito genérico
- `Alias-VPN-TI` - Usa hífen (usar underscore)

### Documentação

- Sempre preencher o campo **Description**
- Usar convenções consistentes
- Documentar o propósito, não só o conteúdo

### Organização

- Agrupar aliases relacionados
- Usar prefixos para categorias
- Manter aliases VPN separados

### Performance

- Usar **Network** ranges em vez de múltiplos hosts
- Evitar aliases de FQDNs se possível (usar IPs)
- Limitar tamanho de aliases (max 1000 entradas)

---

## 🔍 Troubleshooting

### Alias não aparece nas regras

**Causa**: Tipo de alias errado (ex: port alias em campo de IP)

**Solução**: Verificar tipo do alias e campo da regra

### Mudança de alias não funciona

**Causa**: Cache de firewall rules

**Solução**:
```
Firewall → Rules → Edit regra → Save → Apply Changes
```

### Erro "Alias in use"

**Causa**: Tentar eliminar alias usado em regras

**Solução**:
1. Ver onde é usado: `Aliases → View References`
2. Remover das regras primeiro
3. Depois eliminar o alias

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

- [pfSense Aliases Documentation](https://docs.netgate.com/pfsense/en/latest/firewall/aliases.html)
- [Best Practices for pfSense Aliases](https://docs.netgate.com/pfsense/en/latest/firewall/aliases.html#best-practices)

---

<div align="center">

**[⬅️ Voltar: Interfaces](02-interfaces.md)** | **[Índice](README.md)** | **[Próximo: Regras de Firewall ➡️](04-regras-firewall.md)**

</div>

---

*Última atualização: Dezembro 2025*
