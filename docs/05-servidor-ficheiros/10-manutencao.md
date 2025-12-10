# 🔧 Manutenção do Servidor de Ficheiros

> **Guia de manutenção, backup, comandos OCC e troubleshooting**

---

## 📋 Índice

1. [Backup](#-backup)
2. [Comandos OCC Nextcloud](#-comandos-occ-nextcloud)
3. [Gestão de Utilizadores](#-gestão-de-utilizadores)
4. [Manutenção da Base de Dados](#-manutenção-da-base-de-dados)
5. [Updates e Upgrades](#-updates-e-upgrades)
6. [Monitorização](#-monitorização)
7. [Troubleshooting](#-troubleshooting)
8. [Logs](#-logs)
9. [Referências](#-referências)

---

## 💾 Backup

### Script de Backup Completo

```bash
sudo nano /usr/local/bin/backup-fileserver.sh
```

Conteúdo:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/fileserver"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p $BACKUP_DIR

echo "[$(date)] Iniciando backup..."

# 1. Ativar modo de manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# 2. Backup PostgreSQL
echo "Backup PostgreSQL..."
sudo -u postgres pg_dump nextcloud | gzip > $BACKUP_DIR/nextcloud_db_$DATE.sql.gz
sudo -u postgres pg_dump zammad_production | gzip > $BACKUP_DIR/zammad_db_$DATE.sql.gz

# 3. Backup ficheiros Nextcloud
echo "Backup ficheiros Nextcloud..."
tar -czf $BACKUP_DIR/nextcloud_files_$DATE.tar.gz /var/www/nextcloud/config /mnt/data

# 4. Backup Zammad
echo "Backup Zammad..."
tar -czf $BACKUP_DIR/zammad_files_$DATE.tar.gz /opt/zammad/config /opt/zammad/storage

# 5. Backup Redis (dump)
echo "Backup Redis..."
redis-cli -s /var/run/redis/redis-server.sock BGSAVE
sleep 5
cp /var/lib/redis/dump.rdb $BACKUP_DIR/redis_dump_$DATE.rdb

# 6. Desativar modo de manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# 7. Limpar backups antigos
echo "Limpeza de backups antigos..."
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.rdb" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup concluído!"
```

### Tornar Executável e Agendar

```bash
# Permissões
sudo chmod +x /usr/local/bin/backup-fileserver.sh

# Adicionar ao cron (diariamente às 3h)
sudo crontab -e

# Adicionar:
0 3 * * * /usr/local/bin/backup-fileserver.sh >> /var/log/backup-fileserver.log 2>&1
```

### Restore

```bash
# 1. Ativar manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# 2. Restore BD
gunzip < /var/backups/fileserver/nextcloud_db_20241203.sql.gz | sudo -u postgres psql nextcloud

# 3. Restore ficheiros
tar -xzf /var/backups/fileserver/nextcloud_files_20241203.tar.gz -C /

# 4. Ajustar permissões
sudo chown -R www-data:www-data /var/www/nextcloud /mnt/data

# 5. Desativar manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
```

---

## 🛠️ Comandos OCC Nextcloud

### Informação do Sistema

```bash
# Status
sudo -u www-data php /var/www/nextcloud/occ status

# Versão
sudo -u www-data php /var/www/nextcloud/occ -V

# Check de configuração
sudo -u www-data php /var/www/nextcloud/occ config:list system
```

### Manutenção

```bash
# Ativar modo de manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Desativar
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# Reparar instalação
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair

# Limpar cache
sudo -u www-data php /var/www/nextcloud/occ maintenance:repair --include-expensive
```

### Files & Database

```bash
# Scan de ficheiros (todos os utilizadores)
sudo -u www-data php /var/www/nextcloud/occ files:scan --all

# Scan de utilizador específico
sudo -u www-data php /var/www/nextcloud/occ files:scan rbarbosa

# Limpar file cache
sudo -u www-data php /var/www/nextcloud/occ files:cleanup

# Re-gerar thumbnails
sudo -u www-data php /var/www/nextcloud/occ preview:generate-all -vvv
```

### Apps

```bash
# Listar apps
sudo -u www-data php /var/www/nextcloud/occ app:list

# Ativar app
sudo -u www-data php /var/www/nextcloud/occ app:enable <app_name>

# Desativar app
sudo -u www-data php /var/www/nextcloud/occ app:disable <app_name>

# Atualizar app
sudo -u www-data php /var/www/nextcloud/occ app:update <app_name>

# Atualizar todas as apps
sudo -u www-data php /var/www/nextcloud/occ app:update --all
```

### Verificações

```bash
# Security check
sudo -u www-data php /var/www/nextcloud/occ security:check

# Verificar integridade de código
sudo -u www-data php /var/www/nextcloud/occ integrity:check-core
sudo -u www-data php /var/www/nextcloud/occ integrity:check-app <app_name>
```

---

## 👥 Gestão de Utilizadores

### LDAP

```bash
# Sincronizar utilizadores LDAP
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy"

# Forçar re-sincronização
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy" --missing-account-action=enable

# Verificar utilizador LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:check-user rbarbosa

# Listar utilizadores
sudo -u www-data php /var/www/nextcloud/occ user:list

# Ver info de utilizador
sudo -u www-data php /var/www/nextcloud/occ user:info rbarbosa
```

### Quotas

```bash
# Ver quota de utilizador
sudo -u www-data php /var/www/nextcloud/occ user:setting rbarbosa files quota

# Definir quota (5GB)
sudo -u www-data php /var/www/nextcloud/occ user:setting rbarbosa files quota 5GB

# Definir quota ilimitada
sudo -u www-data php /var/www/nextcloud/occ user:setting rbarbosa files quota none

# Quota para grupo
sudo -u www-data php /var/www/nextcloud/occ group:list
```

### Sessions

```bash
# Limpar sessões expiradas
sudo -u www-data php /var/www/nextcloud/occ user:delete-expired-sessions

# Ver sessões ativas
sudo -u www-data php /var/www/nextcloud/occ user:list-sessions rbarbosa
```

---

## 🗄️ Manutenção da Base de Dados

### Otimizações

```bash
# Adicionar índices em falta
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices

# Converter colunas para big int
sudo -u www-data php /var/www/nextcloud/occ db:convert-filecache-bigint

# Adicionar colunas em falta
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-columns

# Adicionar primary keys em falta
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-primary-keys
```

### Limpeza

```bash
# Limpar versões antigas de ficheiros
sudo -u www-data php /var/www/nextcloud/occ versions:cleanup

# Limpar trashbin
sudo -u www-data php /var/www/nextcloud/occ trashbin:cleanup --all-users

# Limpar preview cache
sudo -u www-data php /var/www/nextcloud/occ preview:cleanup
```

---

## 🔄 Updates e Upgrades

### Update Nextcloud

```bash
# Verificar updates disponíveis
sudo -u www-data php /var/www/nextcloud/occ update:check

# Atualizar via web updater
# Aceder a: Settings → Administration → Overview → Open updater

# Ou via CLI (download manual)
cd /tmp
wget https://download.nextcloud.com/server/releases/nextcloud-XX.X.X.zip
unzip nextcloud-XX.X.X.zip

# Ativar manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Backup
sudo cp -r /var/www/nextcloud /var/www/nextcloud_backup

# Substituir ficheiros
sudo rsync -av nextcloud/ /var/www/nextcloud/

# Executar upgrade
sudo -u www-data php /var/www/nextcloud/occ upgrade

# Desativar manutenção
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
```

### Update Sistema

```bash
# Atualizar sistema
sudo apt update
sudo apt upgrade -y

# Atualizar PHP
sudo apt install -y php8.3-* --only-upgrade

# Atualizar PostgreSQL (cuidado!)
sudo apt install -y postgresql --only-upgrade

# Reiniciar serviços
sudo systemctl restart php8.3-fpm
sudo systemctl restart apache2
sudo systemctl restart postgresql
```

---

## 📊 Monitorização

### Verificações de Saúde

```bash
# Status geral
sudo -u www-data php /var/www/nextcloud/occ status

# Background jobs
sudo -u www-data php /var/www/nextcloud/occ background:cron

# Ver último run
sudo crontab -u www-data -l
```

### Espaço em Disco

```bash
# Disco geral
df -h

# Uso por diretório
du -sh /var/www/nextcloud
du -sh /mnt/data
du -sh /opt/zammad
du -sh /var/lib/postgresql

# Top 20 ficheiros maiores
find /mnt/data -type f -exec du -h {} + | sort -rh | head -20
```

### Performance

```bash
# Top processos
htop

# Apache status
sudo apachectl status

# PHP-FPM status
sudo systemctl status php8.3-fpm

# PostgreSQL connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

---

## 🚨 Troubleshooting

### Nextcloud Lento

```bash
# Verificar Redis
redis-cli -s /var/run/redis/redis-server.sock ping

# Limpar cache
sudo -u www-data php /var/www/nextcloud/occ files:cleanup

# Reindexar
sudo -u postgres psql nextcloud -c "REINDEX DATABASE nextcloud;"

# Verificar cron
sudo crontab -u www-data -l
```

### Erros de Permissões

```bash
# Reset de permissões
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chown -R www-data:www-data /mnt/data
sudo chmod -R 750 /var/www/nextcloud
sudo chmod -R 750 /mnt/data
```

### Problemas de LDAP

```bash
# Testar conexão LDAP
ldapsearch -x -H ldap://192.168.1.10 -D "CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt" -W -b "DC=fsociety,DC=pt"

# Re-sincronizar
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy" --missing-account-action=enable

# Limpar cache LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:invalidate-cache
```

---

## 📋 Logs

### Nextcloud

```bash
# Nextcloud log
sudo tail -f /var/www/nextcloud/data/nextcloud.log

# Definir log level (0=debug, 1=info, 2=warn, 3=error)
sudo -u www-data php /var/www/nextcloud/occ config:system:set loglevel --value=2

# Rodar logs
sudo -u www-data php /var/www/nextcloud/occ log:rotate
```

### Apache

```bash
# Access log
sudo tail -f /var/log/apache2/nextcloud_access.log

# Error log
sudo tail -f /var/log/apache2/nextcloud_error.log
```

### Nginx (Zammad)

```bash
# Access log
sudo tail -f /var/log/nginx/zammad_access.log

# Error log
sudo tail -f /var/log/nginx/zammad_error.log
```

### PostgreSQL

```bash
# PostgreSQL log
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

### Zammad

```bash
# Production log
sudo tail -f /opt/zammad/log/production.log

# Puma log
sudo tail -f /opt/zammad/log/puma_out.log
```

### System

```bash
# Syslog
sudo tail -f /var/log/syslog

# Auth log
sudo tail -f /var/log/auth.log

# CrowdSec
sudo tail -f /var/log/crowdsec.log
```

---

## 📝 Checklist de Manutenção Mensal

- [ ] Executar backup manual e testar restore
- [ ] Verificar espaço em disco
- [ ] Limpar versões antigas e trashbin
- [ ] Verificar logs por erros
- [ ] Atualizar sistema e aplicações
- [ ] Verificar decisões CrowdSec
- [ ] Testar acesso LDAP
- [ ] Verificar background jobs
- [ ] Otimizar base de dados (VACUUM)
- [ ] Verificar certificados SSL

---

## 📖 Referências

- [Nextcloud OCC Commands](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html)
- [Nextcloud Maintenance](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/)
- [PostgreSQL Maintenance](https://www.postgresql.org/docs/current/maintenance.html)

---

<div align="center">

**[⬅️ Voltar: CrowdSec](09-crowdsec.md)** | **[Voltar ao README ⬆️](README.md)**

</div>

---

*Última atualização: Dezembro 2025*
