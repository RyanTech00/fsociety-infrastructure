# 🖥️ Domain Controller - FSociety.pt

> **Servidor Central de Identidade e Autenticação**  
>  
> Documentação completa do Domain Controller da infraestrutura FSociety.pt, incluindo Samba AD DC, DNS, DHCP, Kerberos, FreeRADIUS e CrowdSec.

---

## 📋 Informação do Servidor

| Campo | Valor |
|-------|-------|
| **Hostname** | dc.fsociety.pt |
| **Endereço IP** | 192.168.1.10 |
| **Sistema Operativo** | Ubuntu 24.04.3 LTS (Noble Numbat) |
| **Kernel** | 6.8.0-88-generic |
| **Virtualização** | KVM (Proxmox VE) |
| **RAM** | 1.4 GB |
| **Disco** | 24 GB |
| **Zona de Rede** | LAN (192.168.1.0/24) |

---

## 🏗️ Arquitetura de Serviços

```
┌─────────────────────────────────────────────────────────────────┐
│                    dc.fsociety.pt (192.168.1.10)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  SAMBA AD   │  │    DNS      │  │    DHCP     │             │
│  │     DC      │  │ (Integrado) │  │   Server    │             │
│  │             │  │             │  │             │             │
│  │ • LDAP      │  │ • Zonas AD  │  │ • Pool IPs  │             │
│  │ • Kerberos  │  │ • PTR       │  │ • Reservas  │             │
│  │ • GPO       │  │ • SRV       │  │ • Options   │             │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘             │
│         │                │                                      │
│         ▼                ▼                                      │
│  ┌─────────────────────────────────────────────────┐           │
│  │              AUTENTICAÇÃO CENTRALIZADA          │           │
│  ├─────────────────────────────────────────────────┤           │
│  │                                                 │           │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐   │           │
│  │  │ Kerberos  │  │   LDAP    │  │  RADIUS   │   │           │
│  │  │  (KDC)    │  │  (389/636)│  │(1812/1813)│   │           │
│  │  └───────────┘  └───────────┘  └───────────┘   │           │
│  │                                                 │           │
│  └─────────────────────────────────────────────────┘           │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  CrowdSec   │  │   Shares    │  │  Netdata    │             │
│  │    IDS      │  │    SMB      │  │ Monitoring  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação Ubuntu Server](01-instalacao-ubuntu.md) | Setup inicial do sistema operativo |
| 2 | [Samba AD DC](02-samba-ad-dc.md) | Provisão e configuração do Active Directory |
| 3 | [DNS Integrado](03-dns-integrado.md) | Zonas DNS e registos do domínio |
| 4 | [DHCP Server](04-dhcp-server.md) | Servidor DHCP para a rede LAN |
| 5 | [Kerberos](05-kerberos.md) | Autenticação Kerberos e tickets |
| 6 | [FreeRADIUS + LDAP](06-freeradius-ldap.md) | RADIUS integrado com AD para VPN |
| 7 | [CrowdSec](07-crowdsec.md) | Sistema de deteção de intrusões |
| 8 | [Shares e Permissões](08-shares-permissoes.md) | Partilhas SMB e controlo de acesso |
| 9 | [Manutenção](09-manutencao.md) | Backup, monitorização e troubleshooting |

---

## 🔌 Serviços e Portas

| Porta | Protocolo | Serviço | Descrição |
|-------|-----------|---------|-----------|
| 53 | TCP/UDP | DNS | Resolução de nomes (Samba interno) |
| 67 | UDP | DHCP | Atribuição dinâmica de IPs |
| 88 | TCP/UDP | Kerberos | Autenticação de tickets |
| 135 | TCP | RPC | Remote Procedure Call |
| 137-138 | UDP | NetBIOS | Serviço de nomes NetBIOS |
| 139 | TCP | NetBIOS | Sessões NetBIOS |
| 389 | TCP/UDP | LDAP | Directório não cifrado |
| 445 | TCP | SMB | Partilhas de ficheiros |
| 464 | TCP/UDP | Kpasswd | Alteração de passwords Kerberos |
| 636 | TCP | LDAPS | Directório cifrado (TLS) |
| 1812 | UDP | RADIUS Auth | Autenticação RADIUS |
| 1813 | UDP | RADIUS Acct | Accounting RADIUS |
| 3268 | TCP | Global Catalog | Catálogo global LDAP |
| 3269 | TCP | Global Catalog SSL | Catálogo global LDAPS |

---

## 🔗 Integrações

O Domain Controller integra-se com todos os serviços da infraestrutura:

```
                         ┌─────────────────┐
                         │  dc.fsociety.pt │
                         │   192.168.1.10  │
                         └────────┬────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│   Mailcow     │         │   Nextcloud   │         │    pfSense    │
│ (LDAP Auth)   │         │ (LDAP Auth)   │         │ (RADIUS/VPN)  │
│ 10.0.0.40     │         │ 192.168.1.40  │         │ 192.168.1.1   │
└───────────────┘         └───────────────┘         └───────────────┘
```

| Serviço | Tipo de Integração | Porta Utilizada |
|---------|-------------------|-----------------|
| **Mailcow** | LDAP (autenticação email) | 636 (LDAPS) |
| **Nextcloud** | LDAP (utilizadores/grupos) | 636 (LDAPS) |
| **pfSense OpenVPN** | RADIUS → LDAP | 1812 |
| **Estações Windows** | Domain Join | 389, 445, 88 |

---

## 👥 Estrutura Organizacional (AD)

### Organizational Units (OUs)

```
DC=fsociety,DC=pt
├── OU=FSociety
│   ├── OU=TI
│   ├── OU=RH
│   ├── OU=Comercial
│   ├── OU=Financeiro
│   ├── OU=Grupos
│   └── OU=Computadores
├── OU=Service Accounts
├── OU=Domain Controllers
└── CN=Users (built-in)
```

### Grupos de Segurança

| Grupo | Função | Membros |
|-------|--------|---------|
| GRP_TI | Departamento TI | Administradores de sistemas |
| GRP_RH | Recursos Humanos | Equipa de RH |
| GRP_Comercial | Departamento Comercial | Equipa de vendas |
| GRP_Financeiro | Departamento Financeiro | Contabilidade |
| GRP_Gestores | Gestão | Diretores e gestores |
| GRP_VPN_Users | Acesso VPN | Utilizadores com acesso remoto |

---

## 📊 Métricas de Segurança (CrowdSec)

| Métrica | Valor |
|---------|-------|
| **Versão CrowdSec** | v1.7.3 |
| **Bouncer Ativo** | cs-firewall-bouncer v0.0.34 |
| **IPs na Blocklist (CAPI)** | 16.19k |
| **Collections Ativas** | linux, mysql, postfix, smb, sshd |

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

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação Ubuntu ➡️](01-instalacao-ubuntu.md)**

</div>

---

*Última atualização: Dezembro 2025*