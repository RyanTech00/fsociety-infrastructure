# 🎫 Proxy - Zammad (Acesso Restrito)

> **Reverse proxy para Zammad com acesso apenas a redes internas (LAN + VPN)**

---

## 📋 Configuração

### 06-tickets-proxy.conf

```bash
sudo nano /etc/nginx/sites-available/06-tickets-proxy.conf
```

```nginx
# Geo map para controlo de acesso interno
geo $allowed_network {
    default 0;
    192.168.1.0/24 1;  # LAN
    10.8.0.0/24 1;     # VPN RADIUS
    10.9.0.0/24 1;     # VPN Local
    10.0.0.0/24 1;     # DMZ
}

server {
    listen 80;
    server_name tickets.fsociety.pt;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tickets.fsociety.pt;
    
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    access_log /var/log/nginx/tickets_proxy_access.log main;
    error_log /var/log/nginx/tickets_proxy_error.log;
    
    # Permitir apenas redes internas
    if ($allowed_network = 0) {
        return 403;
    }
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://192.168.1.40:8081;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_buffering off;
    }
    
    # WebSocket support
    location ~ ^/(ws|cable) {
        proxy_pass http://192.168.1.40:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
}
```

Ativar:

```bash
sudo ln -s /etc/nginx/sites-available/06-tickets-proxy.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

<div align="center">

**[⬅️ Voltar: Proxy Nextcloud](04-proxy-nextcloud.md)** | **[Próximo: Proxy Mailcow ➡️](06-proxy-mailcow.md)**

</div>
