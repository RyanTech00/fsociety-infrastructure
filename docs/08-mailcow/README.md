# 📧 Mailcow - FSociety.pt

> **Servidor de Email Completo com Anti-spam, Antivírus e Webmail**  
>  
> Documentação completa do Mailcow Dockerized, solução de email empresarial que substitui completamente o Proxmox Mail Gateway na infraestrutura FSociety.pt.

---

## 📋 Informação do Servidor

| Campo | Valor |
|-------|-------|
| **Hostname** | mail.fsociety.pt |
| **Endereço IP** | 10.0.0.20 |
| **VM ID** | 108 |
| **Sistema Operativo** | Ubuntu Server (via Proxmox VE) |
| **RAM** | 6 GB |
| **vCPU** | 2 |
| **Disco** | 24 GB (52% usado) |
| **Zona de Rede** | DMZ (10.0.0.0/24) |
| **Path Instalação** | /opt/mailcow-dockerized |

---

## 🏗️ Arquitetura Mailcow

O Mailcow é uma solução completa de email baseada em Docker, com 18 containers ativos que fornecem todos os serviços necessários:

```
┌─────────────────────────────────────────────────────────────────┐
│              mail.fsociety.pt (10.0.0.20 - DMZ)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    NGINX (80/443)                       │   │
│  │              SSL/TLS + Reverse Proxy                    │   │
│  └────────────────────┬────────────────────────────────────┘   │
│                       │                                         │
│         ┌─────────────┼─────────────┐                          │
│         │             │             │                          │
│         ▼             ▼             ▼                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │  POSTFIX │  │  DOVECOT │  │   SOGo   │                     │
│  │   SMTP   │  │IMAP/POP3 │  │ Webmail  │                     │
│  │25,465,587│  │143,993   │  │          │                     │
│  └────┬─────┘  └────┬─────┘  └──────────┘                     │
│       │             │                                          │
│       ▼             ▼                                          │
│  ┌──────────────────────────┐   ┌──────────────┐              │
│  │       RSPAMD             │   │   CLAMD      │              │
│  │   Anti-spam Filter       │   │  Antivírus   │              │
│  │   (Bayesian, DKIM)       │   │   ClamAV     │              │
│  └──────────────────────────┘   └──────────────┘              │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ MariaDB  │  │  Redis   │  │ Memcached│  │ Unbound  │      │
│  │ Database │  │  Cache   │  │  Cache   │  │   DNS    │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  ACME    │  │ Watchdog │  │Netfilter │  │  Olefy   │      │
│  │Let'sEncr.│  │ Monitor  │  │ Fail2ban │  │  Office  │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Por que Mailcow em vez de Proxmox Mail Gateway?

O Mailcow foi escolhido para substituir completamente o Proxmox Mail Gateway (PMG) pelos seguintes motivos:

| Característica | Mailcow | PMG |
|----------------|---------|-----|
| **Solução Completa** | ✅ MTA + MDA + Webmail + Anti-spam | ❌ Apenas gateway/filtro |
| **Webmail Integrado** | ✅ SOGo (calendário, contactos) | ❌ Não inclui |
| **IMAP/POP3** | ✅ Dovecot integrado | ❌ Requer servidor separado |
| **Gestão de Mailboxes** | ✅ Interface web completa | ❌ Requer servidor backend |
| **Docker-based** | ✅ Fácil deployment e updates | ❌ VM dedicada |
| **ActiveSync** | ✅ Para dispositivos móveis | ❌ Não suportado |
| **Auto-configuração** | ✅ Autodiscover/Autoconfig | ❌ Configuração manual |

**Conclusão:** O Mailcow é uma solução "all-in-one" que elimina a necessidade de múltiplos servidores (gateway + MTA + MDA + webmail), simplificando a arquitetura e manutenção.

---

## 📦 Containers Docker (18 ativos)

| Container | Imagem | Função | Portas |
|-----------|--------|--------|--------|
| **postfix-mailcow** | ghcr.io/mailcow/postfix:1.81 | SMTP Server | 25, 465, 587 |
| **dovecot-mailcow** | ghcr.io/mailcow/dovecot:2.35 | IMAP/POP3 Server | 110, 143, 993, 995, 4190 |
| **rspamd-mailcow** | ghcr.io/mailcow/rspamd:2.4 | Anti-spam Engine | - |
| **clamd-mailcow** | ghcr.io/mailcow/clamd:1.71 | Antivírus ClamAV | - |
| **sogo-mailcow** | ghcr.io/mailcow/sogo:1.136 | Webmail SOGo | - |
| **nginx-mailcow** | ghcr.io/mailcow/nginx:1.05 | Reverse Proxy | 80, 443 |
| **mysql-mailcow** | mariadb:10.11 | Base de Dados | 13306 (local) |
| **redis-mailcow** | redis:7.4.6-alpine | Cache/Sessions | 7654 (local) |
| **php-fpm-mailcow** | ghcr.io/mailcow/phpfpm:1.94 | PHP Backend | 9000 |
| **acme-mailcow** | ghcr.io/mailcow/acme:1.94 | Let's Encrypt SSL | - |
| **unbound-mailcow** | ghcr.io/mailcow/unbound:1.24 | DNS Resolver | - |
| **netfilter-mailcow** | ghcr.io/mailcow/netfilter:1.63 | Fail2ban/IPS | - |
| **watchdog-mailcow** | ghcr.io/mailcow/watchdog:2.09 | Health Monitor | - |
| **dockerapi-mailcow** | ghcr.io/mailcow/dockerapi:2.11 | Docker API Proxy | - |
| **ofelia-mailcow** | mcuadros/ofelia:latest | Cron Scheduler | - |
| **olefy-mailcow** | ghcr.io/mailcow/olefy:1.15 | Office File Scanner | - |
| **memcached-mailcow** | memcached:alpine | Memory Cache | - |
| **postfix-tlspol-mailcow** | ghcr.io/mailcow/postfix-tlspol:1.0 | TLS Policy Server | - |

---

## 📊 Domínio e Contas

### Domínio
- **Domínio Principal:** fsociety.pt
- **Total de Mailboxes:** 20 contas ativas

### Lista de Utilizadores

| Email | Função | Notas |
|-------|--------|-------|
| hugo.correia@fsociety.pt | Equipa TI | Administrador |
| ryan.barbosa@fsociety.pt | Equipa TI | Administrador |
| igor.araujo@fsociety.pt | Equipa TI | Administrador |
| tickets@fsociety.pt | Sistema | Integração Zammad |
| ana.rodrigues@fsociety.pt | Utilizador | - |
| bruno.ferreira@fsociety.pt | Utilizador | - |
| carlos.mendes@fsociety.pt | Utilizador | - |
| claudia.sousa@fsociety.pt | Utilizador | - |
| daniel.ribeiro@fsociety.pt | Utilizador | - |
| ines.gomes@fsociety.pt | Utilizador | - |
| joao.silva@fsociety.pt | Utilizador | - |
| luis.martins@fsociety.pt | Utilizador | - |
| maria.santos@fsociety.pt | Utilizador | - |
| miguel.carvalho@fsociety.pt | Utilizador | - |
| patricia.lima@fsociety.pt | Utilizador | - |
| pedro.costa@fsociety.pt | Utilizador | - |
| ricardo.oliveira@fsociety.pt | Utilizador | - |
| sara.pinto@fsociety.pt | Utilizador | - |
| sofia.almeida@fsociety.pt | Utilizador | - |
| teresa.pereira@fsociety.pt | Utilizador | - |

---

## 🔒 Segurança Implementada

| Camada | Tecnologia | Estado |
|--------|------------|--------|
| **SSL/TLS** | Let's Encrypt (auto-renovação) | ✅ Ativo |
| **Anti-spam** | Rspamd 3.13.2 | ✅ Ativo |
| **Antivírus** | ClamAV | ✅ Ativo |
| **IPS/Fail2ban** | Netfilter | ✅ Ativo |
| **SPF** | Sender Policy Framework | ✅ Configurado |
| **DKIM** | DomainKeys Identified Mail | ✅ Configurado |
| **DMARC** | Domain-based Auth/Report | ✅ Configurado |
| **Greylisting** | Rspamd Greylisting | ✅ Ativo |
| **TLS Policy** | Postfix TLS Policy | ✅ Ativo |

---

## 📈 Estatísticas Rspamd (Anti-spam)

| Métrica | Valor |
|---------|-------|
| **Versão** | 3.13.2 |
| **Emails Processados** | 19 |
| **Sem Ação** | 12 (63%) |
| **Greylisted** | 7 (37%) |
| **Rejeitados** | 0 |
| **Bayesian Aprendizagem** | 2 HAM, 0 SPAM |

---

## 💚 Health Status (Watchdog)

Todos os serviços monitorizados pelo Watchdog estão operacionais a 100%:

| Serviço | Status |
|---------|--------|
| Postfix | 🟢 100% |
| Dovecot | 🟢 100% |
| Rspamd | 🟢 100% |
| SOGo | 🟢 100% |
| MySQL/MariaDB | 🟢 100% |
| Redis | 🟢 100% |
| Nginx | 🟢 100% |
| PHP-FPM | 🟢 100% |
| Unbound | 🟢 100% |
| ClamAV | 🟢 100% |
| ACME | 🟢 100% |

---

## 🔗 Integrações

### Zammad (Sistema de Tickets)

```
┌─────────────────┐      IMAP/SMTP      ┌─────────────────┐
│     Zammad      │ ←─────────────────→ │     Mailcow     │
│ 192.168.1.40    │                     │   10.0.0.20     │
│                 │  tickets@fsociety.pt│                 │
└─────────────────┘                     └─────────────────┘
```

- **Conta:** tickets@fsociety.pt
- **IMAP:** mail.fsociety.pt:993 (SSL)
- **SMTP:** mail.fsociety.pt:587 (STARTTLS)

### DNS Cloudflare

Todos os registos DNS (MX, A, SPF, DKIM, DMARC) estão configurados no Cloudflare para o domínio fsociety.pt.

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Requisitos, Docker, instalação mailcow-dockerized |
| 2 | [Configuração](02-configuracao.md) | mailcow.conf, hostname, timezone, SSL/TLS |
| 3 | [Domínios e Mailboxes](03-dominios-mailboxes.md) | Adicionar domínio, criar contas, aliases, quotas |
| 4 | [Rspamd](04-rspamd.md) | Dashboard, configuração anti-spam, Bayesian |
| 5 | [Antivírus](05-antivirus.md) | ClamAV, atualizações, monitorização |
| 6 | [Webmail](06-webmail.md) | SOGo, ActiveSync, calendário, clientes |
| 7 | [Registos DNS](07-dns-records.md) | MX, A, SPF, DKIM, DMARC, PTR |
| 8 | [Backup](08-backup.md) | Backup de dados, MySQL, scripts, restore |
| 9 | [Integração Zammad](09-integracao-zammad.md) | Configuração IMAP/SMTP no Zammad |
| 10 | [Manutenção](10-manutencao.md) | Updates, logs, troubleshooting |

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

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2025*
