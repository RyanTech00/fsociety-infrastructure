# ☁️ Nextcloud - Instalação

> **Guia completo de instalação do Nextcloud 32.0.0 com Apache, PHP-FPM 8.3 e PostgreSQL**

---

## 📋 Índice

1. [Pré-requisitos](#-pré-requisitos)
2. [Instalação do Apache](#-instalação-do-apache)
3. [Instalação do PHP 8.3](#-instalação-do-php-83)
4. [Configuração do PostgreSQL](#-configuração-do-postgresql)
5. [Instalação do Redis](#-instalação-do-redis)
6. [Download e Instalação do Nextcloud](#-download-e-instalação-do-nextcloud)
7. [Configuração do Apache para Nextcloud](#-configuração-do-apache-para-nextcloud)
8. [Instalação Web do Nextcloud](#-instalação-web-do-nextcloud)
9. [Verificação](#-verificação)
10. [Referências](#-referências)

---

## 📦 Pré-requisitos

### Pacotes do Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências essenciais
sudo apt install -y \
  wget \
  curl \
  unzip \
  sudo \
  apt-transport-https \
  ca-certificates \
  gnupg \
  software-properties-common
```

---

## 🌐 Instalação do Apache

### Instalar Apache 2.4

```bash
# Instalar Apache
sudo apt install -y apache2

# Verificar versão
apache2 -v
```

**Output esperado:**
```
Server version: Apache/2.4.58 (Ubuntu)
Server built:   2024-10-01T00:00:00
```

### Ativar Módulos Apache

```bash
# Módulos essenciais para Nextcloud
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo a2enmod ssl
sudo a2enmod proxy_fcgi
sudo a2enmod setenvif
sudo a2enmod http2

# Reiniciar Apache
sudo systemctl restart apache2
```

### Verificar Status

```bash
sudo systemctl status apache2
sudo systemctl enable apache2
```

---

## 🐘 Instalação do PHP 8.3

### Adicionar Repositório PHP

```bash
# Adicionar repositório Ondřej Surý
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update
```

### Instalar PHP 8.3 e Extensões

```bash
# PHP-FPM e extensões necessárias para Nextcloud
sudo apt install -y \
  php8.3 \
  php8.3-fpm \
  php8.3-common \
  php8.3-cli \
  php8.3-curl \
  php8.3-gd \
  php8.3-imagick \
  php8.3-intl \
  php8.3-mbstring \
  php8.3-xml \
  php8.3-zip \
  php8.3-bz2 \
  php8.3-bcmath \
  php8.3-gmp \
  php8.3-apcu \
  php8.3-redis \
  php8.3-pgsql \
  libapache2-mod-php8.3
```

### Verificar Instalação

```bash
# Versão PHP
php -v

# Módulos instalados
php -m | grep -E 'curl|gd|intl|mbstring|pgsql|redis|apcu'
```

### Configurar PHP-FPM

Editar `/etc/php/8.3/fpm/php.ini`:

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

Ajustar parâmetros:

```ini
memory_limit = 512M
upload_max_filesize = 512M
post_max_size = 512M
max_execution_time = 300
max_input_time = 300
date.timezone = Europe/Lisbon

opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 1
opcache.save_comments = 1
```

Editar `/etc/php/8.3/fpm/pool.d/www.conf`:

```bash
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
```

Ajustar:

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
```

### Ativar PHP-FPM

```bash
# Ativar configuração PHP-FPM no Apache
sudo a2enconf php8.3-fpm

# Reiniciar serviços
sudo systemctl restart php8.3-fpm
sudo systemctl restart apache2

# Verificar status
sudo systemctl status php8.3-fpm
```

---

## 🐘 Configuração do PostgreSQL

### Instalar PostgreSQL 16

```bash
# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Verificar versão
psql --version
```

### Criar Base de Dados e Utilizador

```bash
# Aceder como utilizador postgres
sudo -u postgres psql
```

Dentro do psql:

```sql
-- Criar utilizador nextcloud
CREATE USER nextcloud WITH PASSWORD 'strong_password_here';

-- Criar base de dados
CREATE DATABASE nextcloud WITH OWNER nextcloud ENCODING 'UTF8' LC_COLLATE='pt_PT.UTF-8' LC_CTYPE='pt_PT.UTF-8' TEMPLATE template0;

-- Conceder privilégios
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;

-- Sair
\q
```

### Configurar Acesso Local

Editar `/etc/postgresql/16/main/pg_hba.conf`:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Adicionar linha:

```conf
# Nextcloud local access
local   nextcloud       nextcloud                               md5
host    nextcloud       nextcloud       127.0.0.1/32            md5
host    nextcloud       nextcloud       ::1/128                 md5
```

### Reiniciar PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql
```

### Testar Conexão

```bash
# Testar acesso à base de dados
psql -U nextcloud -d nextcloud -h localhost

# Dentro do psql
\l
\q
```

---

## 🔴 Instalação do Redis

### Instalar Redis Server

```bash
# Instalar Redis
sudo apt install -y redis-server

# Verificar versão
redis-server --version
```

### Configurar Redis

Editar `/etc/redis/redis.conf`:

```bash
sudo nano /etc/redis/redis.conf
```

Ajustar:

```conf
# Usar socket Unix para melhor performance
unixsocket /var/run/redis/redis-server.sock
unixsocketperm 770

# Port 0 para desativar TCP (apenas socket)
port 0

# Memória máxima
maxmemory 128mb
maxmemory-policy allkeys-lru
```

### Adicionar www-data ao Grupo Redis

```bash
sudo usermod -a -G redis www-data
```

### Reiniciar Redis

```bash
sudo systemctl restart redis-server
sudo systemctl enable redis-server
sudo systemctl status redis-server

# Verificar socket
ls -la /var/run/redis/redis-server.sock
```

---

## ☁️ Download e Instalação do Nextcloud

### Download do Nextcloud 32.0.0

```bash
# Ir para /tmp
cd /tmp

# Download da versão 32.0.0
wget https://download.nextcloud.com/server/releases/nextcloud-32.0.0.zip

# Verificar checksum (opcional mas recomendado)
wget https://download.nextcloud.com/server/releases/nextcloud-32.0.0.zip.sha256
sha256sum -c nextcloud-32.0.0.zip.sha256 < nextcloud-32.0.0.zip
```

### Extrair e Mover

```bash
# Extrair
unzip nextcloud-32.0.0.zip

# Mover para /var/www
sudo mv nextcloud /var/www/

# Criar diretório de dados
sudo mkdir -p /mnt/data

# Definir permissões
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chown -R www-data:www-data /mnt/data
sudo chmod -R 750 /var/www/nextcloud
sudo chmod -R 750 /mnt/data
```

### Limpar Ficheiros Temporários

```bash
cd /tmp
rm -rf nextcloud nextcloud-32.0.0.zip nextcloud-32.0.0.zip.sha256
```

---

## 🌐 Configuração do Apache para Nextcloud

### Criar VirtualHost

Criar `/etc/apache2/sites-available/nextcloud.conf`:

```bash
sudo nano /etc/apache2/sites-available/nextcloud.conf
```

Conteúdo:

```apache
<VirtualHost *:80>
    ServerName nextcloud.fsociety.pt
    ServerAlias files.fsociety.pt
    
    # Redirecionar para HTTPS
    Redirect permanent / https://nextcloud.fsociety.pt/
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName nextcloud.fsociety.pt
    ServerAlias files.fsociety.pt
    
    DocumentRoot /var/www/nextcloud
    
    # SSL Configuration (será configurado com Let's Encrypt)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/nextcloud.fsociety.pt/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/nextcloud.fsociety.pt/privkey.pem
    
    # SSL Security
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    SSLCompression off
    
    # HSTS
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Nextcloud Directory
    <Directory /var/www/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
    
    # PHP-FPM
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.3-fpm.sock|fcgi://localhost"
    </FilesMatch>
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
</IfModule>
```

### Instalar e Configurar Certbot

```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-apache

# Obter certificado SSL (ajustar email e domínio)
sudo certbot --apache -d nextcloud.fsociety.pt --non-interactive --agree-tos -m admin@fsociety.pt
```

### Ativar Site

```bash
# Desativar site padrão
sudo a2dissite 000-default.conf

# Ativar site Nextcloud
sudo a2ensite nextcloud.conf

# Testar configuração
sudo apache2ctl configtest

# Reiniciar Apache
sudo systemctl restart apache2
```

---

## 🖥️ Instalação Web do Nextcloud

### Aceder ao Instalador Web

1. Abrir browser e navegar para: `https://nextcloud.fsociety.pt`
2. Será apresentado o assistente de instalação

### Preencher Formulário

```
Criar conta de administrador:
  Username: admin
  Password: [Strong Password]

Configurar base de dados:
  Base de dados: PostgreSQL
  Utilizador: nextcloud
  Password: [password definida anteriormente]
  Nome da BD: nextcloud
  Host: localhost:5432

Diretório de dados:
  /mnt/data
```

### Aguardar Instalação

O processo pode demorar alguns minutos. Aguardar conclusão.

---

## ✅ Verificação

### Testar Acesso Web

```bash
# Verificar se o site responde
curl -I https://nextcloud.fsociety.pt

# Deve retornar HTTP/2 200
```

### Verificar Serviços

```bash
# Apache
sudo systemctl status apache2

# PHP-FPM
sudo systemctl status php8.3-fpm

# PostgreSQL
sudo systemctl status postgresql

# Redis
sudo systemctl status redis-server
```

### Verificar Logs

```bash
# Logs Apache
sudo tail -f /var/log/apache2/nextcloud_error.log

# Logs Nextcloud
sudo tail -f /var/www/nextcloud/data/nextcloud.log

# Logs PHP-FPM
sudo tail -f /var/log/php8.3-fpm.log
```

### Testar Comandos OCC

```bash
# Verificar status do Nextcloud
sudo -u www-data php /var/www/nextcloud/occ status

# Listar apps instaladas
sudo -u www-data php /var/www/nextcloud/occ app:list
```

---

## 📝 Checklist Pós-Instalação

- [x] Apache instalado e configurado
- [x] PHP 8.3 com todas as extensões
- [x] PostgreSQL com base de dados criada
- [x] Redis configurado com socket Unix
- [x] Nextcloud extraído para /var/www/nextcloud
- [x] Permissões corretas (www-data)
- [x] VirtualHost Apache configurado
- [x] SSL/TLS com Let's Encrypt
- [x] Instalação web concluída
- [x] Acesso funcionando via HTTPS

---

## 📖 Referências

- [Nextcloud Installation Guide](https://docs.nextcloud.com/server/latest/admin_manual/installation/)
- [Nextcloud Apache Configuration](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html#apache-configuration)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

<div align="center">

**[⬅️ Voltar: Instalação](01-instalacao.md)** | **[Próximo: Configuração Nextcloud ➡️](03-nextcloud-config.md)**

</div>

---

*Última atualização: Dezembro 2024*
