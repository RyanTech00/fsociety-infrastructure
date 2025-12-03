# 🔧 Manutenção do Webserver DMZ

> **Guia de manutenção, logs, troubleshooting e updates**

---

## 📋 Índice

1. [Logs](#-logs)
2. [Monitorização](#-monitorização)
3. [Backup](#-backup)
4. [Updates](#-updates)
5. [Troubleshooting](#-troubleshooting)
6. [Comandos Úteis](#-comandos-úteis)
7. [Referências](#-referências)

---

## 📋 Logs

### Nginx Logs

```bash
# Access logs por vhost
sudo tail -f /var/log/nginx/fsociety_access.log
sudo tail -f /var/log/nginx/nextcloud_proxy_access.log
sudo tail -f /var/log/nginx/tickets_proxy_access.log
sudo tail -f /var/log/nginx/mail_proxy_access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/fsociety_error.log

# Todos os access logs
sudo tail -f /var/log/nginx/*_access.log
```

### Estatísticas de Logs

```bash
# Top 10 IPs
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Top 10 URLs
sudo awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Status codes
sudo awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Erros 5xx
sudo grep " 5[0-9][0-9] " /var/log/nginx/access.log | tail -20

# Rate limiting (429)
sudo grep " 429 " /var/log/nginx/access.log | tail -20
```

### CrowdSec Logs

```bash
# CrowdSec agent
sudo tail -f /var/log/crowdsec.log

# Firewall bouncer
sudo tail -f /var/log/crowdsec-firewall-bouncer.log

# Ver decisões
sudo cscli decisions list

# Ver alertas
sudo cscli alerts list | head -20
```

---

## 📊 Monitorização

### Verificar Serviços

```bash
# Nginx
sudo systemctl status nginx

# CrowdSec
sudo systemctl status crowdsec
sudo systemctl status crowdsec-firewall-bouncer
sudo systemctl status crowdsec-cloudflare-bouncer

# UFW
sudo ufw status verbose
```

### Performance Nginx

```bash
# Processos
ps aux | grep nginx

# Conexões ativas
sudo netstat -an | grep :80 | wc -l
sudo netstat -an | grep :443 | wc -l

# Workers
sudo nginx -V 2>&1 | grep worker
```

### Espaço em Disco

```bash
# Disco geral
df -h

# Logs
du -sh /var/log/nginx/
du -sh /var/log/

# Limpar logs antigos
sudo find /var/log/nginx/ -name "*.gz" -mtime +30 -delete
```

### Memória e CPU

```bash
# Uso geral
free -h
htop

# Por processo
ps aux --sort=-%mem | head -10
ps aux --sort=-%cpu | head -10
```

---

## 💾 Backup

### Script de Backup

```bash
sudo nano /usr/local/bin/backup-webserver.sh
```

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/webserver"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Nginx configs
tar -czf $BACKUP_DIR/nginx_config_$DATE.tar.gz /etc/nginx/

# Site files
tar -czf $BACKUP_DIR/site_files_$DATE.tar.gz /var/www/

# SSL certificates
tar -czf $BACKUP_DIR/ssl_certs_$DATE.tar.gz /etc/letsencrypt/

# CrowdSec config
tar -czf $BACKUP_DIR/crowdsec_config_$DATE.tar.gz /etc/crowdsec/

# Limpar backups > 7 dias
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "[$(date)] Backup concluído"
```

```bash
sudo chmod +x /usr/local/bin/backup-webserver.sh

# Cron diário
sudo crontab -e
# 0 4 * * * /usr/local/bin/backup-webserver.sh >> /var/log/backup-webserver.log 2>&1
```

---

## 🔄 Updates

### Update Sistema

```bash
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
```

### Update Nginx

```bash
# Atualizar Nginx
sudo apt install nginx --only-upgrade

# Verificar versão
nginx -v

# Testar config
sudo nginx -t

# Recarregar
sudo systemctl reload nginx
```

### Update CrowdSec

```bash
# Update hub
sudo cscli hub update

# Upgrade collections/scenarios
sudo cscli hub upgrade

# Update agent
sudo apt install crowdsec --only-upgrade

# Reiniciar
sudo systemctl restart crowdsec
```

### Renovar SSL

```bash
# Renovar certificados
sudo certbot renew

# Forçar renovação (se próximo da expiração)
sudo certbot renew --force-renewal

# Recarregar Nginx
sudo systemctl reload nginx

# Verificar expiração
sudo certbot certificates
```

---

## 🚨 Troubleshooting

### Nginx Não Inicia

```bash
# Ver erro
sudo nginx -t

# Ver logs
sudo journalctl -u nginx -xe

# Verificar portas em uso
sudo netstat -tlnp | grep -E ':80|:443'

# Matar processos antigos
sudo pkill -9 nginx
sudo systemctl start nginx
```

### SSL Errors

```bash
# Verificar certificados
ls -la /etc/letsencrypt/live/fsociety.pt/

# Permissões
sudo chown -R root:root /etc/letsencrypt
sudo chmod -R 755 /etc/letsencrypt

# Testar SSL
openssl s_client -connect fsociety.pt:443 -servername fsociety.pt
```

### Rate Limiting Issues

```bash
# Ver zona de rate limit
sudo nginx -T | grep limit_req_zone

# Aumentar limites temporariamente (editar nginx.conf)
limit_req_zone ... rate=20r/s;  # Era 10r/s

sudo nginx -t
sudo systemctl reload nginx
```

### CrowdSec Ban Incorreto

```bash
# Ver decisões
sudo cscli decisions list

# Remover ban
sudo cscli decisions delete --ip 1.2.3.4

# Adicionar a whitelist
sudo nano /etc/crowdsec/parsers/s02-enrich/whitelist.yaml

# Recarregar
sudo systemctl reload crowdsec
```

---

## 🛠️ Comandos Úteis

### Nginx

```bash
# Testar configuração
sudo nginx -t

# Recarregar (sem downtime)
sudo systemctl reload nginx

# Reiniciar
sudo systemctl restart nginx

# Ver config completa
sudo nginx -T

# Ver módulos carregados
nginx -V
```

### CrowdSec

```bash
# Status
sudo cscli metrics
sudo cscli hub list

# Bouncers
sudo cscli bouncers list

# Decisões
sudo cscli decisions list

# Alertas
sudo cscli alerts list

# Ban manual
sudo cscli decisions add --ip 1.2.3.4 --duration 24h

# Unban
sudo cscli decisions delete --ip 1.2.3.4
```

### Logs

```bash
# Limpar logs antigos
sudo find /var/log/nginx -name "*.gz" -delete
sudo journalctl --vacuum-time=7d

# Rodar logs manualmente
sudo logrotate -f /etc/logrotate.d/nginx
```

---

## 📝 Checklist de Manutenção Mensal

- [ ] Verificar espaço em disco
- [ ] Verificar logs por erros
- [ ] Atualizar sistema e Nginx
- [ ] Renovar SSL (se necessário)
- [ ] Verificar decisões CrowdSec
- [ ] Limpar logs antigos (>30 dias)
- [ ] Testar acesso a todos os vhosts
- [ ] Verificar backups
- [ ] Verificar rate limiting
- [ ] Update CrowdSec hub

---

## 📖 Referências

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx Log Analysis](https://www.nginx.com/blog/using-nginx-logging-for-application-performance-monitoring/)
- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)

---

<div align="center">

**[⬅️ Voltar: CrowdSec](09-crowdsec.md)** | **[Voltar ao README ⬆️](README.md)**

</div>

---

*Última atualização: Dezembro 2024*
