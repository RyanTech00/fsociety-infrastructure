# 🎫 Zammad - Instalação

> **Guia completo de instalação do Zammad 6.5.2 - Sistema de Ticketing**

---

## 📋 Índice

1. [Pré-requisitos](#-pré-requisitos)
2. [Instalação via Script Oficial](#-instalação-via-script-oficial)
3. [Configuração da Base de Dados](#-configuração-da-base-de-dados)
4. [Systemd Services](#-systemd-services)
5. [Configuração Inicial](#-configuração-inicial)
6. [Verificação](#-verificação)
7. [Referências](#-referências)

---

## 📦 Pré-requisitos

### Pacotes Base

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y \
  curl \
  wget \
  apt-transport-https \
  ca-certificates \
  gnupg
```

### PostgreSQL

Zammad utiliza a mesma instância PostgreSQL do Nextcloud:

```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Criar base de dados para Zammad
sudo -u postgres psql
```

SQL:

```sql
CREATE USER zammad WITH PASSWORD 'strong_zammad_password';
CREATE DATABASE zammad_production WITH OWNER zammad ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE zammad_production TO zammad;
\q
```

---

## 📥 Instalação via Script Oficial

### Adicionar Repositório Zammad

```bash
# Download do script de instalação
wget -qO- https://dl.packager.io/srv/zammad/zammad/key | sudo gpg --dearmor -o /etc/apt/keyrings/pkgr-zammad.gpg

# Adicionar repositório
echo "deb [signed-by=/etc/apt/keyrings/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/ubuntu 24.04 main"| sudo tee /etc/apt/sources.list.d/zammad.list > /dev/null
```

### Instalar Zammad

```bash
# Atualizar lista de pacotes
sudo apt update

# Instalar Zammad
sudo apt install -y zammad

# Versão esperada: 6.5.2
```

### Configuração Automática

O instalador configura automaticamente:
- Utilizador `zammad`
- Diretório `/opt/zammad`
- Serviços systemd
- Dependências Ruby e Node.js

---

## 🐘 Configuração da Base de Dados

### Editar Configuração

```bash
sudo nano /opt/zammad/config/database.yml
```

Conteúdo:

```yaml
production:
  adapter: postgresql
  database: zammad_production
  pool: 50
  timeout: 5000
  encoding: utf8
  host: localhost
  port: 5432
  username: zammad
  password: strong_zammad_password
```

### Aplicar Permissões

```bash
sudo chown zammad:zammad /opt/zammad/config/database.yml
sudo chmod 640 /opt/zammad/config/database.yml
```

### Inicializar Base de Dados

```bash
# Executar migrations como utilizador zammad
sudo -u zammad bash -c "cd /opt/zammad && RAILS_ENV=production bundle exec rake db:migrate"

# Seed inicial (primeira vez)
sudo -u zammad bash -c "cd /opt/zammad && RAILS_ENV=production bundle exec rake db:seed"
```

---

## ⚙️ Systemd Services

### Serviços Zammad

O Zammad utiliza 4 serviços systemd:

#### 1. zammad.service (Master)

```bash
sudo systemctl status zammad.service
```

Controla todos os sub-serviços.

#### 2. zammad-web.service (Puma)

```bash
sudo systemctl status zammad-web.service
```

Servidor web Puma na porta **9292**.

Ficheiro: `/etc/systemd/system/zammad-web.service`

```ini
[Unit]
Description=Zammad web server
After=postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=zammad
Group=zammad
WorkingDirectory=/opt/zammad
Environment=RAILS_ENV=production
Environment=PORT=9292
ExecStart=/usr/bin/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

#### 3. zammad-websocket.service

```bash
sudo systemctl status zammad-websocket.service
```

WebSocket server na porta **6042**.

#### 4. zammad-worker.service

```bash
sudo systemctl status zammad-worker.service
```

Background jobs e tarefas assíncronas.

### Ativar e Iniciar Serviços

```bash
# Ativar todos os serviços
sudo systemctl enable zammad.service
sudo systemctl enable zammad-web.service
sudo systemctl enable zammad-websocket.service
sudo systemctl enable zammad-worker.service

# Iniciar serviços
sudo systemctl start zammad.service

# Verificar status
sudo systemctl status zammad.service
```

### Reiniciar Serviços

```bash
# Reiniciar todos
sudo systemctl restart zammad.service

# Reiniciar apenas web
sudo systemctl restart zammad-web.service
```

---

## 🔧 Configuração Inicial

### Portas Utilizadas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| **Puma** | 9292 | Backend Rails |
| **WebSocket** | 6042 | Real-time updates |

### Verificar Portas

```bash
# Ver portas em uso
sudo netstat -tlnp | grep -E '9292|6042'

# Ou com ss
sudo ss -tlnp | grep -E '9292|6042'
```

Expected output:
```
tcp   0  0 127.0.0.1:9292   0.0.0.0:*   LISTEN   1234/puma
tcp   0  0 127.0.0.1:6042   0.0.0.0:*   LISTEN   1235/websocket
```

### Wizard de Configuração

**NOTA:** O Zammad será acedido através do Nginx local (porta 8081) configurado no próximo documento.

Ao aceder pela primeira vez a `http://localhost:8081`, será apresentado o wizard:

1. **Admin Account**
   - Nome: Administrator
   - Email: admin@fsociety.pt
   - Password: [Strong Password]

2. **Organization**
   - Name: FSociety
   - URL: https://tickets.fsociety.pt

3. **Email Configuration**
   - Será configurado para usar mail.fsociety.pt

4. **Channels**
   - Email
   - Web Form
   - Chat (opcional)

---

## ✅ Verificação

### Serviços Ativos

```bash
# Status de todos os serviços
sudo systemctl status zammad.service zammad-web.service zammad-websocket.service zammad-worker.service

# Logs
sudo journalctl -u zammad.service -f
sudo journalctl -u zammad-web.service -f
```

### Verificar Processos

```bash
# Processos Zammad
ps aux | grep zammad

# Puma
ps aux | grep puma
```

### Logs do Zammad

```bash
# Production log
sudo tail -f /opt/zammad/log/production.log

# Web log
sudo tail -f /opt/zammad/log/puma_out.log
sudo tail -f /opt/zammad/log/puma_err.log

# WebSocket log
sudo tail -f /opt/zammad/log/websocket-server_out.log
```

### Testar Backend

```bash
# Testar se Puma responde
curl http://localhost:9292

# Deve retornar HTML da aplicação
```

---

## 🔄 Comandos Úteis

### Rails Console

```bash
# Aceder ao console Rails
sudo -u zammad bash -c "cd /opt/zammad && RAILS_ENV=production bundle exec rails console"
```

### Rake Tasks

```bash
# Listar tasks disponíveis
sudo -u zammad bash -c "cd /opt/zammad && RAILS_ENV=production bundle exec rake -T"

# Reindexar search
sudo -u zammad bash -c "cd /opt/zammad && RAILS_ENV=production bundle exec rake searchindex:rebuild"
```

### Backup

```bash
# Backup da base de dados
sudo -u postgres pg_dump zammad_production > /tmp/zammad_backup.sql

# Backup de ficheiros
sudo tar -czf /tmp/zammad_files.tar.gz /opt/zammad/storage
```

---

## 📝 Checklist de Instalação

- [x] PostgreSQL configurado com BD zammad_production
- [x] Repositório Zammad adicionado
- [x] Zammad 6.5.2 instalado
- [x] database.yml configurado
- [x] Migrations executadas
- [x] 4 serviços systemd ativos
- [x] Puma a correr na porta 9292
- [x] WebSocket na porta 6042
- [x] Logs sem erros

---

## 🔗 Próximos Passos

No próximo documento, configuraremos:
- Nginx local (porta 8081)
- Proxy para Puma e WebSocket
- Acesso via tickets.fsociety.pt

---

## 📖 Referências

- [Zammad Documentation](https://docs.zammad.org/)
- [Zammad Installation Guide](https://docs.zammad.org/en/latest/install/ubuntu.html)
- [Zammad System Services](https://docs.zammad.org/en/latest/appendix/systemd.html)

---

<div align="center">

**[⬅️ Voltar: Nextcloud Apps](05-nextcloud-apps.md)** | **[Próximo: Zammad Nginx ➡️](07-zammad-nginx.md)**

</div>

---

*Última atualização: Dezembro 2025*
