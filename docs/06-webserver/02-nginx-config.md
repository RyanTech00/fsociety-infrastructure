# ⚙️ Nginx - Configuração Global

> **Configuração do Nginx com security headers, rate limiting, SSL/TLS e otimizações**

---

## 📋 Índice

1. [Instalação do Nginx](#-instalação-do-nginx)
2. [Configuração Global (nginx.conf)](#-configuração-global-nginxconf)
3. [Security Headers](#-security-headers)
4. [Rate Limiting](#-rate-limiting)
5. [SSL/TLS Configuration](#-ssltls-configuration)
6. [Compression (Gzip + Brotli)](#-compression-gzip--brotli)
7. [Logging](#-logging)
8. [Verificação](#-verificação)
9. [Referências](#-referências)

---

## 📥 Instalação do Nginx

```bash
# Instalar Nginx
sudo apt install -y nginx

# Verificar versão
nginx -v

# Esperado: nginx version: nginx/1.24.0 (Ubuntu)
```

### Estrutura de Diretórios

```bash
/etc/nginx/
├── nginx.conf                 # Configuração global
├── sites-available/           # VirtualHosts disponíveis
├── sites-enabled/             # VirtualHosts ativos (symlinks)
├── snippets/                  # Snippets reutilizáveis
├── conf.d/                    # Configs adicionais
└── modules-enabled/           # Módulos ativos
```

---

## ⚙️ Configuração Global (nginx.conf)

### Backup da Configuração Original

```bash
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
```

### Editar nginx.conf

```bash
sudo nano /etc/nginx/nginx.conf
```

Conteúdo completo:

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    types_hash_max_size 2048;
    server_tokens off;
    
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=300s;
    resolver_timeout 5s;
    
    # DH Parameters
    ssl_dhparam /etc/nginx/dhparam.pem;
    
    ##
    # Logging Settings
    ##
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";
    
    ##
    # Brotli Settings (se instalado)
    ##
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/json application/javascript 
                 text/xml application/xml+rss text/javascript;
    
    ##
    # Rate Limiting Zones
    ##
    # Limite geral: 10 req/s por IP
    limit_req_zone $binary_remote_addr zone=general_limit:10m rate=10r/s;
    
    # Limite para logins: 5 req/m por IP
    limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
    
    # Limite de conexões simultâneas: 10 por IP
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    
    ##
    # Security Headers (Global)
    ##
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # HSTS (será definido por vhost)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

---

## 🔒 Security Headers

### Headers Aplicados Globalmente

```nginx
# Prevenir clickjacking
add_header X-Frame-Options "SAMEORIGIN" always;

# Prevenir MIME-type sniffing
add_header X-Content-Type-Options "nosniff" always;

# XSS Protection
add_header X-XSS-Protection "1; mode=block" always;

# Referrer Policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Headers por VirtualHost

HSTS e CSP são definidos por cada vhost conforme necessário.

### Criar Snippet para Headers Comuns

```bash
sudo nano /etc/nginx/snippets/security-headers.conf
```

Conteúdo:

```nginx
# Security Headers Snippet
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self';" always;
```

Usar em vhosts:

```nginx
include snippets/security-headers.conf;
```

---

## 🚦 Rate Limiting

### Zonas Definidas

```nginx
# Limite geral: 10 req/s por IP
limit_req_zone $binary_remote_addr zone=general_limit:10m rate=10r/s;

# Limite para logins: 5 req/m por IP
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;

# Conexões simultâneas: 10 por IP
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
```

### Aplicar em VirtualHost

```nginx
server {
    # Aplicar rate limit geral
    limit_req zone=general_limit burst=20 nodelay;
    limit_conn conn_limit 10;
    
    # Limite específico para login
    location ~ ^/(index\.php)?/login {
        limit_req zone=login_limit burst=10 nodelay;
        proxy_pass ...;
    }
}
```

---

## 🔐 SSL/TLS Configuration

### Gerar DH Parameters

```bash
# Gerar dhparam de 4096 bits (demora ~10 minutos)
sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096

# Ou usar 2048 bits (mais rápido)
sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048
```

### Configuração SSL Global

Já definido em `nginx.conf`:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...';
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_dhparam /etc/nginx/dhparam.pem;
```

### OCSP Stapling

```nginx
ssl_stapling on;
ssl_stapling_verify on;
resolver 1.1.1.1 1.0.0.1 valid=300s;
```

---

## 📦 Compression (Gzip + Brotli)

### Gzip (Built-in)

Já configurado em `nginx.conf`:

```nginx
gzip on;
gzip_vary on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript ...;
```

### Brotli (Módulo Adicional)

```bash
# Instalar módulo Brotli
sudo apt install -y libnginx-mod-http-brotli-filter libnginx-mod-http-brotli-static

# Verificar módulos carregados
nginx -V 2>&1 | grep brotli
```

Adicionar em `nginx.conf`:

```nginx
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript;
```

---

## 📋 Logging

### Formato de Log

Definido em `nginx.conf`:

```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';

access_log /var/log/nginx/access.log main;
error_log /var/log/nginx/error.log warn;
```

### Logs por VirtualHost

Cada vhost terá seus próprios logs:

```nginx
server {
    access_log /var/log/nginx/site_access.log main;
    error_log /var/log/nginx/site_error.log;
}
```

### Rotação de Logs

Configurado em `/etc/logrotate.d/nginx`:

```bash
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

---

## ✅ Verificação

### Testar Configuração

```bash
# Teste de sintaxe
sudo nginx -t

# Deve retornar: syntax is ok
```

### Aplicar Configuração

```bash
# Recarregar (sem downtime)
sudo nginx -s reload

# Ou reiniciar
sudo systemctl restart nginx

# Verificar status
sudo systemctl status nginx
```

### Testar Security Headers

```bash
# Testar headers (após configurar vhost)
curl -I https://fsociety.pt

# Verificar headers específicos
curl -I https://fsociety.pt 2>&1 | grep -i "x-frame-options"
curl -I https://fsociety.pt 2>&1 | grep -i "strict-transport"
```

### Verificar Rate Limiting

```bash
# Fazer múltiplos requests
for i in {1..15}; do curl -I http://10.0.0.30; done

# Deve começar a retornar 429 (Too Many Requests) após burst
```

### Verificar Processos

```bash
# Processos Nginx
ps aux | grep nginx

# Worker processes
ps aux | grep "nginx: worker"
```

---

## 📊 Otimizações Aplicadas

| Otimização | Valor | Descrição |
|------------|-------|-----------|
| **worker_processes** | auto | CPU cores automáticos |
| **worker_connections** | 2048 | Conexões por worker |
| **keepalive_timeout** | 65s | Timeout de conexões keepalive |
| **client_max_body_size** | 100M | Upload máximo |
| **gzip_comp_level** | 6 | Compressão balanceada |
| **ssl_session_cache** | 10MB | Cache de sessões SSL |

---

## 📝 Checklist

- [x] Nginx 1.24.0 instalado
- [x] nginx.conf configurado com otimizações
- [x] Security headers globais aplicados
- [x] Rate limiting configurado (3 zonas)
- [x] SSL/TLS configurado (TLS 1.2/1.3)
- [x] DH parameters gerado (4096 bits)
- [x] Gzip compression ativo
- [x] Brotli instalado e ativo
- [x] Logging configurado
- [x] Configuração testada sem erros

---

## 📖 Referências

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx Security](https://docs.nginx.com/nginx/admin-guide/security-controls/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [OWASP Security Headers](https://owasp.org/www-project-secure-headers/)

---

<div align="center">

**[⬅️ Voltar: Instalação](01-instalacao.md)** | **[Próximo: Site FSociety ➡️](03-site-fsociety.md)**

</div>

---

*Última atualização: Dezembro 2024*
