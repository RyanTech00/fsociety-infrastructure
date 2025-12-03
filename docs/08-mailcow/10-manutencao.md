# 🔧 Manutenção

> **Procedimentos de atualização, monitorização e troubleshooting do Mailcow**

---

## 📋 Índice

1. [Atualizações](#-atualizações)
2. [Logs e Monitorização](#-logs-e-monitorização)
3. [Comandos Úteis](#-comandos-úteis)
4. [Performance e Otimização](#-performance-e-otimização)
5. [Troubleshooting](#-troubleshooting)
6. [Tarefas de Manutenção](#-tarefas-de-manutenção)

---

## 🔄 Atualizações

### Atualizar Mailcow

O Mailcow inclui um script automático de atualização:

```bash
cd /opt/mailcow-dockerized

# Executar script de update
sudo ./update.sh
```

**O script:**
1. Verifica versão atual vs. disponível
2. Faz backup automático
3. Atualiza imagens Docker
4. Atualiza configurações
5. Reinicia containers

### Processo de Atualização

```
┌─────────────────────────────────────┐
│  1. Verificar atualizações          │
│     (git fetch origin)              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Backup automático                │
│     (mailcow.conf + docker-compose)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. Pull novas imagens               │
│     (docker compose pull)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. Restart containers               │
│     (docker compose up -d)           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  5. Verificar health                 │
│     (docker compose ps)              │
└─────────────────────────────────────┘
```

### Atualização Manual

```bash
cd /opt/mailcow-dockerized

# 1. Backup manual (recomendado)
sudo /usr/local/bin/mailcow-backup.sh

# 2. Parar containers
sudo docker compose down

# 3. Atualizar código
sudo git pull

# 4. Pull novas imagens
sudo docker compose pull

# 5. Iniciar
sudo docker compose up -d

# 6. Verificar
sudo docker compose ps
sudo docker compose logs --tail=50
```

### Verificar Versão Atual

```bash
# Ver versão instalada
cd /opt/mailcow-dockerized
git log --oneline -1

# Ver versões das imagens
sudo docker images | grep mailcow
```

### Changelog

```bash
# Ver mudanças desde última atualização
git log --oneline --since="1 month ago"

# Ver detalhes de commit específico
git show <commit_hash>
```

### Rollback de Atualização

Se atualização causar problemas:

```bash
cd /opt/mailcow-dockerized

# Ver commits recentes
git log --oneline -5

# Voltar para commit anterior
sudo docker compose down
sudo git reset --hard <commit_anterior>
sudo docker compose pull
sudo docker compose up -d
```

---

## 📊 Logs e Monitorização

### Ver Logs de Todos os Containers

```bash
cd /opt/mailcow-dockerized

# Todos os logs (últimas 100 linhas)
sudo docker compose logs --tail=100

# Seguir logs em tempo real
sudo docker compose logs -f

# Logs de container específico
sudo docker compose logs -f postfix-mailcow
```

### Logs por Container

```bash
# Postfix (SMTP)
sudo docker compose logs postfix-mailcow --tail=50

# Dovecot (IMAP/POP3)
sudo docker compose logs dovecot-mailcow --tail=50

# Rspamd (Anti-spam)
sudo docker compose logs rspamd-mailcow --tail=50

# Nginx (Web/Proxy)
sudo docker compose logs nginx-mailcow --tail=50

# MySQL
sudo docker compose logs mysql-mailcow --tail=50

# SOGo (Webmail)
sudo docker compose logs sogo-mailcow --tail=50
```

### Filtrar Logs

```bash
# Procurar por email específico
sudo docker compose logs | grep "ryan.barbosa@fsociety.pt"

# Procurar por erros
sudo docker compose logs | grep -i error

# Procurar por rejeições
sudo docker compose logs postfix-mailcow | grep "reject"

# Ver apenas hoje
sudo docker compose logs --since="$(date +%Y-%m-%d)T00:00:00"
```

### Logs do Sistema

```bash
# Ver logs do journald
sudo journalctl -u docker -f

# Ver logs específicos do Mailcow
sudo journalctl -u docker | grep mailcow
```

### Monitorização via Watchdog

O Watchdog monitoriza automaticamente todos os serviços:

```bash
# Ver status via API
curl -s https://mail.fsociety.pt/api/v1/get/status/containers \
  -H "X-API-Key: <api_key>" | jq

# Via Web UI
# https://mail.fsociety.pt → System → Containers
```

---

## 💻 Comandos Úteis

### Docker Compose

```bash
cd /opt/mailcow-dockerized

# Ver status de todos os containers
sudo docker compose ps

# Iniciar todos os containers
sudo docker compose up -d

# Parar todos os containers
sudo docker compose down

# Reiniciar serviço específico
sudo docker compose restart postfix-mailcow

# Reiniciar todos
sudo docker compose restart

# Remover e recriar (perde dados temporários)
sudo docker compose down
sudo docker compose up -d
```

### Entrar em Container

```bash
# Shell interativo
sudo docker compose exec postfix-mailcow /bin/bash

# Executar comando direto
sudo docker compose exec postfix-mailcow postconf mail_version

# Como root
sudo docker compose exec -u root nginx-mailcow /bin/sh
```

### Ver Recursos

```bash
# Uso de CPU/RAM por container
sudo docker stats

# Uso específico
sudo docker stats mailcowdockerized-postfix-mailcow-1

# Disco usado
sudo du -sh /opt/mailcow-dockerized/data/*
```

### Limpar Recursos

```bash
# Remover imagens antigas
sudo docker image prune -a

# Remover volumes não usados
sudo docker volume prune

# Limpar tudo (CUIDADO!)
sudo docker system prune -a
```

---

## ⚡ Performance e Otimização

### Verificar Performance

```bash
# CPU e memória
sudo docker stats --no-stream

# Uso de disco
df -h /opt/mailcow-dockerized/

# IOPS disco
sudo iostat -x 1
```

### Otimizações MySQL

```bash
# Aceder ao MySQL
sudo docker compose exec mysql-mailcow mysql -u root -p

# Ver status
SHOW GLOBAL STATUS;

# Ver variáveis
SHOW VARIABLES LIKE '%buffer%';
```

**Otimizar em docker-compose.override.yml:**

```yaml
version: '2.1'
services:
  mysql-mailcow:
    environment:
      - MYSQL_INNODB_BUFFER_POOL_SIZE=512M
      - MYSQL_INNODB_LOG_FILE_SIZE=64M
```

### Otimizações Redis

```bash
# Verificar uso de memória
sudo docker compose exec redis-mailcow redis-cli info memory

# Ver chaves em uso
sudo docker compose exec redis-mailcow redis-cli dbsize
```

### Limpar Emails Antigos

```bash
# Remover emails com mais de 90 dias da Trash
sudo docker compose exec dovecot-mailcow \
  doveadm expunge -A mailbox Trash savedbefore 90d

# Remover spam antigo
sudo docker compose exec dovecot-mailcow \
  doveadm expunge -A mailbox Junk savedbefore 30d
```

### Limpar Logs Antigos

```bash
# Rotacionar logs do Docker
sudo docker compose logs > /dev/null

# Limpar logs do sistema
sudo journalctl --vacuum-time=7d
```

---

## 🔍 Troubleshooting

### Container Não Inicia

```bash
# Ver erro específico
sudo docker compose ps
sudo docker compose logs <container-name>

# Tentar iniciar manualmente
sudo docker compose up <container-name>

# Verificar porta em uso
sudo ss -tlnp | grep <porta>
```

### Emails Não São Recebidos

**Checklist:**
1. Verificar Postfix:
   ```bash
   sudo docker compose logs postfix-mailcow | grep reject
   ```

2. Verificar DNS:
   ```bash
   dig fsociety.pt MX +short
   ```

3. Verificar portas abertas:
   ```bash
   sudo ss -tlnp | grep -E ':(25|465|587)'
   ```

4. Testar SMTP:
   ```bash
   telnet mail.fsociety.pt 25
   ```

### Emails Não São Enviados

```bash
# Ver queue do Postfix
sudo docker compose exec postfix-mailcow postqueue -p

# Ver deferred messages
sudo docker compose exec postfix-mailcow mailq

# Forçar reenvio
sudo docker compose exec postfix-mailcow postqueue -f
```

### Webmail Não Abre

```bash
# Verificar Nginx
sudo docker compose logs nginx-mailcow

# Verificar SOGo
sudo docker compose logs sogo-mailcow

# Verificar certificado SSL
openssl s_client -connect mail.fsociety.pt:443
```

### Database Corruption

```bash
# Verificar tabelas
sudo docker compose exec mysql-mailcow mysqlcheck -u root -p --all-databases

# Reparar tabelas
sudo docker compose exec mysql-mailcow mysqlcheck -u root -p --all-databases --repair
```

### Out of Memory

```bash
# Ver containers com mais RAM
sudo docker stats --no-stream --format "table {% raw %}{{.Name}}\t{{.MemUsage}}{% endraw %}" | sort -k2 -h

# Aumentar swap (temporário)
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📅 Tarefas de Manutenção

### Diárias

- [ ] Verificar logs de erro
- [ ] Verificar disk usage
- [ ] Verificar queue do Postfix

```bash
#!/bin/bash
# Script de check diário

echo "=== Mailcow Daily Check ==="
echo "Date: $(date)"

echo -e "\n--- Container Status ---"
docker compose ps

echo -e "\n--- Disk Usage ---"
df -h /opt/mailcow-dockerized/

echo -e "\n--- Mail Queue ---"
docker compose exec postfix-mailcow postqueue -p | tail -1

echo -e "\n--- Errors (last hour) ---"
docker compose logs --since=1h | grep -i error | wc -l
```

### Semanais

- [ ] Atualizar Mailcow
- [ ] Verificar backups
- [ ] Limpar logs antigos
- [ ] Verificar certificados SSL

```bash
#!/bin/bash
# Script de manutenção semanal

# Update
cd /opt/mailcow-dockerized
./update.sh

# Verificar SSL
openssl x509 -in data/assets/ssl/cert.pem -noout -dates

# Limpar
docker image prune -f
```

### Mensais

- [ ] Revisar utilizadores e quotas
- [ ] Analisar relatórios DMARC
- [ ] Atualizar documentação
- [ ] Teste de restore de backup

```bash
# Ver quotas
docker compose exec dovecot-mailcow doveadm quota get -A

# Ver uso por utilizador
docker compose exec mysql-mailcow mysql -u mailcow -p mailcow \
  -e "SELECT username, quota, used FROM quota2;"
```

---

## 📞 Suporte

### Recursos Oficiais

- **Documentação:** https://docs.mailcow.email/
- **GitHub:** https://github.com/mailcow/mailcow-dockerized
- **Community:** https://community.mailcow.email/

### Comandos de Diagnóstico

```bash
# Gerar relatório de diagnóstico
cd /opt/mailcow-dockerized
sudo docker compose ps > /tmp/mailcow-report.txt
sudo docker compose logs --tail=200 >> /tmp/mailcow-report.txt
sudo docker stats --no-stream >> /tmp/mailcow-report.txt
```

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

<div align="center">

**[⬅️ Anterior: Integração Zammad](09-integracao-zammad.md)** | **[Índice](README.md)**

</div>

---

*Última atualização: Dezembro 2024*
