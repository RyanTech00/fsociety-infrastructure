# ⚙️ Nextcloud - Configuração

> **Configurações avançadas do Nextcloud: config.php, trusted_domains, email, cron e otimizações**

---

## 📋 Índice

1. [Ficheiro config.php](#-ficheiro-configphp)
2. [Trusted Domains](#-trusted-domains)
3. [Configuração de Email](#-configuração-de-email)
4. [Cron Job](#-cron-job)
5. [Cache e Performance](#-cache-e-performance)
6. [Configurações de Segurança](#-configurações-de-segurança)
7. [Pretty URLs](#-pretty-urls)
8. [Configurações de Upload](#-configurações-de-upload)
9. [Verificação](#-verificação)
10. [Referências](#-referências)

---

## 📄 Ficheiro config.php

### Localização

```bash
/var/www/nextcloud/config/config.php
```

### Configuração Completa

```bash
sudo nano /var/www/nextcloud/config/config.php
```

Conteúdo exemplo:

```php
<?php
$CONFIG = array (
  'instanceid' => 'ocxxxxxxxx',
  'passwordsalt' => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  'secret' => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  'trusted_domains' => 
  array (
    0 => 'nextcloud.fsociety.pt',
    1 => 'files.fsociety.pt',
    2 => '192.168.1.40',
  ),
  'datadirectory' => '/mnt/data',
  'dbtype' => 'pgsql',
  'version' => '32.0.0.2',
  'overwrite.cli.url' => 'https://nextcloud.fsociety.pt',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbport' => '5432',
  'dbtableprefix' => 'oc_',
  'dbuser' => 'nextcloud',
  'dbpassword' => 'strong_password_here',
  'installed' => true,
  
  // Cache Redis
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => '/var/run/redis/redis-server.sock',
    'port' => 0,
    'timeout' => 0.0,
  ),
  
  // Email
  'mail_from_address' => 'nextcloud',
  'mail_smtpmode' => 'smtp',
  'mail_sendmailmode' => 'smtp',
  'mail_domain' => 'fsociety.pt',
  'mail_smtphost' => 'mail.fsociety.pt',
  'mail_smtpport' => '587',
  'mail_smtpauth' => 1,
  'mail_smtpauthtype' => 'LOGIN',
  'mail_smtpname' => 'nextcloud@fsociety.pt',
  'mail_smtppassword' => 'smtp_password_here',
  'mail_smtpsecure' => 'tls',
  
  // Default Phone Region
  'default_phone_region' => 'PT',
  
  // Maintenance
  'maintenance' => false,
  'maintenance_window_start' => 1,
  
  // Cron
  'backgroundjobs_mode' => 'cron',
  
  // Preview
  'enable_previews' => true,
  'enabledPreviewProviders' => 
  array (
    0 => 'OC\\Preview\\PNG',
    1 => 'OC\\Preview\\JPEG',
    2 => 'OC\\Preview\\GIF',
    3 => 'OC\\Preview\\BMP',
    4 => 'OC\\Preview\\XBitmap',
    5 => 'OC\\Preview\\MP3',
    6 => 'OC\\Preview\\TXT',
    7 => 'OC\\Preview\\MarkDown',
    8 => 'OC\\Preview\\PDF',
  ),
  
  // Logging
  'loglevel' => 2,
  'log_type' => 'file',
  'logfile' => '/var/www/nextcloud/data/nextcloud.log',
  'log_rotate_size' => 104857600,
  
  // Security
  'updater.release.channel' => 'stable',
  'overwriteprotocol' => 'https',
  'overwritehost' => 'nextcloud.fsociety.pt',
  'htaccess.RewriteBase' => '/',
  
  // Session lifetime (24 hours)
  'session_lifetime' => 86400,
  'session_keepalive' => true,
  
  // Trashbin
  'trashbin_retention_obligation' => 'auto, 30',
  
  // Versioning
  'versions_retention_obligation' => 'auto, 365',
  
  // Apps
  'app_install_overwrite' => 
  array (
  ),
  
  // Trusted Proxies (Webserver DMZ)
  'trusted_proxies' => 
  array (
    0 => '10.0.0.30',
  ),
  
  // File Locking
  'filelocking.enabled' => true,
  
  // Skeletondirectory (desativar para não copiar ficheiros por defeito)
  'skeletondirectory' => '',
  
  // Default Language
  'default_language' => 'pt',
  'default_locale' => 'pt_PT',
  
  // Force Language
  'force_language' => 'pt',
  'force_locale' => 'pt_PT',
  
  // Knowledgebase
  'knowledgebaseenabled' => false,
  
  // Allow local remote servers
  'allow_local_remote_servers' => true,
);
```

### Aplicar Permissões

```bash
sudo chown www-data:www-data /var/www/nextcloud/config/config.php
sudo chmod 640 /var/www/nextcloud/config/config.php
```

---

## 🌐 Trusted Domains

### Adicionar Domínios via OCC

```bash
# Listar domínios confiáveis
sudo -u www-data php /var/www/nextcloud/occ config:system:get trusted_domains

# Adicionar domínio
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 0 --value=nextcloud.fsociety.pt
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 1 --value=files.fsociety.pt
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 2 --value=192.168.1.40
```

### Verificar

```bash
sudo -u www-data php /var/www/nextcloud/occ config:system:get trusted_domains
```

---

## 📧 Configuração de Email

### Configurar SMTP via OCC

```bash
# Configurar servidor SMTP
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpmode --value=smtp
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtphost --value=mail.fsociety.pt
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpport --value=587
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpsecure --value=tls
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpauth --value=1
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpauthtype --value=LOGIN
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpname --value=nextcloud@fsociety.pt
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtppassword --value=smtp_password

# Configurar remetente
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_from_address --value=nextcloud
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain --value=fsociety.pt
```

### Testar Email

```bash
# Enviar email de teste via web interface
# Settings → Basic Settings → Email server → Send email
```

Ou via linha de comandos (criar script PHP):

```bash
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpmode --value=sendmail
```

---

## ⏰ Cron Job

### Configurar Crontab

```bash
# Editar crontab do www-data
sudo crontab -u www-data -e
```

Adicionar linha:

```cron
# Nextcloud cron job (executar a cada 5 minutos)
*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
```

### Verificar Cron

```bash
# Listar crontab
sudo crontab -u www-data -l

# Ver último run do cron via OCC
sudo -u www-data php /var/www/nextcloud/occ background:cron
```

### Configurar Background Jobs Mode

```bash
# Configurar para usar cron
sudo -u www-data php /var/www/nextcloud/occ background:cron

# Verificar
sudo -u www-data php /var/www/nextcloud/occ config:system:get backgroundjobs_mode
```

---

## 🚀 Cache e Performance

### Redis (já configurado)

Verificar configuração Redis no config.php:

```php
'memcache.local' => '\\OC\\Memcache\\APCu',
'memcache.distributed' => '\\OC\\Memcache\\Redis',
'memcache.locking' => '\\OC\\Memcache\\Redis',
'redis' => array (
  'host' => '/var/run/redis/redis-server.sock',
  'port' => 0,
),
```

### APCu

Verificar se APCu está ativo:

```bash
php -m | grep apcu
```

### Otimizações PHP OPcache

Já configurado em `/etc/php/8.3/fpm/php.ini`:

```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=1
opcache.save_comments=1
```

### Verificar Cache

```bash
# Status do cache
sudo -u www-data php /var/www/nextcloud/occ config:list system --private | grep memcache
```

---

## 🔐 Configurações de Segurança

### HTTPS Enforcement

```bash
# Forçar HTTPS
sudo -u www-data php /var/www/nextcloud/occ config:system:set overwriteprotocol --value=https
sudo -u www-data php /var/www/nextcloud/occ config:system:set overwrite.cli.url --value=https://nextcloud.fsociety.pt
```

### Configurar Trusted Proxies

```bash
# Adicionar webserver DMZ como proxy confiável
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_proxies 0 --value=10.0.0.30
```

### Session Settings

```bash
# Session lifetime (24 horas)
sudo -u www-data php /var/www/nextcloud/occ config:system:set session_lifetime --value=86400
sudo -u www-data php /var/www/nextcloud/occ config:system:set session_keepalive --value=true
```

### Brute Force Protection

```bash
# Ativado por defeito através da app 'bruteforcesettings'
sudo -u www-data php /var/www/nextcloud/occ app:list | grep brute
```

---

## 🔗 Pretty URLs

### Atualizar .htaccess

```bash
# Regenerar .htaccess
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
```

### Configurar Rewrite Base

```bash
sudo -u www-data php /var/www/nextcloud/occ config:system:set htaccess.RewriteBase --value=/
```

---

## 📤 Configurações de Upload

### Aumentar Limites PHP

Já configurado em `/etc/php/8.3/fpm/php.ini`:

```ini
upload_max_filesize = 512M
post_max_size = 512M
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
```

### Aumentar Limites Apache

Editar `/etc/apache2/sites-available/nextcloud.conf`:

```apache
<Directory /var/www/nextcloud/>
    # ... outras configurações ...
    
    # Timeout para uploads grandes
    php_value upload_max_filesize 512M
    php_value post_max_size 512M
    php_value memory_limit 512M
    php_value max_execution_time 300
    php_value max_input_time 300
</Directory>
```

### Reiniciar Serviços

```bash
sudo systemctl restart php8.3-fpm
sudo systemctl restart apache2
```

---

## ✅ Verificação

### Security & Setup Warnings

```bash
# Executar verificação de configuração
sudo -u www-data php /var/www/nextcloud/occ security:check
```

Ou via web: **Settings → Administration → Overview**

### Verificar Configurações Aplicadas

```bash
# Listar todas as configurações do sistema
sudo -u www-data php /var/www/nextcloud/occ config:list system

# Ver configuração específica
sudo -u www-data php /var/www/nextcloud/occ config:system:get overwrite.cli.url
sudo -u www-data php /var/www/nextcloud/occ config:system:get backgroundjobs_mode
```

### Teste de Performance

```bash
# Status geral
sudo -u www-data php /var/www/nextcloud/occ status

# Informações do servidor
sudo -u www-data php /var/www/nextcloud/occ serverinfo:get
```

---

## 📝 Checklist de Configuração

- [x] config.php completo e otimizado
- [x] Trusted domains configurados
- [x] Email SMTP configurado e testado
- [x] Cron job ativo (cada 5 minutos)
- [x] Redis cache configurado
- [x] APCu local cache ativo
- [x] HTTPS enforcement
- [x] Trusted proxies configurados
- [x] Session settings otimizados
- [x] Pretty URLs ativos
- [x] Upload limits aumentados
- [x] Security check passed

---

## 📖 Referências

- [Nextcloud Configuration Parameters](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html)
- [Nextcloud Email Configuration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/email_configuration.html)
- [Nextcloud Background Jobs](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/background_jobs_configuration.html)
- [Nextcloud Caching](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/caching_configuration.html)

---

<div align="center">

**[⬅️ Voltar: Instalação Nextcloud](02-nextcloud.md)** | **[Próximo: LDAP Integration ➡️](04-nextcloud-ldap.md)**

</div>

---

*Última atualização: Dezembro 2025*
