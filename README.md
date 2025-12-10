<div align="center">

<div align="center">
  
![FSociety Infrastructure](docs/assets/images/fsociety-logo.png)

</div>

# 🔐 FSociety.pt

### Infraestrutura Empresarial Segura | Four-Legged Firewall Architecture
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.17840636.svg)](https://doi.org/10.5281/zenodo.17840635)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://ryantech00.github.io/fsociety-infrastructure/)
[![pfSense](https://img.shields.io/badge/Firewall-pfSense-orange)](https://www.pfsense.org/)
[![Proxmox](https://img.shields.io/badge/Virtualization-Proxmox%20VE-E57000)](https://www.proxmox.com/)
[![CrowdSec](https://img.shields.io/badge/IDS-CrowdSec-blueviolet)](https://www.crowdsec.net/)
[![Cloudflare](https://img.shields.io/badge/WAF-Cloudflare-F38020)](https://www.cloudflare.com/)

*Projeto universitário de implementação de infraestrutura de rede empresarial com defesa em profundidade*

**ESTG - Instituto Politécnico do Porto | 2025/2026**

---

[📖 Documentação](https://ryantech00.github.io/fsociety-infrastructure/) •
[🔧 Wiki](https://github.com/RyanTech00/fsociety-infrastructure/wiki) •
[📊 Arquitetura](#-arquitetura)

</div>

---

## 📋 Sobre o Projeto

Este projeto implementa uma **infraestrutura de rede empresarial completa** para a empresa fictícia **FSociety.pt**, demonstrando conceitos avançados de segurança e administração de sistemas:

- 🛡️ **Segurança Perimetral** - Firewall stateful com segmentação em 4 zonas (WAN/LAN/DMZ/VPN)
- 🔐 **Gestão de Identidades** - Active Directory com autenticação LDAP centralizada
- 🌐 **Serviços Corporativos** - Email, Web, VPN, Colaboração de Ficheiros
- ☁️ **Proteção Multi-Camada** - Cloudflare (Edge) + pfSense (Perímetro) + CrowdSec (Host)
- 📊 **Deteção de Ameaças** - 57+ cenários de deteção com blocklists comunitárias (~70k IPs)
- 📈 **Monitorização Centralizada** - Netdata Cloud com AI Insights para 6 servidores

---

## 🏗️ Arquitetura

### Princípios de Design

A implementação seguiu **cinco princípios fundamentais**:

1. **Segmentação Rigorosa** - Isolamento completo entre zonas de confiança
2. **Defense in Depth** - Múltiplas camadas de controlo de segurança
3. **Least Privilege** - Default deny com permissões explícitas mínimas
4. **Visibilidade Contínua** - Logging centralizado e monitorização em tempo real
5. **Simplicidade Operacional** - Gestão via interfaces web intuitivas

### Diagrama de Rede

<div align="center">

![FSociety Network Architecture](docs/assets/images/arquitetura-rede-fsociety.png)

*Arquitetura Four-Legged Firewall com segmentação WAN/LAN/DMZ/VPN e proteção Cloudflare*

</div>

### Plano de Endereçamento

#### Firewall (pfSense)
- **WAN:** 192.168.31.100/24 (Gateway: 192.168.31.1)
- **LAN:** 192.168.1.1/24
- **DMZ:** 10.0.0.1/24
- **VPN1 (RADIUS):** 10.8.0.1/24
- **VPN2 (Local):** 10.9.0.1/24

#### LAN (192.168.1.0/24)
| Servidor | IP | Serviços |
|----------|-------|----------|
| dc.fsociety.pt | 192.168.1.10 | AD, DNS, DHCP, RADIUS |
| pbs.fsociety.pt | 192.168.1.30 | Proxmox Backup Server |
| files.fsociety.pt | 192.168.1.40 | Nextcloud, Zammad |
| Clientes DHCP | 192.168.1.100-200 | Estações de trabalho |

#### DMZ (10.0.0.0/24)
| Servidor | IP | Serviços |
|----------|-------|----------|
| mail.fsociety.pt | 10.0.0.20 | Mailcow (Postfix, Dovecot, Rspamd, SOGo) |
| web.fsociety.pt | 10.0.0.30 | Nginx Reverse Proxy |

#### VPN Pools (Hierárquicos por Grupo AD)
| Grupo | Range | Acesso |
|-------|-------|--------|
| TI | 10.8.0.10-59 | Acesso total (LAN + DMZ + Internet) |
| Gestores | 10.8.0.60-109 | LAN + DMZ + Internet |
| Financeiro | 10.8.0.110-159 | DC + Internet |
| Comercial | 10.8.0.160-209 | DC + Internet |
| VPN_Users | 10.8.0.210-254 | Mail + Web + Internet |

### Camadas de Segurança (Defense in Depth)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CAMADA 1: EDGE (Cloudflare)                                            │
│  ├── WAF com OWASP Managed Rules + Regras Personalizadas                │
│  ├── Mitigação DDoS (L3/L4/L7)                                          │
│  ├── CDN com cache em 330+ datacenters                                  │
│  ├── SSL/TLS Full (Strict) com TLS 1.3                                  │
│  └── Proteção apenas para HTTP/HTTPS (Web)                              │
├─────────────────────────────────────────────────────────────────────────┤
│  CAMADA 2: PERÍMETRO (pfSense)                                          │
│  ├── Stateful Firewall com Default Deny                                 │
│  ├── Segmentação em 4 zonas isoladas (WAN/LAN/DMZ/VPN)                  │
│  ├── NAT/Port Forwarding controlado                                     │
│  ├── OpenVPN RADIUS (integrado com AD)                                  │
│  ├── OpenVPN Local (autenticação backup)                                │
│  └── Regras hierárquicas por grupo AD                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  CAMADA 3: HOST (CrowdSec)                                              │
│  ├── 57+ cenários de deteção (CVEs, brute-force, scans)                 │
│  ├── 3 Bouncers: Cloudflare + Firewall + Nginx                          │
│  ├── Community Blocklist: ~70.000 IPs maliciosos                        │
│  └── Análise comportamental de logs em tempo real                       │
├─────────────────────────────────────────────────────────────────────────┤
│  CAMADA 4: APLICAÇÃO                                                    │
│  ├── Mailcow: SPF + DKIM + DMARC + Rspamd                               │
│  ├── Nginx: Rate limiting + Geo-blocking                                │
│  ├── Nextcloud: LDAP + 2FA + Geo-access control                         │
│  └── Samba AD: Password policies + Account lockout                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Stack Tecnológica

### Infraestrutura Core

| Componente | Tecnologia | Função |
|------------|------------|--------|
| **Virtualização** | Proxmox VE 9.0.3 | Hypervisor Type-1 com KVM/LXC, memory ballooning |
| **Firewall** | pfSense CE 2.8.1 | Four-legged firewall com 4 zonas |
| **Identidade** | Samba AD DC 4.x | Active Directory + DNS + DHCP |
| **Autenticação** | FreeRADIUS 3.x | RADIUS para VPN com integração AD |

### Serviços

| Componente | Tecnologia | Localização | Integração |
|------------|------------|-------------|------------|
| **Email** | Mailcow (Postfix + Dovecot + Rspamd + SOGo) | DMZ | LDAP Auth |
| **Web Server** | Nginx | DMZ | Reverse Proxy para 6 serviços |
| **Ficheiros** | Nextcloud 32.0.0 | LAN | LDAP + Geo-access |
| **Suporte** | Zammad 6.5.2 | LAN | LDAP Auth |
| **Backup** | Proxmox Backup Server | LAN | Encriptação + Deduplicação |
| **VPN** | OpenVPN 2.x (2 instâncias) | pfSense | RADIUS + Local Auth |

### Segurança

| Camada | Tecnologia | Proteção |
|--------|------------|----------|
| **Edge** | Cloudflare | WAF, DDoS, CDN (HTTP/HTTPS only) |
| **Perímetro** | pfSense | Firewall stateful, NAT, VPN duplo |
| **Host** | CrowdSec | IDS/IPS distribuído, 57+ cenários |
| **Email** | Mailcow (Rspamd) + SPF/DKIM/DMARC | Anti-spam, Anti-malware |
| **Aplicação** | Rate limiting, Geo-blocking, LDAP | Por serviço |

### Monitorização

| Componente | Tecnologia | Função |
|------------|------------|--------|
| **Observabilidade** | Netdata Cloud | Monitorização centralizada de 6 servidores |
| **Métricas** | Netdata Agents | 800+ métricas por servidor, 1s granularidade |
| **Alertas** | Email + Mobile App | Notificações push em tempo real |
| **AI Insights** | Machine Learning | Análise preditiva, anomaly detection |
| **Administração** | Cockpit | Terminal web, gestão de serviços |

---

## 📊 Métricas da Infraestrutura

### Segurança

| Métrica | Valor |
|---------|-------|
| **Cenários CrowdSec Ativos** | 57+ (incluindo CVEs críticas) |
| **IPs na Blocklist** | ~70.000 (CAPI community) |
| **Ameaças Mitigadas (24h)** | 234 pelo Cloudflare |
| **Pedidos Bloqueados** | 411 pelo Nginx Bouncer |
| **Zonas de Segurança** | 4 (WAN/LAN/DMZ/VPN) |
| **Regras de Firewall** | 72+ regras hierárquicas |

### Monitorização

| Métrica | Valor |
|---------|-------|
| **Servidores Monitorizados** | 6/6 (100%) |
| **Serviços Auto-descobertos** | 45+ |
| **Granularidade Temporal** | 1 segundo |
| **Overhead de Monitorização** | 1.8% CPU, 150MB RAM |
| **Retenção de Dados** | 14 dias |
| **MTTD (Mean Time To Detect)** | <60 segundos |

### Virtualização

| Métrica | Valor |
|---------|-------|
| **Host Proxmox** | mail.fsociety.pt |
| **CPU** | Intel Core i5-7300HQ @ 2.50GHz (4 cores) |
| **RAM Total** | 16 GB |
| **Storage** | HDD 1TB + NVMe 224GB |
| **VMs em Produção** | 6 de 7 |
| **Uptime Médio** | 99.5% |

---

## 📁 Estrutura do Repositório

```
fsociety-infrastructure/
├── 📄 README.md                          # Este ficheiro
├── 📄 LICENSE                            # Licença MIT
│
└── 📁 docs/                              # Documentação (GitHub Pages)
    ├── index.md                          # Página inicial
    ├── 01-proxmox/                       # Virtualização
    │   ├── README.md                     # Overview do Proxmox
    │   ├── 01-instalacao.md              # Instalação
    │   ├── 02-configuracao-rede.md       # Network bridges
    │   ├── 03-storage.md                 # LVM + NVMe
    │   ├── 04-criacao-vms.md             # Criação de VMs
    │   ├── 05-backup-config.md           # Integração PBS
    │   └── 06-manutencao.md              # Manutenção
    │
    ├── 03-pfsense/                       # 10 documentos
    │   ├── README.md                     # Overview do pfSense
    │   ├── 01-instalacao.md              # Instalação inicial
    │   ├── 02-interfaces.md              # 4 interfaces (WAN/LAN/DMZ/VPN)
    │   ├── 03-firewall-rules.md          # 72 regras
    │   ├── 04-nat-port-forwarding.md     # Port forwarding
    │   ├── 05-aliases.md                 # Aliases por grupo AD
    │   ├── 06-openvpn.md                 # 2 servidores VPN
    │   ├── 07-dhcp-dns.md                # DHCP Relay + DNS Resolver
    │   ├── 08-crowdsec-bouncer.md        # Integração CrowdSec
    │   ├── 09-backup-restore.md          # Backup de configuração
    │   └── 10-accounting-daemon.md       # RADIUS Accounting (RFC 2866)
    │
    ├── 04-domain-controller/             # 9 documentos
    │   ├── README.md                     # Overview do DC
    │   ├── 01-instalacao.md              # Instalação Ubuntu Server
    │   ├── 02-samba-ad.md                # Samba AD DC
    │   ├── 03-dns-config.md              # DNS integrado
    │   ├── 04-dhcp-relay.md              # DHCP Relay
    │   ├── 05-freeradius.md              # FreeRADIUS + LDAP
    │   ├── 06-users-groups.md            # Estrutura AD (OUs, grupos)
    │   ├── 07-crowdsec.md                # CrowdSec agent
    │   ├── 08-backup-ad.md               # Backup do AD
    │   └── 09-troubleshooting.md         # Troubleshooting comum
    │
    ├── 05-servidor-ficheiros/            # Nextcloud + Zammad
    │   ├── README.md                     # Overview
    │   ├── 01-instalacao-docker.md       # Docker + Docker Compose
    │   ├── 02-nextcloud.md               # Nextcloud + LDAP
    │   ├── 03-zammad.md                  # Zammad + LDAP
    │   └── 04-backup-containers.md       # Backup de containers
    │
    ├── 06-webserver/                     # Nginx Reverse Proxy
    │   ├── README.md                     # Overview
    │   ├── 01-instalacao-nginx.md        # Instalação Nginx
    │   ├── 02-ssl-certificates.md        # Let's Encrypt + Cloudflare
    │   ├── 03-reverse-proxy-config.md    # 6 Reverse Proxies
    │   ├── 04-proxy-nextcloud.md         # Nextcloud + Geo-access
    │   ├── 05-proxy-mailcow.md           # Mailcow
    │   ├── 06-proxy-zammad.md            # Zammad
    │   ├── 07-crowdsec-bouncer.md        # Nginx Bouncer
    │   └── 08-monitoring.md              # Logs + Métricas
    │
    ├── 07-mailcow/                       # Email Server
    │   ├── README.md                     # Overview do Mailcow
    │   ├── 01-instalacao.md              # Docker Compose
    │   ├── 02-ldap-integration.md        # Integração LDAP
    │   ├── 03-spf-dkim-dmarc.md          # Autenticação de email
    │   ├── 04-rspamd-config.md           # Anti-spam
    │   └── 05-backup.md                  # Backup de emails
    │
    ├── 08-proxmox-backup-server/         # PBS
    │   ├── README.md                     # Overview do PBS
    │   ├── 01-instalacao.md              # Instalação
    │   ├── 02-datastore-config.md        # Configuração storage
    │   ├── 03-backup-jobs.md             # Jobs agendados
    │   ├── 04-encryption.md              # Encriptação
    │   └── 05-restore.md                 # Restore de VMs
    │
    ├── 09-monitorizacao-centralizada/    # Netdata Cloud
    │   ├── README.md                     # Overview de monitorização
    │   └── 01-netdata.md                 # Netdata Cloud completo
    │
    ├── 09-seguranca/                     # Cloudflare + CrowdSec
    │   ├── 01-cloudflare.md              # WAF + DDoS + CDN
    │   └── 02-crowdsec.md                # Arquitetura distribuída
    │
    └── assets/images/                    # Imagens do projeto
        ├── fsociety-infrastructure.png   # Diagrama principal
        ├── 02-Fsociety-Network.png       # Arquitetura de rede
        ├── netdata-all-nodes.png         # Dashboard Netdata
        └── ...                           # Mais screenshots
```
---

## 📄 Documentação Académica

| Documento | Descrição | Download |
|-----------|-----------|----------|
| **Relatório Final ASII** | Relatório completo do projeto 2025/2026 | [PDF](docs/assets/reports/Relatorio-ASII-2025.pdf) |

> 🔐 **Integridade Certificada:** A autenticidade deste documento está registada na blockchain Bitcoin via [OpenTimestamps](https://opentimestamps.org). Ver [prova de certificação](docs/assets/reports/BLOCKCHAIN-PROOF.md).
>
> 📦 **Arquivo Permanente:** DOI [10.5281/zenodo.17840636](https://doi.org/10.5281/zenodo.17840636)

---

## 📖 Documentação Git

| Recurso | Descrição |
|---------|-----------|
| 📚 **[GitHub Pages](https://ryantech00.github.io/fsociety-infrastructure/)** | Documentação formatada e navegável |
| 📝 **[Wiki](https://github.com/RyanTech00/fsociety-infrastructure/wiki)** | Guias passo a passo detalhados |

### Guias Principais

| Componente | Documentação | Descrição |
|------------|--------------|-----------|
| 🖥️ **Proxmox VE** | [docs/01-proxmox/](docs/01-proxmox/) | Virtualização KVM/LXC, 7 VMs, storage dual |
| 🛡️ **pfSense** | [docs/03-pfsense/](docs/03-pfsense/) | Four-legged firewall, 72 regras, 2 VPNs |
| 🖥️ **Domain Controller** | [docs/04-domain-controller/](docs/04-domain-controller/) | Samba AD, DNS, DHCP, RADIUS |
| 📁 **Servidor Ficheiros** | [docs/05-servidor-ficheiros/](docs/05-servidor-ficheiros/) | Nextcloud 32.0, Zammad 6.5 |
| 🌐 **Webserver** | [docs/06-webserver/](docs/06-webserver/) | Nginx, 6 Reverse Proxies, SSL |
| 📧 **Mailcow** | [docs/07-mailcow/](docs/07-mailcow/) | Email completo com LDAP |
| 💾 **Proxmox Backup** | [docs/08-proxmox-backup-server/](docs/08-proxmox-backup-server/) | PBS com encriptação |
| 📊 **Monitorização** | [docs/09-monitorizacao-centralizada/](docs/09-monitorizacao-centralizada/) | Netdata Cloud + AI Insights |

### Destaques Técnicos

- 🔄 **[RADIUS Accounting Daemon](docs/03-pfsense/10-accounting-daemon.md)** - Script para contabilização de sessões VPN (RFC 2866)
- 🔐 **[Hierarquia VPN por Grupos AD](docs/03-pfsense/06-openvpn.md)** - Pools de IP baseados em grupos do Active Directory
- 🌍 **[Geo-Access Control](docs/06-webserver/04-proxy-nextcloud.md)** - Controlo de acesso por localização (internos vs externos)
- 🛡️ **[CrowdSec Multi-Server](docs/04-domain-controller/07-crowdsec.md)** - IDS/IPS distribuído com 57+ cenários
- 📊 **[Netdata AI Insights](docs/09-monitorizacao-centralizada/01-netdata.md)** - Análise preditiva de 168h com ML
- 🔌 **[OpenVPN Dual-Server](docs/03-pfsense/06-openvpn.md)** - RADIUS (produção) + Local (backup)

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa (@RyanTech00), Hugo Correia (@hugocorreia2004), Igor Araújo (@FK3570) |
| **Domínio** | fsociety.pt |

---

## 📚 Citação

Se utilizar este projeto ou a documentação como referência académica, por favor cite:

> Barbosa, R., Correia, H., & Araújo, I. (2025). FSociety Infrastructure: Enterprise Network with Four-Legged Firewall (v1.1.0). Zenodo. https://doi.org/10.5281/zenodo.17840636

**BibTeX:**

```bibtex
@software{fsociety_infra_2025,
  author       = {Barbosa, Ryan and Correia, Hugo and Araújo, Igor},
  title        = {FSociety Infrastructure: Enterprise Network with Four-Legged Firewall},
  month        = dec,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {v1.1.0},
  doi          = {10.5281/zenodo.17840636},
  url          = {https://doi.org/10.5281/zenodo.17840636}
}
```
---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

<div align="center">

<img src="docs/assets/images/fsociety-infrastructure.png" alt="FSociety Logo" width="150">

*"Control is an illusion, and whoever has the illusion has the control."*

**[⬆ Voltar ao topo](#-fsocietypt)**

---

<sub>🔐 FSociety.pt - Infraestrutura Empresarial Segura | Projeto Universitário em Cibersegurança, Redes e Sistemas Informáticos na ESTG/IPP - 2025/2026</sub>

</div>
