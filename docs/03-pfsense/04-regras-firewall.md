# 🛡️ Regras de Firewall

> Documentação completa das regras de firewall configuradas no pfSense, organizadas por zona de segurança (WAN, LAN, DMZ, VPN).

---

## 📹 Demonstração Completa

O vídeo abaixo demonstra a navegação pelas **72 regras** distribuídas pelas interfaces WAN, LAN, DMZ e OpenVPN:

https://github.com/user-attachments/assets/9809a299-b4ac-408f-a518-2019d445b742

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

| # | States | Ação | Proto | Origem | Porta | Destino | Porta | Gateway | Descrição |
|---|--------|------|-------|--------|-------|---------|-------|---------|-----------|
| 1 | 18/19.59 MiB | ✅ Pass | IPv4 TCP | 192.168.31.34 | * | 192.168.1.30 | 8007 | none | WAN: Proxmox VE → PBS |
| | | | **SERVIÇOS PÚBLICOS: EMAIL (PMG + MAIL SERVER)** | | | | | | |
| 2 | 0/0 B | ✅ Pass | IPv4 TCP | * | * | 10.0.0.20 | 25 (SMTP) | none | WAN: SMTP → MAILCOW |
| 3 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.20 | 587 (SUBMISSION) | none | WAN: Submission → Mail |
| 4 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.20 | 465 (SMTP/S) | none | WAN: SMTPS → Mail |
| 5 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.20 | 143 (IMAP) | none | WAN: IMAP → Mail |
| 6 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.20 | 993 (IMAP/S) | none | WAN: IMAPS → Mail |
| | | | **SERVIÇOS PÚBLICOS: WEB** | | | | | | |
| 7 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.30 | 80 (HTTP) | none | WAN: HTTP → Webserver |
| 8 | | ✅ Pass | IPv4 TCP | * | * | 10.0.0.30 | 443 (HTTPS) | none | WAN: HTTPS → Webserver |
| | | | **ACESSO REMOTO (VPN)** | | | | | | |
| 9 | 0/0 B | ✅ Pass | IPv4 UDP | * | * | WAN address | 1194 (OpenVPN) | none | WAN: OpenVPN (BACKUP) |
| 10 | 2/45.29 MiB | ✅ Pass | IPv4 UDP | * | * | WAN address | 1195 | none | WAN: OpenVPN |
| | | | **SEGURANÇA** | | | | | | |
| 11 | | ❌ Block | IPv4 TCP | * | * | * | * | none | WAN: Default Deny All |

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

| # | States | Ação | Proto | Origem | Porta | Destino | Porta | Gateway | Descrição |
|---|--------|------|-------|--------|-------|---------|-------|---------|-----------|
| 1 | 3/1 B | ✅ Pass | * | * | * | LAN Address | 8009, 80, 22 | | Anti-Lockout Rule |
| 2 | 0/0 B | ✅ Pass | IPv4 TCP | 192.168.1.0 /24 | * | DMZ_SERVERS | * | none | |
| | | | **ACESSO INTERNET** | | | | | | |
| 3 | 1/455 KiB | ✅ Pass | IPv4 TCP/UDP | LAN address | * | * | 53 (DNS) | none | LAN → Internet: DNS |
| 4 | | ✅ Pass | IPv4 TCP | LAN address | * | * | 80 (HTTP) | none | LAN → Internet: HTTP |
| 5 | | ✅ Pass | IPv4 TCP | LAN address | * | * | 443 (HTTPS) | none | LAN → Internet: HTTPS |
| 6 | | ✅ Pass | IPv4 UDP | LAN address | * | * | 123 (NTP) | none | LAN → Internet: NTP |
| 7 | | ✅ Pass | IPv4 ICMP | LAN address | * | * | * | none | LAN → Internet: ICMP |
| | | | **SERVIÇOS DC (DOMAIN CONTROLLER - 192.168.1.10)** | | | | | | |
| 8 | 5/0 B | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 1812 | none | RADIUS Auth + Accounting para DC Fsociety |
| 9 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 389 (LDAP) | none | LAN → DC: LDAP |
| 10 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 636 (LDAP/S) | none | LAN → DC: LDAPS |
| 11 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 88 | none | LAN → DC: Kerberos |
| 12 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 445 (MS DS) | none | LAN → DC: MS DS |
| 13 | 0/0 B | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.10 | 49152-65535 | none | LAN → DC: RPC Dinâmico |
| 14 | 0/0 B | ✅ Pass | IPv4 TCP/UDP | LAN address | * | 192.168.1.10 | 53 (DNS) | none | LAN → DC: DNS |
| 15 | 1/1 B | ✅ Pass | IPv4 TCP/UDP | LAN address | * | 192.168.1.10 | 464 | none | LAN → DC: KDC |
| 16 | | ✅ Pass | IPv4 UDP | LAN address | * | 192.168.1.10 | 123 (NTP) | none | LAN → DC: NTP |
| 17 | | ✅ Pass | IPv4 UDP | LAN address | * | 192.168.1.10 | 67 | none | LAN → DC: DHCP |
| 18 | | ✅ Pass | IPv4 UDP | LAN address | * | 192.168.1.10 | 3268 | none | LAN → DC: GC |
| | | | **SERVIÇOS INTERNOS** | | | | | | |
| 19 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.40 | 443 (HTTPS) | none | LAN → Files: Nextcloud |
| 20 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.40 | 8080 | none | LAN → Files: Zammad |
| 21 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.40 | 22 (SSH) | none | LAN → Files: SSH |
| 22 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.30 | 8007 | none | LAN → PBS: UI |
| 23 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.30 | 22 (SSH) | none | LAN → PBS: SSH |
| 24 | | ✅ Pass | IPv4 TCP | LAN address | * | 192.168.1.1 | 443 (HTTPS) | none | LAN → pfSense |
| | | | **ACESSO À DMZ** | | | | | | |
| 25 | | ✅ Pass | IPv4 TCP | 192.168.1.10 | * | 10.0.0.30 | 85 (HTTP) | none | LAN → DMZ: Web Relay |
| 26 | | ✅ Pass | IPv4 TCP | LAN address | * | 10.0.0.30 | 443 (HTTPS) | none | LAN → DMZ: Web HTTPS |
| | | | **NEXTCLOUD - MAIL SERVER (INTEGRAÇÃO)** | | | | | | |
| 27 | | ✅ Pass | IPv4 TCP | 192.168.1.40 | * | 10.0.0.20 | 143 (IMAP) | none | LAN → DMZ: Nextcloud → Mail (IMAPS) |
| 28 | | ✅ Pass | IPv4 TCP | 192.168.1.40 | * | 10.0.0.20 | 993 (IMAP/S) | none | LAN → DMZ: Nextcloud → Mail (IMAPS) |
| 29 | | ✅ Pass | IPv4 TCP | 192.168.1.40 | * | 10.0.0.20 | 587 | none | |
| 30 | | ✅ Pass | IPv4 TCP | 192.168.1.40 | * | 10.0.0.20 | 465 (SMTP/S) | none | |
| | | | **SEGURANÇA** | | | | | | |
| 31 | 1/1 B | ❌ Reject | IPv4 TCP | LAN address | * | 10.0.0.0/24 | * | none | LAN → DMZ: Block rest |

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

| # | States | Ação | Proto | Origem | Porta | Destino | Porta | Gateway | Descrição |
|---|--------|------|-------|--------|-------|---------|-------|---------|-----------|
| | | | **SAÍDA PARA INTERNET** | | | | | | |
| 1 | 0/0.45 KiB | ✅ Pass | IPv4 ICMP | DMZ address | * | * | * | none | DMZ → Internet: ICMP (ping) |
| 2 | 0/0 B | ✅ Pass | IPv4 TCP | 10.0.0.20 | * | * | 2525 | none | DMZ → Internet: MAILCOW SMTP2GO |
| 3 | | ✅ Pass | IPv4 TCP | 10.0.0.20 | * | * | 25 (SMTP) | none | DMZ → Internet: Mail SMTP |
| 4 | 22/3.64 MiB | ✅ Pass | IPv4 TCP/UDP | DMZ address | * | * | 53 (DNS) | none | DMZ → Internet: DNS |
| 5 | | ✅ Pass | IPv4 TCP | DMZ address | * | * | 80 (HTTP) | none | DMZ → Internet: HTTP |
| 6 | 64/73.67 KiB | ✅ Pass | IPv4 TCP | DMZ address | * | * | 443 (HTTPS) | none | DMZ → Internet: HTTPS |
| 7 | | ✅ Pass | IPv4 UDP | DMZ address | * | * | 123 (NTP) | none | DMZ → Internet: NTP |
| | | | **COMUNICAÇÃO COM LAN (DC + FILES)** | | | | | | |
| 8 | 8/2.11 KiB | ✅ Pass | IPv4 TCP/UDP | DMZ address | * | 192.168.1.50 | * | none | DMZ → WAZUH MANAGER: TCP/UDP |
| 9 | 5/427 KiB | ✅ Pass | IPv4 TCP/UDP | DMZ address | * | 192.168.1.10 | 389 (LDAP) | none | DMZ → DC: Mail LDAP |
| 10 | | ✅ Pass | IPv4 TCP | DMZ address | * | 192.168.1.10 | 636 (LDAP/S) | none | DMZ → DC: Mail LDAPS |
| 11 | 0/158 KiB | ✅ Pass | IPv4 TCP | DMZ address | * | 192.168.1.10 | 88 | none | DMZ → DC: Kerberos |
| 12 | | ✅ Pass | IPv4 TCP | DMZ address | * | 192.168.1.10 | 445 (MS DS) | none | DMZ → DC: MS DS |
| 13 | 0/0 B | ✅ Pass | IPv4 TCP | DMZ address | * | 192.168.1.10 | 49152-65535 | none | DMZ → DC: RPC Dinâmico |
| 14 | 0/0 B | ✅ Pass | IPv4 TCP/UDP | DMZ address | * | 192.168.1.10 | 53 (DNS) | none | DMZ → DC: DNS |
| 15 | 0/0 B | ✅ Pass | IPv4 TCP/UDP | DMZ address | * | 192.168.1.10 | 464 | none | DMZ → DC: KDC |
| 16 | | ✅ Pass | IPv4 UDP | DMZ address | * | 192.168.1.10 | 123 (NTP) | none | DMZ → DC: NTP |
| 17 | | ✅ Pass | IPv4 ICMP | DMZ address | * | 192.168.1.10 | * | none | DMZ → DC: PING |
| 18 | 0/0 B | ✅ Pass | IPv4 TCP | 10.0.0.20 | * | 192.168.1.40 | 443 (HTTPS) | none | DMZ → LAN: Mail → Nextcloud (return traffic) |
| 19 | | ✅ Pass | IPv4 TCP | 10.0.0.20 | * | 192.168.1.40 | 8080 | none | DMZ → Files: Nextcloud |
| 20 | | ✅ Pass | IPv4 TCP | 10.0.0.30 | * | 192.168.1.40 | 7867 | none | DMZ → Files: Notify Push |
| | | | **COMUNICAÇÃO INTERNA DMZ** | | | | | | |
| 21 | 0/0 B | ✅ Pass | IPv4 TCP | 10.0.0.30 | * | 10.0.0.20 | 993 (IMAP/S) | none | DMZ: Webserver → Mail (IMAPS for Z-Push) |
| 22 | | ✅ Pass | IPv4 TCP | 10.0.0.30 | * | 10.0.0.20 | 587 | none | DMZ: Webserver → Mail (SMTP SUBMISSION) |
| 23 | 0/0 B | ✅ Pass | IPv4 TCP | 10.0.0.30 | * | 10.0.0.20 | 327 | none | |
| 24 | | ✅ Pass | IPv4 TCP | 10.0.0.30 | * | 10.0.0.20 | 143 (IMAP) | none | DMZ: Webserver → Mail (IMAP for Z-Push) |
| | | | **SEGURANÇA** | | | | | | |
| 25 | | ❌ Reject | IPv4 TCP | DMZ address | * | DMZ address | * | none | DMZ: Block Inter-server |
| 26 | 0/0 B | ❌ Reject | IPv4 TCP | DMZ address | * | 192.168.1.0/24 | * | none | DMZ → LAN: Block |

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
L0 - VPN Backup (10.9.0.0/24)     → Acesso Total (emergência)
L1 - Admin (TI)                   → Acesso Total
L2 - Gestão (Gestores)            → LAN + DMZ + Internet
L3 - Departamentos                → Serviços específicos + Internet
L4 - Users                        → Mail + Nextcloud + Internet
L5 - DEFAULT DENY                 → Block All
```

### Lista de Regras

| # | States | Ação | Proto | Origem | Porta | Destino | Porta | Gateway | Descrição |
|---|--------|------|-------|--------|-------|---------|-------|---------|-----------|
| | | | **VPN BACKUP** | | | | | | |
| 1 | 10/34 MiB | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | 10.0.0.30 | 443 (HTTPS) | none | |
| 2 | 0/0 B | ✅ Pass | IPv4 ICMP | 10.9.0.0/24 | * | * | * | none | [VPN-Backup] ICMP |
| 3 | | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | 192.168.1.1 | 22 (SSH) | none | [VPN-Backup] SSH → pfSense |
| 4 | | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | 192.168.1.1 | 443 | none | [VPN-Backup] WebUI → pfSense (443) |
| 5 | 0/0 B | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | 192.168.1.30 | 8007 | none | [VPN-Backup] PBS |
| 6 | | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | * | 53 (DNS) | none | [VPN-Backup] DNS |
| 7 | 0/0 B | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | * | 80 (HTTP) | none | [VPN-Backup] Internet (HTTP) |
| 8 | | ✅ Pass | IPv4 TCP | 10.9.0.0/24 | * | * | 443 (HTTPS) | none | [VPN-Backup] Internet (HTTPS) |
| 9 | | ❌ Block | IPv4 TCP | 10.9.0.0/24 | * | 192.168.1.0/24 | * | none | [VPN-Backup] BLOCK → LAN |
| 10 | | ❌ Block | IPv4 TCP | 10.9.0.0/24 | * | * | * | none | [VPN-Backup] BLOCK → DMZ |
| | | | **NÍVEL 1: ADMINISTRAÇÃO (ACESSO TOTAL)** | | | | | | |
| 11 | | ✅ Pass | IPv4 TCP | Alias_VPN_TI | * | * | * | none | [L1-Admin] TI → Acesso Total |
| | | | **NÍVEL 2: GESTÃO** | | | | | | |
| 12 | | ✅ Pass | IPv4 TCP | Alias_VPN_Gestores | * | LAN_NET | * | none | [L2-Gestão] Gestores → LAN |
| 13 | | ✅ Pass | IPv4 TCP | Alias_VPN_Gestores | * | DMZ_NET | * | none | [L2-Gestão] Gestores → DMZ |
| 14 | | ✅ Pass | IPv4 TCP | Alias_VPN_Gestores | * | * | * | none | [L2-Gestão] Gestores → Internet |
| | | | **NÍVEL 3: DEPARTAMENTOS (FINANCEIRO + COMERCIAL)** | | | | | | |
| 15 | | ✅ Pass | IPv4 TCP | Alias_VPN_Financeiro | * | * | 445 (MS DS) | none | [L3-Dept] Financeiro → File Server (SMB) |
| 16 | 0/0 B | ✅ Pass | IPv4 TCP/UDP | Alias_VPN_Financeiro | * | HOST_DC | 53 (DNS) | none | [L3-Dept] Financeiro → DNS |
| 17 | | ✅ Pass | IPv4 TCP | Alias_VPN_Financeiro | * | * | 80 (HTTP) | none | [L3-Dept] Financeiro → Internet (HTTP) |
| 18 | | ✅ Pass | IPv4 TCP | Alias_VPN_Financeiro | * | * | 443 (HTTPS) | none | [L3-Dept] Financeiro → Internet (HTTPS) |
| 19 | | ✅ Pass | IPv4 UDP | Alias_VPN_Financeiro | * | * | 123 (NTP) | none | [L3-Dept] Financeiro → NTP |
| 20 | | ✅ Pass | IPv4 TCP | Alias_VPN_Comercial | * | * | 445 (MS DS) | none | [L3-Dept] Comercial → File Server (SMB) |
| 21 | 0/0 B | ✅ Pass | IPv4 TCP/UDP | Alias_VPN_Comercial | * | HOST_DC | 53 (DNS) | none | [L3-Dept] Comercial → DNS |
| 22 | | ✅ Pass | IPv4 TCP | Alias_VPN_Comercial | * | * | 80 (HTTP) | none | [L3-Dept] Comercial → Internet (HTTP) |
| 23 | | ✅ Pass | IPv4 TCP | Alias_VPN_Comercial | * | * | 443 (HTTPS) | none | [L3-Dept] Comercial → Internet (HTTPS) |
| 24 | | ✅ Pass | IPv4 UDP | Alias_VPN_Comercial | * | * | 123 (NTP) | none | [L3-Dept] Comercial → NTP |
| | | | **NÍVEL 4: UTILIZADORES GERAIS (VPN_USERS)** | | | | | | |
| 25 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | HOST_MAIL | 143 (IMAP) | none | [L4-Users] VPN_Users → Mail (IMAP) |
| 26 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | HOST_MAIL | 993 (IMAP/S) | none | [L4-Users] VPN_Users → Mail (Submission) |
| 27 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | HOST_MAIL | 587 | none | [L4-Users] VPN_Users → Mail (Submission) |
| 28 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | 10.0.0.30 | 80 (HTTP) | none | [L4-Users] VPN_Users → Webserver (HTTP) |
| 29 | | ✅ Pass | IPv4 TCP/UDP | ALL_GROUPS | * | HOST_DC | 53 (DNS) | none | [L4-Users] VPN_Users → DNS |
| 30 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | * | 80 (HTTP) | none | [L4-Users] VPN_Users → Internet (HTTP) |
| 31 | | ✅ Pass | IPv4 TCP | ALL_GROUPS | * | * | 443 (HTTPS) | none | [L4-Users] VPN_Users → Internet (HTTPS) |
| 32 | | ✅ Pass | IPv4 UDP | ALL_GROUPS | * | * | 123 (NTP) | none | [L4-Users] VPN_Users → NTP |
| 33 | | ✅ Pass | IPv4 ICMP | ALL_GROUPS | * | * | * | none | [L4-Users] VPN_Users → ICMP |
| | | | **NÍVEL 5: SEGURANÇA (DEFAULT DENY)** | | | | | | |
| 34 | 1/1 B | ❌ Block | IPv4 TCP | * | * | * | * | none | [L5-Security] DEFAULT DENY - Block All |

---

## 📊 Resumo de Regras

### Estatísticas por Interface

| Interface | Regras Pass | Regras Block/Reject | Total |
|-----------|-------------|---------------------|-------|
| **WAN** | 10 | 1 | 11 |
| **LAN** | 30 | 1 | 31 |
| **DMZ** | 24 | 2 | 26 |
| **OpenVPN** | 32 | 2 | 34 |
| **Total** | **96 regras** | **6 regras** | **102 regras** |

### Portas Mais Utilizadas

| Porta(s) | Protocolo | Serviço | Frequência |
|----------|-----------|---------|------------|
| 80, 443 | TCP | HTTP/HTTPS | 20+ regras |
| 53 | TCP/UDP | DNS | 10+ regras |
| 389, 636 | TCP/UDP | LDAP/LDAPS | 6 regras |
| 25, 587 | TCP | SMTP | 5 regras |
| 88 | TCP/UDP | Kerberos | 4 regras |
| 445 | TCP | SMB/MS DS | 4 regras |

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

- [pfSense Firewall Rules](https://docs.netgate.com/pfsense/en/latest/firewall/index.html)
- [Understanding Rule Processing](https://docs.netgate.com/pfsense/en/latest/firewall/rule-methodology.html)
- [Troubleshooting Firewall Rules](https://docs.netgate.com/pfsense/en/latest/troubleshooting/firewall.html)

---

<div align="center">

**[⬅️ Voltar: Aliases](03-aliases.md)** | **[Índice](README.md)** | **[Próximo: NAT e Port Forwarding ➡️](05-nat-port-forwarding.md)**

</div>

---

*Última atualização: Dezembro 2025*
