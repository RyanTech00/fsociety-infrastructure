# 🔐 FSociety. pt - Documentação da Infraestrutura

<div align="center">

![FSociety Logo](assets/images/fsociety-logo.png)

**Infraestrutura Empresarial Segura | Four-Legged Firewall Architecture**

*Projeto Universitário ESTG/IPP - Administração de Sistemas II*

---

[🏠 Início](#) •
[📊 Arquitetura](#-arquitetura-de-rede) •
[📚 Documentação](#-documentação-por-componente) •
[👥 Autores](#-informação-académica)

</div>

---

## 📋 Sobre o Projeto

Este projeto implementa uma **infraestrutura de rede empresarial completa** para a empresa fictícia **FSociety.pt**, demonstrando conceitos avançados de segurança e administração de sistemas:

| Característica | Descrição |
|----------------|-----------|
| 🛡️ **Segurança Perimetral** | Firewall stateful com segmentação em 4 zonas |
| 🔐 **Gestão de Identidades** | Active Directory com autenticação LDAP centralizada |
| 🌐 **Serviços Corporativos** | Email, Web, VPN, Colaboração, Tickets |
| ☁️ **Proteção Multi-Camada** | Cloudflare + pfSense + CrowdSec |
| 📊 **Deteção de Ameaças** | 57+ cenários com blocklists (~70k IPs) |

---

## 🗺️ Arquitetura de Rede

<div align="center">

![Arquitetura de Rede FSociety](assets/images/arquitetura-rede-fsociety.png)

*Arquitetura Four-Legged Firewall com proteção Cloudflare*

</div>

### Zonas de Segurança

| Zona | Rede | Nível de Confiança | Servidores |
|------|------|-------------------|------------|
| **WAN** | 188.81.65.191 | ❌ Não confiável | Internet Gateway |
| **LAN** | 192.168.1. 0/24 | ✅ Alta confiança | DC, File Server, PBS |
| **DMZ** | 10.0.0. 0/24 | ⚠️ Média confiança | Mail, Web, Mail Gateway |
| **VPN** | 10.8.0.0/24 | 🔐 Autenticada | Utilizadores remotos |

---

## 🛠️ Stack Tecnológica

### Infraestrutura Core

| Componente | Tecnologia | Versão |
|------------|------------|--------|
| Virtualização | Proxmox VE | 8.x |
| Firewall | pfSense CE | 2.8. 1 |
| Identidade | Samba AD DC | 4.x |
| Autenticação | FreeRADIUS | 3.x |

### Serviços

| Componente | Tecnologia | Localização |
|------------|------------|-------------|
| Email | Mailcow (Postfix + Dovecot + SOGo) | DMZ |
| Web Server | Nginx Reverse Proxy | DMZ |
| Ficheiros | Nextcloud 32. 0.0 | LAN |
| Tickets | Zammad 6.5.2 | LAN |
| Backup | Proxmox Backup Server | LAN |
| VPN | OpenVPN (2 servidores) | pfSense |

### Segurança

| Camada | Tecnologia | Função |
|--------|------------|--------|
| Edge | Cloudflare | WAF, DDoS, CDN |
| Perímetro | pfSense | Firewall, NAT, VPN |
| Host | CrowdSec | IDS/IPS distribuído |
| Email | SPF/DKIM/DMARC | Autenticação |

---

## 📚 Documentação por Componente

### 🛡️ [pfSense Firewall](03-pfsense/README.md)

> Firewall perimetral com 72 regras, 34 aliases, VPN com autenticação RADIUS

| Documento | Descrição |
|-----------|-----------|
| [Instalação](03-pfsense/01-instalacao.md) | Criação da VM e setup inicial |
| [Interfaces](03-pfsense/02-interfaces.md) | WAN, LAN, DMZ, VPN |
| [Aliases](03-pfsense/03-aliases.md) | 34 aliases organizados |
| [Regras Firewall](03-pfsense/04-regras-firewall.md) | 72 regras por zona |
| [NAT](03-pfsense/05-nat-port-forwarding.md) | Port forwards e outbound NAT |
| [OpenVPN](03-pfsense/06-openvpn. md) | 2 servidores VPN |
| [RADIUS](03-pfsense/07-radius-integracao.md) | Integração com DC |
| [Packages](03-pfsense/08-packages-servicos.md) | ntopng, HAProxy, etc. |
| [Manutenção](03-pfsense/09-manutencao.md) | Backup e troubleshooting |
| [Accounting Daemon](03-pfsense/10-accounting-daemon.md) | RADIUS Accounting (RFC 2866) |

---

### 🖥️ [Domain Controller](04-domain-controller/README. md)

> Samba AD DC com DNS, DHCP, Kerberos, FreeRADIUS e CrowdSec

| Documento | Descrição |
|-----------|-----------|
| [Instalação Ubuntu](04-domain-controller/01-instalacao-ubuntu.md) | Setup do sistema base |
| [Samba AD DC](04-domain-controller/02-samba-ad-dc.md) | Provisão do domínio |
| [DNS Integrado](04-domain-controller/03-dns-integrado.md) | Zonas e registos |
| [DHCP Server](04-domain-controller/04-dhcp-server.md) | Pool e reservas |
| [Kerberos](04-domain-controller/05-kerberos. md) | Autenticação de tickets |
| [FreeRADIUS + LDAP](04-domain-controller/06-freeradius-ldap. md) | RADIUS para VPN |
| [CrowdSec](04-domain-controller/07-crowdsec.md) | IDS/IPS |
| [Shares](04-domain-controller/08-shares-permissoes.md) | Partilhas SMB |
| [Manutenção](04-domain-controller/09-manutencao.md) | Backup e monitorização |

---

### 📁 [Servidor de Ficheiros](05-servidor-ficheiros/README.md)

> Nextcloud 32.0.0 + Zammad 6.5.2 com integração LDAP

| Documento | Descrição |
|-----------|-----------|
| [Instalação](05-servidor-ficheiros/01-instalacao.md) | Ubuntu Server 24.04 |
| [Nextcloud](05-servidor-ficheiros/02-nextcloud.md) | Instalação e config |
| [Nextcloud LDAP](05-servidor-ficheiros/04-nextcloud-ldap. md) | Integração AD |
| [Nextcloud Apps](05-servidor-ficheiros/05-nextcloud-apps.md) | 65+ aplicações |
| [Zammad](05-servidor-ficheiros/06-zammad.md) | Sistema de tickets |
| [Base de Dados](05-servidor-ficheiros/08-postgresql-redis.md) | PostgreSQL + Redis |
| [CrowdSec](05-servidor-ficheiros/09-crowdsec.md) | Segurança |

---

### 🌐 [Webserver DMZ](06-webserver/README.md)

> Nginx Reverse Proxy com 6 sites, SSL wildcard e CrowdSec

| Documento | Descrição |
|-----------|-----------|
| [Instalação](06-webserver/01-instalacao.md) | Ubuntu na DMZ |
| [Nginx Config](06-webserver/02-nginx-config.md) | Security headers, rate limiting |
| [Site fsociety.pt](06-webserver/03-site-fsociety.md) | Site institucional |
| [Proxy Nextcloud](06-webserver/04-proxy-nextcloud.md) | Geo-access control |
| [Proxy Zammad](06-webserver/05-proxy-zammad.md) | Acesso restrito |
| [Proxy Mailcow](06-webserver/06-proxy-mailcow. md) | Mail, autoconfig |
| [SSL](06-webserver/07-ssl-letsencrypt.md) | Wildcard Let's Encrypt |
| [DNS Cloudflare](06-webserver/08-dns-cloudflare.md) | Registos DNS |
| [CrowdSec](06-webserver/09-crowdsec.md) | 3 bouncers |

---

## 📊 Métricas do Projeto

| Métrica | Valor |
|---------|-------|
| **Regras de Firewall** | 72 |
| **Aliases pfSense** | 34 |
| **Cenários CrowdSec** | 57+ |
| **IPs Blocklist** | ~70. 000 |
| **Utilizadores AD** | 19 |
| **Apps Nextcloud** | 65+ |
| **Documentos Técnicos** | 40+ |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |
| **Domínio** | fsociety.pt |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../LICENSE). 

---

<div align="center">

<img src="assets/images/fsociety-logo.png" alt="FSociety" width="120">

*"Control is an illusion."*

**FSociety.pt** - Infraestrutura Empresarial Segura

</div>
