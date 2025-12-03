# 📁 Servidor de Ficheiros - FSociety.pt

> **Servidor de Colaboração e Ticketing**  
>  
> Documentação completa do Servidor de Ficheiros da infraestrutura FSociety.pt, incluindo Nextcloud com LDAP, Zammad, PostgreSQL, Redis e CrowdSec.

---

## 📋 Informação do Servidor

| Campo | Valor |
|-------|-------|
| **Hostname** | files.fsociety.pt |
| **Endereço IP** | 192.168.1.40 |
| **Sistema Operativo** | Ubuntu 24.04.3 LTS (Noble Numbat) |
| **Kernel** | 6.8.0-generic |
| **Virtualização** | KVM (Proxmox VE) |
| **CPU** | Intel i5-7300HQ (4 cores) |
| **RAM** | 2 GB |
| **Disco** | 48 GB |
| **Zona de Rede** | LAN (192.168.1.0/24) |

---

## 🏗️ Arquitetura de Serviços

```
┌─────────────────────────────────────────────────────────────────┐
│              files.fsociety.pt (192.168.1.40)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   NEXTCLOUD 32.0.0                       │  │
│  │            (nextcloud.fsociety.pt:443)                   │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Apache 2.4  │  PHP-FPM 8.3  │  Let's Encrypt SSL      │  │
│  │  /var/www/nextcloud  │  Data: /mnt/data                 │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  • 65+ Apps: Calendar, Mail, Talk, Deck, Forms          │  │
│  │  • LDAP: 19 utilizadores sincronizados                  │  │
│  │  • Cache: Redis (socket) + APCu                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    ZAMMAD 6.5.2                          │  │
│  │             (tickets.fsociety.pt:8081)                   │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Puma (9292)  │  WebSocket (6042)  │  Nginx (8081)      │  │
│  │  /opt/zammad                                             │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Systemd Services:                                       │  │
│  │  • zammad.service         • zammad-web.service          │  │
│  │  • zammad-websocket.service  • zammad-worker.service    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │               BASES DE DADOS                             │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  PostgreSQL 16  │  nextcloud  │  zammad_production      │  │
│  │  Redis          │  Cache + Sessions                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CrowdSec v1.7.3  │  cs-firewall-bouncer v0.0.34        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Ubuntu, rede, pacotes base |
| 2 | [Nextcloud - Instalação](02-nextcloud.md) | Apache, PHP-FPM, Nextcloud |
| 3 | [Nextcloud - Configuração](03-nextcloud-config.md) | config.php, trusted_domains, mail |
| 4 | [Nextcloud - LDAP](04-nextcloud-ldap.md) | Integração com Samba AD |
| 5 | [Nextcloud - Apps](05-nextcloud-apps.md) | 65+ apps organizadas por categoria |
| 6 | [Zammad - Instalação](06-zammad.md) | Instalação e systemd services |
| 7 | [Zammad - Nginx](07-zammad-nginx.md) | Nginx local (porta 8081) |
| 8 | [PostgreSQL e Redis](08-postgresql-redis.md) | Bases de dados e cache |
| 9 | [CrowdSec](09-crowdsec.md) | Sistema de deteção de intrusões |
| 10 | [Manutenção](10-manutencao.md) | Backup, occ commands, logs |

---

## 🔌 Serviços e Portas

| Porta | Protocolo | Serviço | Descrição |
|-------|-----------|---------|-----------|
| 80 | TCP | Apache (HTTP) | Redireciona para HTTPS |
| 443 | TCP | Apache (HTTPS) | Nextcloud (Let's Encrypt) |
| 5432 | TCP | PostgreSQL | Base de dados (localhost) |
| 6379 | TCP | Redis | Cache e sessions (socket) |
| 6042 | TCP | Zammad WebSocket | WebSocket para Zammad |
| 8081 | TCP | Nginx (Zammad) | Proxy local para Zammad |
| 9292 | TCP | Puma | Backend Zammad |

---

## 🔗 Integrações

### LDAP (Samba AD)

```
┌─────────────────────────────────────────────────────────────┐
│                    Nextcloud LDAP Config                    │
├─────────────────────────────────────────────────────────────┤
│  Host: 192.168.1.10:389                                     │
│  Base DN: DC=fsociety,DC=pt                                 │
│  Bind DN: CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt     │
│  User Filter: (&(objectClass=user)(objectCategory=person)  │
│               (!(userAccountControl:1.2.840.113556.1.4.803  │
│               :=2)))                                        │
│  Login Filter: samaccountname=%uid                          │
│  Group Filter: objectClass=group                            │
├─────────────────────────────────────────────────────────────┤
│  Utilizadores Sincronizados: 19                            │
│  Grupos Sincronizados: 6                                    │
└─────────────────────────────────────────────────────────────┘
```

### Acesso Externo (via Webserver DMZ)

```
                  ┌─────────────────┐
                  │    INTERNET     │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │   Webserver     │
                  │   10.0.0.30     │
                  │  (Nginx Proxy)  │
                  └────────┬────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Nextcloud     │ │     Zammad      │ │   Mailcow       │
│ 192.168.1.40    │ │ 192.168.1.40    │ │ 10.0.0.20       │
│ Port 443        │ │ Port 8081       │ │ Port 443        │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

| Serviço | URL Pública | Acesso |
|---------|-------------|--------|
| **Nextcloud** | nextcloud.fsociety.pt | Geo-based (completo LAN/VPN, Mail app externa) |
| **Zammad** | tickets.fsociety.pt | Apenas rede interna (LAN + VPN) |

---

## 📊 Nextcloud - Apps Instaladas (65+)

### Produtividade
- **calendar** - Calendário com CalDAV
- **contacts** - Contactos com CardDAV
- **deck** - Quadros Kanban
- **notes** - Notas markdown
- **tasks** - Gestão de tarefas
- **forms** - Criação de formulários
- **polls** - Inquéritos e votações

### Colaboração
- **spreed** (Talk) - Videochamadas e chat
- **mail** - Cliente de email
- **groupfolders** - Pastas partilhadas por grupo

### Ficheiros
- **files_markdown** - Editor markdown
- **files_pdfviewer** - Visualizador PDF
- **photos** - Galeria de fotos
- **bookmarks** - Gestor de marcadores

### Segurança
- **twofactor_totp** - 2FA TOTP
- **twofactor_backupcodes** - Códigos de recuperação
- **suspicious_login** - Deteção de logins suspeitos

### Integração
- **user_ldap** - Integração LDAP/AD
- **richdocuments** - Collabora Online
- **integration_overleaf** - Integração LaTeX

### Gestão
- **appointments** - Marcação de reuniões
- **timemanager** - Gestão de tempo
- **announcementcenter** - Anúncios centralizados

---

## 💾 Armazenamento

| Diretório | Tamanho | Descrição |
|-----------|---------|-----------|
| **/var/www/nextcloud** | ~600 MB | Instalação Nextcloud |
| **/mnt/data** | ~10 GB | Ficheiros dos utilizadores |
| **/opt/zammad** | ~300 MB | Instalação Zammad |
| **/var/lib/postgresql** | ~500 MB | Bases de dados |

---

## 📊 Métricas de Segurança (CrowdSec)

| Métrica | Valor |
|---------|-------|
| **Versão CrowdSec** | v1.7.3 |
| **Bouncer Ativo** | cs-firewall-bouncer v0.0.34 |
| **Scenarios Ativos** | 40+ (web, ssh, http) |
| **Collections** | linux, nginx, apache2, nextcloud |

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

- [Nextcloud Documentation](https://docs.nextcloud.com/)
- [Nextcloud LDAP Integration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_user/user_auth_ldap.html)
- [Zammad Documentation](https://docs.zammad.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/docs/)

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2024*
