# 🛡️ CrowdSec - 3 Bouncers + Nginx Lua

> **Sistema de deteção de intrusões com múltiplos bouncers**

---

## 📋 Índice

1. [Instalação CrowdSec](#-instalação-crowdsec)
2. [Firewall Bouncer](#-firewall-bouncer)
3. [Cloudflare Bouncer](#-cloudflare-bouncer)
4. [Nginx Lua Bouncer](#-nginx-lua-bouncer)
5. [Configuração e Monitorização](#-configuração-e-monitorização)
6. [Referências](#-referências)

---

## 📥 Instalação CrowdSec

```bash
# Adicionar repositório
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash

# Instalar
sudo apt install -y crowdsec

# Versão: v1.7.3
sudo cscli version
```

### Configurar Aquisição de Logs

```bash
sudo nano /etc/crowdsec/acquis.yaml
```

```yaml
---
filenames:
  - /var/log/nginx/access.log
  - /var/log/nginx/*_access.log
labels:
  type: nginx

---
filenames:
  - /var/log/nginx/error.log
  - /var/log/nginx/*_error.log
labels:
  type: nginx-error

---
filenames:
  - /var/log/auth.log
labels:
  type: syslog
```

### Instalar Collections

```bash
sudo cscli collections install crowdsecurity/nginx
sudo cscli collections install crowdsecurity/linux
sudo cscli collections install crowdsecurity/base-http-scenarios
sudo cscli scenarios install crowdsecurity/http-sensitive-files
sudo cscli scenarios install crowdsecurity/http-probing
sudo cscli scenarios install crowdsecurity/http-crawl-non_statics

sudo systemctl restart crowdsec
```

---

## 🔥 Firewall Bouncer

### Instalação

```bash
sudo apt install -y crowdsec-firewall-bouncer-iptables

# Versão: v0.0.34
```

### Configuração

```bash
sudo nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

```yaml
mode: iptables
pid_dir: /var/run/
update_frequency: 10s
api_url: http://localhost:8080
api_key: <auto_generated>

deny_action: DROP
deny_log: false

iptables_chains:
  - INPUT
  - FORWARD
```

### Verificar

```bash
sudo systemctl status crowdsec-firewall-bouncer
sudo iptables -L crowdsec-chain -n -v
```

---

## ☁️ Cloudflare Bouncer

### Instalação

```bash
# Download
wget https://github.com/crowdsecurity/cs-cloudflare-bouncer/releases/download/v0.3.0/crowdsec-cloudflare-bouncer_0.3.0_linux_amd64.tar.gz

# Extrair
tar -xzf crowdsec-cloudflare-bouncer_0.3.0_linux_amd64.tar.gz
sudo mv crowdsec-cloudflare-bouncer /usr/local/bin/

# Criar service
sudo nano /etc/systemd/system/crowdsec-cloudflare-bouncer.service
```

```ini
[Unit]
Description=CrowdSec Cloudflare Bouncer
After=crowdsec.service

[Service]
ExecStart=/usr/local/bin/crowdsec-cloudflare-bouncer -c /etc/crowdsec/bouncers/crowdsec-cloudflare-bouncer.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

### Configuração

```bash
# Gerar API key
sudo cscli bouncers add cloudflare-bouncer

sudo nano /etc/crowdsec/bouncers/crowdsec-cloudflare-bouncer.yaml
```

```yaml
crowdsec_api_url: http://localhost:8080
crowdsec_api_key: <generated_key>

cloudflare_token: <cloudflare_api_token>
cloudflare_zone_id: <zone_id>

update_frequency: 10s
```

### Iniciar

```bash
sudo systemctl daemon-reload
sudo systemctl enable crowdsec-cloudflare-bouncer
sudo systemctl start crowdsec-cloudflare-bouncer
```

---

## 🌐 Nginx Lua Bouncer

### Instalação

```bash
# Instalar dependências Lua
sudo apt install -y libnginx-mod-http-lua lua-cjson

# Instalar bouncer
sudo apt install -y crowdsec-nginx-bouncer

# Versão: v1.1.3
```

### Configuração Nginx

Adicionar ao `nginx.conf`:

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    # CrowdSec Lua
    lua_shared_dict crowdsec_cache 50m;
    
    init_by_lua_block {
        cs = require "crowdsec"
        local ok, err = cs.init("/etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf", "crowdsec-nginx-bouncer")
        if ok == nil then
            ngx.log(ngx.ERR, "[Crowdsec] " .. err)
        end
    }
    
    access_by_lua_block {
        local cs = require "crowdsec"
        cs.Allow(ngx.var.remote_addr)
    }
    
    # ... resto da configuração
}
```

### Configuração do Bouncer

```bash
sudo nano /etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf
```

```conf
ENABLED=true
API_URL=http://localhost:8080
API_KEY=<generated_key>
MODE=stream
UPDATE_FREQUENCY=10
BAN_TEMPLATE_PATH=/etc/crowdsec/bouncers/templates/ban.html
```

### Gerar API Key

```bash
sudo cscli bouncers add nginx-bouncer
```

### Reiniciar Nginx

```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📊 Configuração e Monitorização

### Ver Decisões Ativas

```bash
# Todas as decisões
sudo cscli decisions list

# Por bouncer
sudo cscli decisions list --origin crowdsec
sudo cscli decisions list --origin capi
```

### Ver Alertas

```bash
# Alertas recentes
sudo cscli alerts list

# Por tipo
sudo cscli alerts list --ip 1.2.3.4
sudo cscli alerts list --scenario crowdsecurity/http-probing
```

### Métricas

```bash
# Métricas gerais
sudo cscli metrics

# Bouncers ativos
sudo cscli bouncers list

# Máquinas
sudo cscli machines list
```

### Logs

```bash
# CrowdSec
sudo tail -f /var/log/crowdsec.log

# Firewall Bouncer
sudo tail -f /var/log/crowdsec-firewall-bouncer.log

# Cloudflare Bouncer
sudo journalctl -u crowdsec-cloudflare-bouncer -f
```

---

## 🎯 Resumo dos 3 Bouncers

| Bouncer | Versão | Função | Layer |
|---------|--------|--------|-------|
| **Firewall** | v0.0.34 | iptables DROP | L3/L4 |
| **Cloudflare** | v0.3.0 | WAF block | Edge |
| **Nginx Lua** | v1.1.3 | HTTP block | L7 |

### Fluxo de Proteção

```
Internet → Cloudflare (Edge) → pfSense → iptables (Firewall Bouncer) 
         → Nginx (Lua Bouncer) → Backend
```

---

## 📝 Checklist

- [x] CrowdSec v1.7.3 instalado
- [x] Logs Nginx configurados
- [x] Collections instaladas (nginx, linux, http)
- [x] Firewall bouncer v0.0.34 ativo
- [x] Cloudflare bouncer v0.3.0 ativo
- [x] Nginx Lua bouncer v1.1.3 ativo
- [x] 3 bouncers funcionando em paralelo
- [x] CAPI registado

---

## 📖 Referências

- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [Nginx Lua Bouncer](https://docs.crowdsec.net/docs/bouncers/nginx/)
- [Cloudflare Bouncer](https://docs.crowdsec.net/docs/bouncers/cloudflare/)

---

<div align="center">

**[⬅️ Voltar: DNS Cloudflare](08-dns-cloudflare.md)** | **[Próximo: Manutenção ➡️](10-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2025*
