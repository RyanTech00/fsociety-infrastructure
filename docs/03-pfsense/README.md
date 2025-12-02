# 🛡️ pfSense Firewall - FSociety.pt

> **Firewall Perimetral e Gateway da Infraestrutura**  
>  
> Documentação completa do pfSense da infraestrutura FSociety.pt, incluindo configuração de interfaces, aliases, regras de firewall, NAT, OpenVPN e integração RADIUS.

---

## 📋 Informação do Sistema

| Campo | Valor |
|-------|-------|
| **Hostname** | pfSense.fsociety.pt |
| **Versão** | 2.8.1-RELEASE (amd64) |
| **Base** | FreeBSD 15.0-CURRENT |
| **CPU** | Intel i5-7300HQ @ 2.50GHz (2 cores) |
| **RAM** | 1991 MiB |
| **Disco** | 42 GB (ZFS) |
| **Virtualização** | QEMU Guest (Proxmox VE) |

---

## 🏗️ Arquitetura de Rede

```
                    ┌─────────────────────────────────┐
                    │         INTERNET                │
                    │     192.168.31.1 (Gateway)      │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │      pfSense.fsociety.pt        │
                    │       Four-Legged Firewall      │
                    │                                 │
                    │  WAN: 192.168.31.100/24         │
                    └─────┬──────┬──────┬─────────────┘
                          │      │      │
          ┌───────────────┘      │      └───────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      LAN        │    │      DMZ        │    │      VPN        │
│ 192.168.1.0/24  │    │  10.0.0.0/24    │    │  10.8.0.0/24    │
│                 │    │                 │    │  10.9.0.0/24    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ Gateway:        │    │ Gateway:        │    │ OpenVPN:        │
│ 192.168.1.1     │    │ 10.0.0.1        │    │ - UDP 1194      │
│                 │    │                 │    │ - UDP 1195      │
│ • DC (.10)      │    │ • Mail (.20)    │    │                 │
│ • PBS (.30)     │    │ • Web (.30)     │    │ RADIUS Auth:    │
│ • Files (.40)   │    │                 │    │ dc.fsociety.pt  │
│ • Wazuh (.50)   │    │                 │    │ (192.168.1.10)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🔌 Interfaces de Rede

| Interface | Nome | Endereço IP | Função |
|-----------|------|-------------|--------|
| **vtnet0** | WAN | 192.168.31.100/24 | Internet (Gateway: 192.168.31.1) |
| **vtnet1** | LAN | 192.168.1.1/24 | Rede Interna |
| **vtnet2** | DMZ | 10.0.0.1/24 | Servidores Públicos |
| **ovpns1** | OpenVPN Local | 10.9.0.1/24 | VPN Backup (UDP 1194) |
| **ovpns2** | OpenVPN Radius | 10.8.0.1/24 | VPN Principal (UDP 1195) |

---

## 🔧 Serviços e Portas

### Serviços Ativos

| Serviço | Status | Descrição |
|---------|--------|-----------|
| dhcpd | ✅ Running | DHCP Server (LAN) |
| dpinger | ✅ Running | Gateway monitoring |
| ntopng | ✅ Running | Network traffic monitoring |
| ntpd | ✅ Running | NTP time synchronization |
| OpenVPN Server 1 | ✅ Running | VPN Local (Port 1194) |
| OpenVPN Server 2 | ✅ Running | VPN RADIUS (Port 1195) |
| sshd | ✅ Running | SSH remote access |
| syslogd | ✅ Running | System logging |
| unbound | ✅ Running | DNS resolver |

### Portas Abertas (WAN)

| Porta | Protocolo | Destino | Serviço |
|-------|-----------|---------|---------|
| 25 | TCP | 10.0.0.20 | SMTP (Mailcow) |
| 80 | TCP | 10.0.0.30 | HTTP (Webserver) |
| 110 | TCP | 10.0.0.20 | POP3 (Mailcow) |
| 143 | TCP | 10.0.0.20 | IMAP (Mailcow) |
| 443 | TCP | 10.0.0.30 | HTTPS (Webserver) |
| 465 | TCP | 10.0.0.20 | SMTPS (Mailcow) |
| 587 | TCP | 10.0.0.20 | Submission (Mailcow) |
| 993 | TCP | 10.0.0.20 | IMAPS (Mailcow) |
| 995 | TCP | 10.0.0.20 | POP3S (Mailcow) |
| 1194 | UDP | pfSense | OpenVPN Local |
| 1195 | UDP | pfSense | OpenVPN RADIUS |
| 4190 | TCP | 10.0.0.20 | Sieve (Mailcow) |
| 8007 | TCP | 192.168.1.30 | PBS (from 192.168.31.34) |

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Criação da VM e instalação do pfSense |
| 2 | [Interfaces](02-interfaces.md) | Configuração das interfaces de rede |
| 3 | [Aliases](03-aliases.md) | Aliases de hosts, redes e portas |
| 4 | [Regras de Firewall](04-regras-firewall.md) | Regras por zona (WAN, LAN, DMZ, VPN) |
| 5 | [NAT e Port Forwarding](05-nat-port-forwarding.md) | Redirecionamento de portas e NAT |
| 6 | [OpenVPN](06-openvpn.md) | Configuração dos servidores OpenVPN |
| 7 | [Integração RADIUS](07-radius-integracao.md) | RADIUS com Domain Controller |
| 8 | [Packages e Serviços](08-packages-servicos.md) | Packages instalados e configurações |
| 9 | [Manutenção](09-manutencao.md) | Backup, updates e troubleshooting |

---

## 🔐 Modelo de Segurança

### Zonas de Segurança

```
┌─────────────────────────────────────────────────────────────┐
│  ZONA 1: WAN (Internet)                                     │
│  • Entrada controlada por Port Forwarding                  │
│  • Default Deny All                                        │
│  • Apenas serviços públicos autorizados                    │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│  ZONA 2: LAN (192.168.1.0/24)                               │
│  • Acesso total a Internet                                 │
│  • Acesso controlado a DMZ (apenas serviços autorizados)   │
│  • Servidores internos (DC, PBS, Files, Wazuh)            │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│  ZONA 3: DMZ (10.0.0.0/24)                                  │
│  • Servidores públicos (Mail, Web)                         │
│  • Acesso limitado à Internet (DNS, SMTP, HTTP, NTP)      │
│  • Acesso limitado ao DC (LDAP, Kerberos)                 │
│  • Isolamento entre servidores DMZ                         │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│  ZONA 4: VPN (10.8.0.0/24, 10.9.0.0/24)                    │
│  • Autenticação RADIUS + LDAP                              │
│  • Acessos por grupos AD (hierarquia de níveis)           │
│  • Backup VPN com auth local (10.9.0.0/24)                │
└─────────────────────────────────────────────────────────────┘
```

### Hierarquia de Acesso VPN

| Nível | Grupo AD | Pool IP | Acesso |
|-------|----------|---------|--------|
| **L1 - Admin** | GRP_TI | 10.8.0.10-59 | Total (LAN + DMZ + Internet) |
| **L2 - Gestão** | GRP_Gestores | 10.8.0.60-109 | LAN + DMZ + Internet |
| **L3 - Dept** | GRP_Financeiro | 10.8.0.110-159 | DC (SMB/DNS) + Internet |
| **L3 - Dept** | GRP_Comercial | 10.8.0.160-209 | DC (SMB/DNS) + Internet |
| **L4 - Users** | GRP_VPN_Users | 10.8.0.210-254 | Mail + Nextcloud + Internet |
| **L0 - Backup** | Local Auth | 10.9.0.0/24 | Acesso total (emergência) |

---

## 📦 Packages Instalados

| Package | Versão | Descrição |
|---------|--------|-----------|
| Cron | 0.3.8_6 | Agendamento de tarefas |
| FreeRADIUS3 | 0.15.14 | RADIUS server local (backup) |
| HAProxy | 0.63_11 | Load Balancer (stopped) |
| iperf | 3.0.5 | Testes de desempenho de rede |
| ntopng | 6.2.0 | Monitorização de tráfego |
| openvpn-client-export | 1.9.5 | Exportação de configurações VPN |
| Shellcmd | 1.0.5_4 | Scripts de inicialização |

---

## 🔗 Integrações

```
                    ┌─────────────────┐
                    │  pfSense        │
                    │ 192.168.1.1     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│  DC (RADIUS)   │  │  DMZ Services  │  │  LAN Clients   │
│  192.168.1.10  │  │  10.0.0.0/24   │  │ 192.168.1.0/24 │
│                │  │                │  │                │
│ • Auth VPN     │  │ • Mail (NAT)   │  │ • DHCP         │
│ • User Pools   │  │ • Web (NAT)    │  │ • DNS          │
│ • Groups       │  │ • Firewall     │  │ • Gateway      │
└────────────────┘  └────────────────┘  └────────────────┘
```

---

## 📊 Estatísticas de Operação

| Métrica | Valor |
|---------|-------|
| **Regras de Firewall** | 35+ regras ativas |
| **Aliases Configurados** | 25+ (hosts, networks, ports) |
| **Port Forwards** | 12 (serviços públicos) |
| **OpenVPN Servers** | 2 (Local + RADIUS) |
| **VPN Max Clients** | 254 (10.8.0.0/24) |
| **RADIUS Pools** | 5 (por grupo AD) |

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

- [pfSense Official Documentation](https://docs.netgate.com/pfsense/en/latest/)
- [pfSense Book](https://docs.netgate.com/pfsense/en/latest/book/)
- [OpenVPN Documentation](https://openvpn.net/community-resources/)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2024*
