# 🌍 DNS - Cloudflare

> **Configuração DNS e proteção WAF/DDoS**

---

## 📋 Registos DNS

### Registos A/CNAME

| Nome | Tipo | Valor | Proxy | TTL |
|------|------|-------|-------|-----|
| @ | A | 188.81.65.191 | ☁️ Proxied | Auto |
| www | CNAME | fsociety.pt | ☁️ Proxied | Auto |
| mail | A | 188.81.65.191 | ☁️ Proxied | Auto |
| nextcloud | A | 188.81.65.191 | ☁️ Proxied | Auto |
| tickets | A | 188.81.65.191 | ☁️ Proxied | Auto |
| autoconfig | A | 188.81.65.191 | ☁️ Proxied | Auto |
| autodiscover | A | 188.81.65.191 | ☁️ Proxied | Auto |

### Registos MX (Email)

| Nome | Tipo | Prioridade | Valor |
|------|------|------------|-------|
| @ | MX | 10 | mail.fsociety.pt |

### Registos TXT (SPF, DKIM, DMARC)

| Nome | Tipo | Valor |
|------|------|-------|
| @ | TXT | `v=spf1 mx ~all` |
| _dmarc | TXT | `v=DMARC1; p=quarantine;` |
| dkim._domainkey | TXT | `v=DKIM1; k=rsa; p=...` |

---

## 🛡️ Cloudflare Protection

### WAF Rules

- OWASP Managed Rules: **Enabled**
- Cloudflare Managed Rules: **Enabled**
- Custom Rules: Rate limiting, geo-blocking

### DDoS Protection

- L3/L4 DDoS: **Auto-mitigated**
- L7 DDoS: **Enabled**

### SSL/TLS Settings

- Mode: **Full (Strict)**
- Min TLS Version: **TLS 1.2**
- TLS 1.3: **Enabled**
- HSTS: **Enabled** (max-age 31536000)

---

<div align="center">

**[⬅️ Voltar: SSL](07-ssl-letsencrypt.md)** | **[Próximo: CrowdSec ➡️](09-crowdsec.md)**

</div>
