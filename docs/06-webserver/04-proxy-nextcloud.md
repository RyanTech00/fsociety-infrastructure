# ☁️ Proxy - Nextcloud com Geo-Access Control

> **Reverse proxy para Nextcloud com controlo de acesso baseado em geolocalização**

---

## 📋 Índice

1. [Conceito](#-conceito)
2. [Configuração do Proxy](#-configuração-do-proxy)
3. [Geo-Access Control](#-geo-access-control)
4. [Headers e SSL](#-headers-e-ssl)
5. [Verificação](#-verificação)
6. [Referências](#-referências)

---

## 🌍 Conceito

### Regras de Acesso

| Origem | Acesso | Restrições |
|--------|--------|------------|
| **LAN** (192.168.1.0/24) | Completo | Todas as apps |
| **VPN** (10.8.0.0/24, 10.9.0.0/24) | Completo | Todas as apps |
| **Internet** (Externos) | Restrito | Apenas Mail app |

### Paths Permitidos Externamente

```
/apps/mail/*           # Mail app
/remote.php/dav/*      # CalDAV/CardDAV
/ocs/*                 # OCS API (necessário)
/index.php/apps/mail/* # Mail app endpoint
```

Todos os outros paths: **403 Forbidden**

---

## ⚙️ Configuração do Proxy

### 05-nextcloud-proxy.conf

```bash
sudo nano /etc/nginx/sites-available/05-nextcloud-proxy.conf
```

Conteúdo:

```nginx
# Geo map para controlo de acesso
geo $internal_network {
    default 0;
    192.168.1.0/24 1;  # LAN
    10.8.0.0/24 1;     # VPN RADIUS
    10.9.0.0/24 1;     # VPN Local
    10.0.0.0/24 1;     # DMZ (própria rede)
}

# Map para determinar acesso externo
map $internal_network$uri $deny_external {
    default 1;
    # Rede interna: permitir tudo
    ~^1 0;
    # Externa: permitir apenas mail app
    ~^0/apps/mail 0;
    ~^0/remote.php/dav 0;
    ~^0/ocs 0;
    ~^0/index.php/apps/mail 0;
}

server {
    listen 80;
    listen [::]:80;
    server_name nextcloud.fsociety.pt;
    
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name nextcloud.fsociety.pt;
    
    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    # Logs
    access_log /var/log/nginx/nextcloud_proxy_access.log main;
    error_log /var/log/nginx/nextcloud_proxy_error.log;
    
    # Rate limiting
    limit_req zone=general_limit burst=30 nodelay;
    
    # Max upload size
    client_max_body_size 512M;
    client_body_buffer_size 512k;
    client_body_timeout 300s;
    
    # Timeouts para uploads grandes
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    send_timeout 300;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    
    # Geo-based access control
    if ($deny_external) {
        return 403;
    }
    
    # Main proxy
    location / {
        proxy_pass https://192.168.1.40:443;
        proxy_ssl_verify off;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebDAV
        proxy_set_header Destination $http_destination;
        
        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
        
        # HTTP version
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
    
    # Well-known (CalDAV/CardDAV)
    location /.well-known/carddav {
        return 301 $scheme://$host/remote.php/dav;
    }
    
    location /.well-known/caldav {
        return 301 $scheme://$host/remote.php/dav;
    }
    
    # Status page (internal only)
    location /status.php {
        if ($internal_network = 0) {
            return 403;
        }
        proxy_pass https://192.168.1.40:443;
    }
}
```

### Ativar Site

```bash
sudo ln -s /etc/nginx/sites-available/05-nextcloud-proxy.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🌍 Geo-Access Control

### Como Funciona

1. **geo $internal_network**: Define se o IP é interno (1) ou externo (0)
2. **map $internal_network$uri**: Combina rede + URI para decidir acesso
3. **if ($deny_external)**: Bloqueia se necessário

### Teste de Acesso

#### Acesso Interno (Deve Funcionar)

```bash
# De dentro da LAN/VPN
curl -I https://nextcloud.fsociety.pt/apps/calendar
# Status: 200 OK
```

#### Acesso Externo (Deve Bloquear)

```bash
# De fora (Internet)
curl -I https://nextcloud.fsociety.pt/apps/calendar
# Status: 403 Forbidden

# Mas Mail app deve funcionar
curl -I https://nextcloud.fsociety.pt/apps/mail
# Status: 200 OK
```

---

## 📝 Headers e SSL

### Headers Específicos Nextcloud

```nginx
proxy_set_header Host $host;                      # Hostname original
proxy_set_header X-Forwarded-Proto $scheme;       # HTTPS
proxy_set_header X-Forwarded-Host $host;          # Host original
proxy_set_header Destination $http_destination;   # WebDAV MOVE/COPY
```

### SSL Backend

```nginx
proxy_pass https://192.168.1.40:443;  # HTTPS backend
proxy_ssl_verify off;                  # Não verificar cert (interno)
```

---

## ✅ Verificação

### Teste LAN

```bash
# De dentro da LAN
curl -I https://nextcloud.fsociety.pt
curl -I https://nextcloud.fsociety.pt/apps/files
curl -I https://nextcloud.fsociety.pt/apps/calendar
```

### Teste Externo

```bash
# Simular IP externo (via proxy)
curl -I -H "X-Real-IP: 1.2.3.4" https://nextcloud.fsociety.pt/apps/files
# Deve retornar 403

curl -I -H "X-Real-IP: 1.2.3.4" https://nextcloud.fsociety.pt/apps/mail
# Deve retornar 200
```

### Logs

```bash
# Ver acessos bloqueados
sudo grep "403" /var/log/nginx/nextcloud_proxy_access.log

# Ver acessos externos ao mail
sudo grep "apps/mail" /var/log/nginx/nextcloud_proxy_access.log | grep -v "192.168.1"
```

---

## 📖 Referências

- [Nginx Geo Module](https://nginx.org/en/docs/http/ngx_http_geo_module.html)
- [Nginx Map Module](https://nginx.org/en/docs/http/ngx_http_map_module.html)
- [Nextcloud Reverse Proxy](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/reverse_proxy_configuration.html)

---

<div align="center">

**[⬅️ Voltar: Site FSociety](03-site-fsociety.md)** | **[Próximo: Proxy Zammad ➡️](05-proxy-zammad.md)**

</div>

---

*Última atualização: Dezembro 2024*
