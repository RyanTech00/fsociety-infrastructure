# 📧 Proxy - Mailcow (Autoconfig + Autodiscover + Mail)

> **Reverse proxies para servidor de email Mailcow**

---

## 📋 Configuração

### 01-autoconfig.conf

```bash
sudo nano /etc/nginx/sites-available/01-autoconfig.conf
```

```nginx
server {
    listen 80;
    server_name autoconfig.fsociety.pt;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name autoconfig.fsociety.pt;
    
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    location / {
        proxy_pass http://10.0.0.20;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 02-autodiscover.conf

```bash
sudo nano /etc/nginx/sites-available/02-autodiscover.conf
```

```nginx
server {
    listen 80;
    server_name autodiscover.fsociety.pt;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name autodiscover.fsociety.pt;
    
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    location / {
        proxy_pass http://10.0.0.20;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 04-mail-proxy.conf

```bash
sudo nano /etc/nginx/sites-available/04-mail-proxy.conf
```

```nginx
server {
    listen 80;
    server_name mail.fsociety.pt;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name mail.fsociety.pt;
    
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://10.0.0.20;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # SOGo webmail
    location /SOGo {
        proxy_pass http://10.0.0.20/SOGo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # ActiveSync
    location /Microsoft-Server-ActiveSync {
        proxy_pass http://10.0.0.20/Microsoft-Server-ActiveSync;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Ativar todos:

```bash
sudo ln -s /etc/nginx/sites-available/01-autoconfig.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/02-autodiscover.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/04-mail-proxy.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

<div align="center">

**[⬅️ Voltar: Proxy Zammad](05-proxy-zammad.md)** | **[Próximo: SSL Let's Encrypt ➡️](07-ssl-letsencrypt.md)**

</div>
