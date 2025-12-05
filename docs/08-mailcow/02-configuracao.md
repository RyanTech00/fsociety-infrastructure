# ⚙️ Configuração do Mailcow

> **Guia de configuração avançada do ficheiro mailcow.conf e parâmetros do sistema**

---

## 📋 Índice

1. [Ficheiro mailcow.conf](#-ficheiro-mailcowconf)
2. [Configurações Principais](#-configurações-principais)
3. [SSL/TLS Settings](#-ssltls-settings)
4. [Configurações de Email](#-configurações-de-email)
5. [Base de Dados](#-base-de-dados)
6. [Recursos e Limites](#-recursos-e-limites)
7. [Configurações de Segurança](#-configurações-de-segurança)
8. [Aplicar Alterações](#-aplicar-alterações)

---

## 📄 Ficheiro mailcow.conf

O ficheiro `mailcow.conf` é o coração da configuração do Mailcow. Localiza-se em:

```bash
/opt/mailcow-dockerized/mailcow.conf
```

### Editar Configuração

```bash
cd /opt/mailcow-dockerized
sudo nano mailcow.conf
```

⚠️ **AVISO:** Após editar `mailcow.conf`, é necessário reiniciar os containers:

```bash
sudo docker compose down
sudo docker compose up -d
```

---

## 🔑 Configurações Principais

### Hostname

O hostname **deve** corresponder ao registo DNS público:

```bash
# FQDN do servidor de email
MAILCOW_HOSTNAME=mail.fsociety.pt
```

✅ **Verificar DNS:**
```bash
# Deve retornar o IP público (após NAT)
nslookup mail.fsociety.pt

# Deve retornar mail.fsociety.pt
nslookup 188.81.65.191
```

### Timezone

Define o fuso horário para logs e agendamentos:

```bash
# Timezone de Lisboa
MAILCOW_TZ=Europe/Lisbon
```

**Timezones comuns:**
- `Europe/Lisbon` - Portugal Continental
- `Atlantic/Azores` - Açores (UTC-1)
- `Atlantic/Madeira` - Madeira (UTC)

### Branch do Mailcow

```bash
# master = stable (recomendado)
# nightly = testes (não usar em produção)
MAILCOW_BRANCH=master
```

---

## 🔒 SSL/TLS Settings

### Let's Encrypt Automático

```bash
# Ativar Let's Encrypt
SKIP_LETS_ENCRYPT=n

# Email para notificações de expiração
ACME_CONTACT=admin@fsociety.pt

# Staging (teste) ou produção
# Deixar vazio para produção
LE_STAGING=

# Adicionar SAN (Subject Alternative Names)
ADDITIONAL_SAN=
```

### Configurações de Certificados

```bash
# Certificados ficam em
# /opt/mailcow-dockerized/data/assets/ssl/

# Renovação automática ocorre via container acme-mailcow
# Verifica diariamente e renova se faltarem < 30 dias
```

### Forçar HTTPS

```bash
# Bind IPs
HTTP_PORT=80
HTTPS_PORT=443
HTTP_BIND=0.0.0.0
HTTPS_BIND=0.0.0.0

# Redirect HTTP -> HTTPS (configurado no nginx-mailcow)
```

### Verificar Certificado

```bash
# Ver informação do certificado
sudo docker compose exec nginx-mailcow \
  openssl x509 -in /etc/ssl/mail/cert.pem -text -noout

# Testar SSL/TLS
openssl s_client -connect mail.fsociety.pt:443 -servername mail.fsociety.pt
```

---

## 📧 Configurações de Email

### Diretório de Emails

```bash
# Formato Maildir (padrão)
MAILDIR_SUB=Maildir

# Estrutura: /var/vmail/dominio/utilizador/Maildir/
```

### Limites de Tamanho

```bash
# Tamanho máximo de anexo (em MB)
# Editável também via Web UI
MAILCOW_PASS_SCHEME=BLF-CRYPT
```

**Configurar via docker-compose.override.yml:**

```bash
sudo nano docker-compose.override.yml
```

```yaml
version: '2.1'
services:
  postfix-mailcow:
    environment:
      # Tamanho máximo de mensagem: 50MB
      - MESSAGE_SIZE_LIMIT=52428800
```

### DomainKeys (DKIM)

```bash
# DKIM keys são geradas automaticamente por domínio
# Localização: /opt/mailcow-dockerized/data/dkim/

# Ver chave pública de um domínio
sudo cat data/dkim/fsociety.pt.dkim
```

---

## 🗄️ Base de Dados

### MySQL/MariaDB

```bash
# Nome da base de dados
DBNAME=mailcow

# Utilizador da aplicação
DBUSER=mailcow

# Password do utilizador mailcow (gerada automaticamente)
DBPASS=<senha_gerada>

# Password do root MySQL (gerada automaticamente)
DBROOT=<senha_gerada>

# Porta exposta localmente (NÃO expor externamente)
SQL_PORT=127.0.0.1:13306
```

### Aceder ao MySQL

```bash
# Via container
sudo docker compose exec mysql-mailcow mysql -u root -p

# Via host (porta 13306)
mysql -h 127.0.0.1 -P 13306 -u mailcow -p mailcow
```

### Backup da Base de Dados

```bash
# Backup automático (daily)
# Localização: /opt/mailcow-dockerized/data/assets/mysql/

# Backup manual
sudo docker compose exec mysql-mailcow \
  mysqldump -u root -p mailcow > backup_mailcow_$(date +%F).sql
```

---

## 🔑 Credenciais da Base de Dados

| Campo | Valor |
|-------|-------|
| **User** | mailcow |
| **Database** | mailcow |
| **Porta Local** | 13306 |

### Aceder à Base de Dados

```bash
sudo docker compose exec mysql-mailcow mysql -u mailcow -p mailcow
```

---

## 💾 Redis Cache

```bash
# Porta local do Redis
REDIS_PORT=127.0.0.1:7654

# Usado para:
# - Sessões SOGo
# - Cache Rspamd
# - Rate limiting
```

### Verificar Redis

```bash
# Aceder ao Redis CLI
sudo docker compose exec redis-mailcow redis-cli

# Verificar conexão
redis-cli -h 127.0.0.1 -p 7654 ping
# Resposta: PONG
```

---

## ⚡ Recursos e Limites

### Limites de Memória

Configurar limites para prevenir OOM (Out of Memory):

```bash
sudo nano docker-compose.override.yml
```

```yaml
version: '2.1'
services:
  rspamd-mailcow:
    mem_limit: 1g
  clamd-mailcow:
    mem_limit: 2g
  mysql-mailcow:
    mem_limit: 1g
  sogo-mailcow:
    mem_limit: 512m
```

### Verificar Uso de Recursos

```bash
# Uso de CPU e memória por container
sudo docker stats

# Uso de disco
sudo du -sh /opt/mailcow-dockerized/data/*
```

---

## 🛡️ Configurações de Segurança

### API Keys

```bash
# API key do Mailcow (gerada na Web UI)
# System > Access > API

# Usar para automações e integrações
```

### Fail2ban (Netfilter)

```bash
# Configurado automaticamente no container netfilter-mailcow
# Bans após falhas de autenticação

# Ver bans ativos
sudo docker compose exec netfilter-mailcow iptables -L -n | grep REJECT
```

### Rate Limiting

Configurado no Rspamd para prevenir spam:

```bash
# Ver configuração
sudo docker compose exec rspamd-mailcow \
  rspamadm configdump ratelimit
```

### SPF, DKIM, DMARC

Configurações automáticas após adicionar domínio. Ver detalhes em [07-dns-records.md](07-dns-records.md).

---

## 📮 SMTP Relay - smtp2go

Devido ao IP residencial (188.81.65.191) estar presente em blacklists e à impossibilidade de configurar reverse DNS (ISP Telepac), foi implementado um relay SMTP através do serviço smtp2go.

### Porquê smtp2go?

| Problema | Solução |
|----------|---------|
| ❌ IP residencial em blacklists | ✅ smtp2go tem IPs com boa reputação |
| ❌ rDNS não configurável (ISP) | ✅ smtp2go gere o rDNS |
| ❌ Porta 587 bloqueada pelo ISP | ✅ Usar porta alternativa 2525 |
| ❌ Emails caem em spam | ✅ Entrega fiável |

### Configuração smtp2go

| Campo | Valor |
|-------|-------|
| **Servidor** | mail-eu.smtp2go.com |
| **Porta** | 2525 |
| **Username** | pmg-fsociety |

### Configurar no Mailcow (GUI)

1. Ir a **System → Configuration → Routing**
2. Em **Add transport**, configurar:

| Campo | Valor |
|-------|-------|
| Host | `[mail-eu.smtp2go.com]:2525` |
| Username | pmg-fsociety |
| Password | (password do smtp2go) |

3. Salvar
4. Ir a **E-Mail → Configuration → Domains**
5. Editar domínio `fsociety.pt`
6. Em **Relayhost**, selecionar o transport criado
7. Salvar

### Verificar Configuração

```bash
# Ver relayhost configurado
sudo docker compose exec postfix-mailcow postconf relayhost

# Verificar na base de dados
sudo docker compose exec mysql-mailcow mysql -u mailcow -p mailcow -e "SELECT * FROM relayhosts;"
```

### Resultado Esperado

```
+----+----------------------------+--------------+--------+
| id | hostname                   | username     | active |
+----+----------------------------+--------------+--------+
|  1 | [mail-eu.smtp2go.com]:2525 | pmg-fsociety |      1 |
+----+----------------------------+--------------+--------+
```

---

## 🔐 Identity Provider LDAP Nativo

O Mailcow possui um **Identity Provider LDAP nativo** que permite autenticação e sincronização automática de utilizadores a partir do Active Directory.

### Configuração via Web UI

1. **Aceder ao painel de administração:**
   - URL: https://mail.fsociety.pt/admin
   - Login: `admin`

2. **Navegar para System → Configuration → Identity Provider:**
   - Selecionar **LDAP** como authsource

3. **Preencher parâmetros LDAP:**

| Campo | Valor |
|-------|-------|
| **Host** | 192.168.1.10 |
| **Port** | 636 |
| **Encryption** | SSL/TLS (LDAPS) |
| **Base DN** | DC=fsociety,DC=pt |
| **Bind DN** | CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt |
| **Bind DN Password** | (password da conta svc_ldap) |
| **Username Field** | mail |
| **Filter** | `(&(objectClass=user)(objectCategory=person)(mail=*)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(!(cn=Administrator))(!(cn=Guest))(!(cn=krbtgt))(!(cn=svc_ldap))(!(cn=noreply)))` |
| **Sync Interval** | 15 minutos |
| **Import Users** | ✅ Ativo |
| **Default Template** | Default |

4. **Salvar configuração**

### Comandos de Gestão LDAP

```bash
cd /opt/mailcow-dockerized

# Forçar sincronização manual
docker compose exec php-fpm-mailcow php /crons/ldap-sync.php

# Ver logs de sincronização
docker compose exec redis-mailcow redis-cli -a 'REDIS_PASSWORD' LRANGE CRON_LOG 0 20

# Ver utilizadores LDAP importados
docker compose exec mysql-mailcow mysql -u mailcow -p mailcow \
  -e "SELECT username, name, authsource FROM mailbox WHERE authsource='ldap';"

# Ver container responsável pela sincronização
docker compose ps ofelia-mailcow
```

### Verificar Configuração LDAP

```bash
# Ver parâmetros LDAP configurados
docker compose exec mysql-mailcow mysql -u mailcow -p mailcow \
  -e "SELECT id, active, auth_source FROM domain;"

# Testar conexão LDAP
docker compose exec php-fpm-mailcow php -r "
\$ldap = ldap_connect('ldaps://192.168.1.10:636');
ldap_set_option(\$ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option(\$ldap, LDAP_OPT_X_TLS_REQUIRE_CERT, LDAP_OPT_X_TLS_NEVER);
if (ldap_bind(\$ldap, 'CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt', 'PASSWORD')) {
    echo 'LDAP connection successful\n';
} else {
    echo 'LDAP connection failed\n';
}
"
```

### Filtro LDAP Explicado

O filtro configurado exclui:
- Contas desativadas (userAccountControl bit 2)
- Contas de sistema: Administrator, Guest, krbtgt
- Conta de serviço: svc_ldap
- Conta de sistema: noreply

E importa apenas:
- Utilizadores com `objectClass=user` e `objectCategory=person`
- Utilizadores com atributo `mail` preenchido

### Funcionamento da Sincronização

1. O container `ofelia-mailcow` executa cron jobs
2. O script `/crons/ldap-sync.php` é executado a cada 15 minutos
3. O script consulta o AD usando a conta `svc_ldap`
4. Novos utilizadores são importados com o template "Default"
5. Mailboxes são criadas automaticamente
6. Autenticação ocorre em tempo real contra o AD

---

## 🔄 Aplicar Alterações

### Restart Completo

```bash
cd /opt/mailcow-dockerized

# Parar todos os containers
sudo docker compose down

# Iniciar novamente
sudo docker compose up -d
```

### Restart de Container Específico

```bash
# Reiniciar apenas um serviço
sudo docker compose restart postfix-mailcow

# Múltiplos containers
sudo docker compose restart postfix-mailcow dovecot-mailcow
```

### Verificar Logs Após Alterações

```bash
# Logs de todos os containers
sudo docker compose logs --tail=100 --follow

# Logs de container específico
sudo docker compose logs -f nginx-mailcow
```

---

## 📊 Configurações Avançadas

### IPV6

```bash
# Desativar IPV6 (se não usado)
IPV6_NETWORK=

# Ativar IPV6
IPV6_NETWORK=fd4d:6169:6c63:6f77::/64
```

### Syslog

```bash
# Enviar logs para servidor syslog externo
SYSLOG_ADDRESS=192.168.1.50
SYSLOG_PORT=514
```

### Webmail SOGo

```bash
# Configurações do SOGo
# Ajustar via Web UI: Configuration > Mailboxes
```

---

## 🔍 Troubleshooting

### Verificar Configuração

```bash
# Validar sintaxe
grep -v "^#" mailcow.conf | grep -v "^$"

# Ver variáveis de ambiente ativas
sudo docker compose config
```

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Certificado SSL não gerado | DNS não aponta corretamente | Verificar registos A e PTR |
| Containers crashando | Memória insuficiente | Aumentar RAM da VM |
| Emails não chegam | Portas bloqueadas | Verificar firewall/NAT |
| Slow performance | Disco lento | Mover para SSD/NVMe |

### Reset de Configuração

```bash
# Backup atual
sudo cp mailcow.conf mailcow.conf.backup

# Regenerar (CUIDADO: perde alterações)
sudo ./generate_config.sh
```

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

<div align="center">

**[⬅️ Anterior: Instalação](01-instalacao.md)** | **[Índice](README.md)** | **[Próximo: Domínios e Mailboxes ➡️](03-dominios-mailboxes.md)**

</div>

---

*Última atualização: Dezembro 2025*
