# 🌐 Webserver DMZ - FSociety.pt

> **Servidor Web de Perímetro e Reverse Proxy**  
>  
> Documentação completa do Webserver DMZ da infraestrutura FSociety.pt, incluindo Nginx, site principal, reverse proxies, SSL e CrowdSec com múltiplos bouncers.

---

## 📋 Informação do Servidor

| Campo | Valor |
|-------|-------|
| **Hostname** | webserver.fsociety.pt |
| **Endereço IP** | 10.0.0.30 |
| **Sistema Operativo** | Ubuntu 24.04.3 LTS (Noble Numbat) |
| **Kernel** | 6.8.0-generic |
| **Virtualização** | KVM (Proxmox VE) |
| **RAM** | 794 MB |
| **Disco** | 24 GB |
| **Zona de Rede** | DMZ (10.0.0.0/24) |

---

## 🏗️ Arquitetura DMZ

```
                        ┌─────────────────┐
                        │   INTERNET      │
                        │  Cloudflare WAF │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │    pfSense      │
                        │  192.168.31.100 │
                        │  NAT:80/443     │
                        └────────┬────────┘
                                 │
┌────────────────────────────────┼────────────────────────────────┐
│                         DMZ (10.0.0.0/24)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Webserver (10.0.0.30) - Nginx 1.24.0           │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │  SITE PRINCIPAL: fsociety.pt / www.fsociety.pt  │    │  │
│  │  │  Mr. Robot Theme | Matrix Rain | Hacker Style   │    │  │
│  │  │  Location: /var/www/fsociety.pt/public_html/    │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │          REVERSE PROXIES (6 vhosts)             │    │  │
│  │  ├─────────────────────────────────────────────────┤    │  │
│  │  │ 1. autoconfig.fsociety.pt → 10.0.0.20          │    │  │
│  │  │ 2. autodiscover.fsociety.pt → 10.0.0.20        │    │  │
│  │  │ 3. fsociety.pt/www → Site Local                 │    │  │
│  │  │ 4. mail.fsociety.pt → 10.0.0.20 (SOGo)         │    │  │
│  │  │ 5. nextcloud.fsociety.pt → 192.168.1.40:443    │    │  │
│  │  │    - Geo-based access control                   │    │  │
│  │  │    - External: Mail app only                    │    │  │
│  │  │    - Internal/VPN: Full access                  │    │  │
│  │  │ 6. tickets.fsociety.pt → 192.168.1.40:8081     │    │  │
│  │  │    - Internal access only (LAN + VPN)          │    │  │
│  │  │    - WebSocket support                          │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │  SEGURANÇA                                       │    │  │
│  │  │  • Security Headers (HSTS, CSP, XSS, etc)       │    │  │
│  │  │  • Rate Limiting (10r/s geral, 5r/m login)      │    │  │
│  │  │  • SSL/TLS 1.2/1.3 + Strong Ciphers             │    │  │
│  │  │  • Compression: Gzip + Brotli                    │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │  CROWDSEC (3 Bouncers)                          │    │  │
│  │  │  • cs-cloudflare-bouncer v0.3.0                 │    │  │
│  │  │  • cs-firewall-bouncer v0.0.34                  │    │  │
│  │  │  • crowdsec-nginx-bouncer v1.1.3 (Lua)          │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Mailcow (10.0.0.20)                         │  │
│  │  SMTP | IMAP | POP3 | SOGo | ActiveSync                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │   LAN Servers   │
                        │ 192.168.1.0/24  │
                        │                 │
                        │ • Nextcloud     │
                        │ • Zammad        │
                        │ • Domain Ctrl   │
                        └─────────────────┘
```

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Ubuntu, rede DMZ, pacotes base |
| 2 | [Nginx - Configuração Global](02-nginx-config.md) | nginx.conf, security headers, rate limiting |
| 3 | [Site FSociety.pt](03-site-fsociety.md) | Site principal, tema Mr. Robot, assets |
| 4 | [Proxy - Nextcloud](04-proxy-nextcloud.md) | Reverse proxy com geo-access control |
| 5 | [Proxy - Zammad](05-proxy-zammad.md) | Reverse proxy com acesso restrito |
| 6 | [Proxy - Mailcow](06-proxy-mailcow.md) | Proxies mail, autoconfig, autodiscover |
| 7 | [SSL Let's Encrypt](07-ssl-letsencrypt.md) | Certificados wildcard |
| 8 | [DNS Cloudflare](08-dns-cloudflare.md) | Registos DNS, proxy status |
| 9 | [CrowdSec](09-crowdsec.md) | 3 bouncers, integração Lua |
| 10 | [Manutenção](10-manutencao.md) | Logs, troubleshooting, updates |

---

## 🔌 Serviços e Portas

| Porta | Protocolo | Serviço | Descrição |
|-------|-----------|---------|-----------|
| 80 | TCP | Nginx HTTP | Redireciona para HTTPS |
| 443 | TCP | Nginx HTTPS | Todos os vhosts SSL |

### Port Forwarding (pfSense → Webserver)

| Porta Externa | Destino Interno | Serviço |
|---------------|----------------|---------|
| 80 | 10.0.0.30:80 | HTTP (redirect HTTPS) |
| 443 | 10.0.0.30:443 | HTTPS (todos os vhosts) |

---

## 🌐 Virtual Hosts (6 Sites)

### 1. autoconfig.fsociety.pt
```nginx
# Thunderbird/Outlook email auto-configuration
location /.well-known/autoconfig/mail/config-v1.1.xml
proxy_pass http://10.0.0.20 (Mailcow)
```

### 2. autodiscover.fsociety.pt
```nginx
# Microsoft Autodiscover (Exchange)
location /autodiscover/autodiscover.xml
location /Autodiscover/Autodiscover.xml
proxy_pass http://10.0.0.20 (Mailcow)
```

### 3. fsociety.pt / www.fsociety.pt
```nginx
# Site Principal - Mr. Robot Theme
root /var/www/fsociety.pt/public_html
• Matrix rain canvas animation
• Glitch text effects
• Terminal-style interface
• fsociety.mp4 video background
• Quote: "Control is an illusion..."
```

### 4. mail.fsociety.pt
```nginx
# Mailcow SOGo Webmail + ActiveSync
proxy_pass http://10.0.0.20
Locations: /SOGo, /Microsoft-Server-ActiveSync
```

### 5. nextcloud.fsociety.pt ⭐
```nginx
# Nextcloud com Geo-Based Access Control
proxy_pass https://192.168.1.40:443

Access Rules:
• Internal (LAN + VPN): Full access to all apps
• External (Internet): Mail app ONLY
  - /apps/mail/*, /remote.php/dav/*, /ocs/*
  - All other paths blocked with 403
```

### 6. tickets.fsociety.pt
```nginx
# Zammad Ticketing System (Internal Only)
proxy_pass http://192.168.1.40:8081

Access: LAN (192.168.1.0/24) + VPN (10.8.0.0/24, 10.9.0.0/24)
WebSocket: /ws, /cable
```

---

## 🔐 Modelo de Segurança

### Security Headers (Global)

```nginx
# Proteção contra Clickjacking
X-Frame-Options: SAMEORIGIN

# Prevenção MIME-type sniffing
X-Content-Type-Options: nosniff

# XSS Protection
X-XSS-Protection: 1; mode=block

# HSTS (HTTP Strict Transport Security)
Strict-Transport-Security: max-age=31536000; includeSubDomains

# Content Security Policy
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'

# Referrer Policy
Referrer-Policy: strict-origin-when-cross-origin
```

### Rate Limiting

| Zona | Limite | Burst | Aplicação |
|------|--------|-------|-----------|
| **general_limit** | 10 req/s | 20 | Global (todos os requests) |
| **login_limit** | 5 req/m | 10 | Logins (Nextcloud, Zammad, Mail) |

### SSL/TLS Configuration

| Parâmetro | Valor |
|-----------|-------|
| **Protocolos** | TLSv1.2 TLSv1.3 |
| **Ciphers** | ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256 |
| **ECDH Curve** | secp384r1 |
| **DH Params** | 4096 bits |
| **Session Cache** | shared:SSL:10m |
| **Session Timeout** | 10m |
| **OCSP Stapling** | Enabled |

---

## 🎨 Site FSociety.pt - Assets

### Estrutura de Ficheiros

```
/var/www/fsociety.pt/public_html/
├── index.html              # Página principal
├── css/
│   └── style.css           # Estilos Mr. Robot theme
├── js/
│   ├── matrix.js           # Matrix rain animation
│   └── glitch.js           # Text glitch effects
├── media/
│   ├── fsociety.mp4        # Vídeo de fundo
│   └── logo.png            # Logo FSociety
└── fonts/
    └── anonymous-pro.woff2 # Fonte monospaced
```

### Características do Tema

- 🎭 **Tema**: Mr. Robot / FSociety (hacker aesthetic)
- 🌧️ **Efeitos**: Matrix rain canvas, glitch text, terminal animation
- 🎥 **Vídeo**: fsociety.mp4 com overlay de áudio
- 💬 **Quote**: "Control is an illusion..."
- 🎨 **Cores**: Verde (#00ff00), Preto (#0d0208), Vermelho (#ff0000)
- 🔤 **Fonte**: Anonymous Pro (monospaced)

---

## 🔒 SSL Certificates (Let's Encrypt)

| Tipo | Domínio | Validade |
|------|---------|----------|
| **Wildcard** | *.fsociety.pt | Até 2026-03-01 |
| **Base** | fsociety.pt | Até 2026-03-01 |

### Domínios Cobertos

- ✅ fsociety.pt
- ✅ www.fsociety.pt
- ✅ mail.fsociety.pt
- ✅ nextcloud.fsociety.pt
- ✅ tickets.fsociety.pt
- ✅ autoconfig.fsociety.pt
- ✅ autodiscover.fsociety.pt

---

## 📊 Métricas de Segurança (CrowdSec)

| Métrica | Valor |
|---------|-------|
| **CrowdSec Agent** | v1.7.3 |
| **Bouncers Ativos** | 3 (Cloudflare + Firewall + Nginx) |
| **Nginx Bouncer** | v1.1.3 (Lua) |
| **Cloudflare Bouncer** | v0.3.0 |
| **Firewall Bouncer** | v0.0.34 |
| **Scenarios** | 50+ (web, nginx, http) |
| **Collections** | linux, nginx, base-http-scenarios |

### Integração Lua (Nginx)

```nginx
# CrowdSec Lua Bouncer carregado em nginx.conf
lua_shared_dict crowdsec_cache 50m;
init_by_lua_block {
    cs = require("crowdsec")
    cs.init("/etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf")
}
access_by_lua_block {
    cs.Allow(ngx.var.remote_addr)
}
```

---

## 🌍 DNS (Cloudflare)

### Registos A/CNAME

| Nome | Tipo | Destino | Proxy |
|------|------|---------|-------|
| @ (fsociety.pt) | A | 188.81.65.191 | ☁️ Proxied |
| www | CNAME | fsociety.pt | ☁️ Proxied |
| mail | A | 188.81.65.191 | ☁️ Proxied |
| nextcloud | A | 188.81.65.191 | ☁️ Proxied |
| tickets | A | 188.81.65.191 | ☁️ Proxied |
| autoconfig | A | 188.81.65.191 | ☁️ Proxied |
| autodiscover | A | 188.81.65.191 | ☁️ Proxied |

### Cloudflare Protection

- 🛡️ **WAF**: OWASP Managed Rules
- 🚫 **DDoS**: L3/L4/L7 Mitigation
- ⚡ **CDN**: 330+ datacenters
- 🔒 **SSL**: Full (Strict) Mode

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

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/)
- [CrowdSec Documentation](https://docs.crowdsec.net/)

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2024*
