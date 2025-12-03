# 🌐 Zammad - Nginx Local

> **Configuração do Nginx local na porta 8081 como proxy para Zammad**

---

## 📋 Índice

1. [Instalação do Nginx](#-instalação-do-nginx)
2. [Configuração do VirtualHost](#-configuração-do-virtualhost)
3. [WebSocket Support](#-websocket-support)
4. [Teste Local](#-teste-local)
5. [Logs](#-logs)
6. [Referências](#-referências)

---

## 📥 Instalação do Nginx

```bash
# Instalar Nginx
sudo apt install -y nginx

# Verificar versão
nginx -v

# Esperado: nginx version: nginx/1.24.0 (Ubuntu)
```

---

## ⚙️ Configuração do VirtualHost

### Criar Configuração

```bash
sudo nano /etc/nginx/sites-available/zammad
```

Conteúdo:

```nginx
upstream zammad-puma {
    server 127.0.0.1:9292;
}

upstream zammad-websocket {
    server 127.0.0.1:6042;
}

server {
    listen 8081;
    listen [::]:8081;

    server_name localhost;

    root /opt/zammad/public;

    access_log /var/log/nginx/zammad_access.log;
    error_log /var/log/nginx/zammad_error.log;

    client_max_body_size 50M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location ~ ^/(assets/|robots.txt|humans.txt|favicon.ico|apple-touch-icon.png) {
        expires max;
    }

    # WebSocket
    location /ws {
        proxy_pass http://zammad-websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Cable (ActionCable WebSocket)
    location /cable {
        proxy_pass http://zammad-websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # API
    location /api/v1/channels_stream {
        proxy_pass http://zammad-websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # Main application
    location / {
        proxy_pass http://zammad-puma;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port 8081;
        proxy_buffering off;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        gzip off;
    }
}
```

### Ativar Site

```bash
# Criar symlink
sudo ln -s /etc/nginx/sites-available/zammad /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Deve retornar: syntax is ok
```

### Remover Site Default (Opcional)

```bash
sudo rm /etc/nginx/sites-enabled/default
```

### Reiniciar Nginx

```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

---

## 🔌 WebSocket Support

### Verificação

O Nginx está configurado para fazer proxy de:

1. **WebSocket Main** (`/ws`)
2. **ActionCable** (`/cable`)
3. **Channel Stream API** (`/api/v1/channels_stream`)

### Parâmetros Importantes

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "Upgrade";
proxy_read_timeout 86400;  # 24 horas
proxy_send_timeout 86400;  # 24 horas
```

---

## 🧪 Teste Local

### Testar HTTP

```bash
# Testar resposta do Nginx
curl -I http://localhost:8081

# Deve retornar 200 OK ou redirect
```

### Testar com Browser

```bash
# No servidor local
curl http://localhost:8081

# Deve retornar HTML do Zammad
```

### Verificar Proxy

```bash
# Ver logs em tempo real
sudo tail -f /var/log/nginx/zammad_access.log
sudo tail -f /var/log/nginx/zammad_error.log
```

### Teste Completo

1. Abrir browser (se disponível)
2. Navegar para: `http://192.168.1.40:8081`
3. Deve aparecer o wizard de configuração do Zammad

---

## 📊 Logs

### Logs do Nginx

```bash
# Access log
sudo tail -f /var/log/nginx/zammad_access.log

# Error log
sudo tail -f /var/log/nginx/zammad_error.log

# Ver últimos 50 acessos
sudo tail -n 50 /var/log/nginx/zammad_access.log
```

### Formato de Log

Access log típico:
```
192.168.1.100 - - [03/Dec/2024:12:00:00 +0000] "GET / HTTP/1.1" 200 5234 "-" "Mozilla/5.0..."
```

### Verificar Erros Comuns

```bash
# Procurar erros 502 Bad Gateway
sudo grep "502" /var/log/nginx/zammad_error.log

# Procurar erros de timeout
sudo grep "timeout" /var/log/nginx/zammad_error.log

# Procurar erros de conexão
sudo grep "connect() failed" /var/log/nginx/zammad_error.log
```

---

## 🔧 Troubleshooting

### Erro 502 Bad Gateway

**Causa:** Puma não está a correr

```bash
# Verificar status do Puma
sudo systemctl status zammad-web.service

# Reiniciar se necessário
sudo systemctl restart zammad-web.service

# Verificar se porta 9292 está em uso
sudo netstat -tlnp | grep 9292
```

### WebSocket Não Funciona

**Causa:** WebSocket server não está ativo

```bash
# Verificar status
sudo systemctl status zammad-websocket.service

# Reiniciar
sudo systemctl restart zammad-websocket.service

# Verificar porta 6042
sudo netstat -tlnp | grep 6042
```

### Permissões

```bash
# Verificar permissões do diretório public
ls -la /opt/zammad/public

# Deve ser owned por zammad:zammad
sudo chown -R zammad:zammad /opt/zammad/public
```

---

## ⚙️ Configurações Adicionais

### Aumentar Upload Size

Se necessário enviar ficheiros maiores:

```nginx
client_max_body_size 100M;  # Aumentar de 50M para 100M
```

### Timeouts

Para tickets com uploads grandes:

```nginx
proxy_read_timeout 600;
proxy_connect_timeout 600;
proxy_send_timeout 600;
```

### Buffer Settings

```nginx
proxy_buffering off;  # Já configurado, desabilita buffering
proxy_request_buffering off;  # Adicionar se necessário
```

---

## 📝 Checklist

- [x] Nginx instalado
- [x] VirtualHost configurado na porta 8081
- [x] Upstreams para Puma (9292) e WebSocket (6042)
- [x] WebSocket support ativado
- [x] Security headers configurados
- [x] Site ativado em sites-enabled
- [x] Nginx testado e a funcionar
- [x] Logs configurados
- [x] Acesso local funcional (192.168.1.40:8081)

---

## 🔗 Próximos Passos

O Zammad está agora acessível localmente na porta 8081.

No próximo passo, o **Webserver DMZ** (10.0.0.30) fará reverse proxy de `tickets.fsociety.pt` para `192.168.1.40:8081`.

---

## 📖 Referências

- [Zammad Nginx Configuration](https://docs.zammad.org/en/latest/appendix/nginx.html)
- [Nginx WebSocket Proxying](https://nginx.org/en/docs/http/websocket.html)
- [Nginx Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

---

<div align="center">

**[⬅️ Voltar: Zammad](06-zammad.md)** | **[Próximo: PostgreSQL e Redis ➡️](08-postgresql-redis.md)**

</div>

---

*Última atualização: Dezembro 2024*
