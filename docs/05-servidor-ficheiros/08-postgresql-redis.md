# 🐘 PostgreSQL e Redis

> **Configuração e gestão das bases de dados PostgreSQL e cache Redis**

---

## 📋 Índice

1. [PostgreSQL](#-postgresql)
2. [Redis](#-redis)
3. [Backup e Restore](#-backup-e-restore)
4. [Monitorização](#-monitorização)
5. [Manutenção](#-manutenção)
6. [Referências](#-referências)

---

## 🐘 PostgreSQL

### Informação Geral

| Parâmetro | Valor |
|-----------|-------|
| **Versão** | PostgreSQL 16 |
| **Porta** | 5432 |
| **Bases de Dados** | nextcloud, zammad_production |
| **Utilizadores** | nextcloud, zammad |

### Bases de Dados

#### Nextcloud

```bash
# Aceder à BD
sudo -u postgres psql nextcloud

# Ver tabelas
\dt

# Ver tamanho da BD
SELECT pg_size_pretty(pg_database_size('nextcloud'));

# Sair
\q
```

#### Zammad

```bash
# Aceder à BD
sudo -u postgres psql zammad_production

# Ver tabelas
\dt

# Ver tamanho
SELECT pg_size_pretty(pg_database_size('zammad_production'));
```

### Configuração PostgreSQL

Ficheiro: `/etc/postgresql/16/main/postgresql.conf`

```conf
# Memória
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 4MB

# WAL
wal_buffers = 8MB
checkpoint_completion_target = 0.9

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d.log'
log_line_prefix = '%m [%p] %u@%d '
log_timezone = 'Europe/Lisbon'
```

### Otimizações

```bash
# Editar configuração
sudo nano /etc/postgresql/16/main/postgresql.conf

# Reiniciar
sudo systemctl restart postgresql
```

### Verificar Conexões

```bash
# Ver conexões ativas
sudo -u postgres psql -c "SELECT datname, usename, application_name, client_addr, state FROM pg_stat_activity;"

# Contar conexões por BD
sudo -u postgres psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

---

## 🔴 Redis

### Informação Geral

| Parâmetro | Valor |
|-----------|-------|
| **Versão** | Redis 7.x |
| **Socket** | /var/run/redis/redis-server.sock |
| **Porta TCP** | 0 (desativada) |
| **Memória Máx** | 128MB |
| **Utilização** | Cache Nextcloud + Sessions |

### Configuração Redis

Ficheiro: `/etc/redis/redis.conf`

```conf
# Socket Unix (melhor performance que TCP)
unixsocket /var/run/redis/redis-server.sock
unixsocketperm 770

# Desativar TCP
port 0

# Memória
maxmemory 128mb
maxmemory-policy allkeys-lru

# Persistência (opcional)
save 900 1
save 300 10
save 60 10000

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
```

### Verificar Redis

```bash
# Status
sudo systemctl status redis-server

# Teste de conexão via socket
redis-cli -s /var/run/redis/redis-server.sock ping

# Deve retornar: PONG
```

### Estatísticas Redis

```bash
# Info geral
redis-cli -s /var/run/redis/redis-server.sock info

# Memória utilizada
redis-cli -s /var/run/redis/redis-server.sock info memory

# Número de keys
redis-cli -s /var/run/redis/redis-server.sock dbsize

# Ver keys (cuidado em produção!)
redis-cli -s /var/run/redis/redis-server.sock keys '*' | head -20
```

### Limpar Cache

```bash
# CUIDADO: Limpa TODAS as keys
redis-cli -s /var/run/redis/redis-server.sock FLUSHALL

# Limpar apenas DB 0
redis-cli -s /var/run/redis/redis-server.sock -n 0 FLUSHDB
```

---

## 💾 Backup e Restore

### Backup PostgreSQL

#### Backup Manual

```bash
# Backup Nextcloud
sudo -u postgres pg_dump nextcloud > /tmp/nextcloud_backup_$(date +%Y%m%d).sql

# Backup Zammad
sudo -u postgres pg_dump zammad_production > /tmp/zammad_backup_$(date +%Y%m%d).sql

# Backup comprimido
sudo -u postgres pg_dump nextcloud | gzip > /tmp/nextcloud_backup_$(date +%Y%m%d).sql.gz
```

#### Restore

```bash
# Restore Nextcloud
sudo -u postgres psql nextcloud < /tmp/nextcloud_backup_20241203.sql

# Restore Zammad
sudo -u postgres psql zammad_production < /tmp/zammad_backup_20241203.sql

# Restore de .gz
gunzip < /tmp/nextcloud_backup_20241203.sql.gz | sudo -u postgres psql nextcloud
```

#### Backup Automático (Cron)

```bash
# Criar script de backup
sudo nano /usr/local/bin/backup-databases.sh
```

Conteúdo:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup Nextcloud
sudo -u postgres pg_dump nextcloud | gzip > $BACKUP_DIR/nextcloud_$DATE.sql.gz

# Backup Zammad
sudo -u postgres pg_dump zammad_production | gzip > $BACKUP_DIR/zammad_$DATE.sql.gz

# Manter apenas últimos 7 dias
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup concluído: $DATE"
```

Tornar executável e agendar:

```bash
sudo chmod +x /usr/local/bin/backup-databases.sh

# Adicionar ao cron (diariamente às 2h)
sudo crontab -e

# Adicionar linha:
0 2 * * * /usr/local/bin/backup-databases.sh >> /var/log/db-backup.log 2>&1
```

### Backup Redis

```bash
# Forçar save
redis-cli -s /var/run/redis/redis-server.sock BGSAVE

# Copiar dump
sudo cp /var/lib/redis/dump.rdb /tmp/redis_backup_$(date +%Y%m%d).rdb
```

---

## 📊 Monitorização

### PostgreSQL

#### Tamanho das Bases de Dados

```bash
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC;"
```

#### Top Tabelas (por tamanho)

```bash
# Nextcloud
sudo -u postgres psql nextcloud -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"
```

#### Conexões Ativas

```bash
sudo -u postgres psql -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

#### Slow Queries

```bash
# Ver queries lentas (> 1 segundo)
sudo -u postgres psql -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '1 second' ORDER BY duration DESC;"
```

### Redis

#### Uso de Memória

```bash
redis-cli -s /var/run/redis/redis-server.sock info memory | grep used_memory_human
```

#### Hit Rate

```bash
redis-cli -s /var/run/redis/redis-server.sock info stats | grep keyspace
```

---

## 🔧 Manutenção

### PostgreSQL

#### VACUUM

```bash
# VACUUM Nextcloud (limpeza de espaço)
sudo -u postgres psql nextcloud -c "VACUUM VERBOSE;"

# VACUUM ANALYZE (atualiza estatísticas)
sudo -u postgres psql nextcloud -c "VACUUM ANALYZE;"

# VACUUM FULL (reescreve tabelas, mais agressivo)
sudo -u postgres psql nextcloud -c "VACUUM FULL VERBOSE;"
```

#### REINDEX

```bash
# Reindexar BD Nextcloud
sudo -u postgres psql nextcloud -c "REINDEX DATABASE nextcloud;"

# Reindexar tabela específica
sudo -u postgres psql nextcloud -c "REINDEX TABLE oc_filecache;"
```

#### Autovacuum

Verificar se está ativo:

```bash
sudo -u postgres psql -c "SHOW autovacuum;"
```

Deve estar `on` por defeito.

### Redis

#### Monitorizar em Tempo Real

```bash
# Ver comandos em tempo real
redis-cli -s /var/run/redis/redis-server.sock monitor

# Stats
redis-cli -s /var/run/redis/redis-server.sock --stat
```

#### Restart Redis

```bash
sudo systemctl restart redis-server
```

---

## 🚨 Troubleshooting

### PostgreSQL

#### Erro "too many connections"

```bash
# Ver max_connections atual
sudo -u postgres psql -c "SHOW max_connections;"

# Aumentar (editar postgresql.conf)
sudo nano /etc/postgresql/16/main/postgresql.conf

# Alterar:
max_connections = 200

# Reiniciar
sudo systemctl restart postgresql
```

#### Bloqueios (Locks)

```bash
# Ver locks ativos
sudo -u postgres psql -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Matar query específica
sudo -u postgres psql -c "SELECT pg_terminate_backend(PID);"
```

### Redis

#### Memória cheia

```bash
# Ver memória usada
redis-cli -s /var/run/redis/redis-server.sock info memory

# Aumentar maxmemory
sudo nano /etc/redis/redis.conf

# Alterar:
maxmemory 256mb

# Reiniciar
sudo systemctl restart redis-server
```

---

## 📝 Checklist

- [x] PostgreSQL 16 instalado e a correr
- [x] Bases de dados nextcloud e zammad_production criadas
- [x] Redis configurado com socket Unix
- [x] Redis a correr sem erros
- [x] Backup automático configurado
- [x] Monitorização configurada
- [x] Logs a funcionar

---

## 📖 Referências

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Redis Documentation](https://redis.io/docs/)
- [Redis Best Practices](https://redis.io/docs/management/optimization/)

---

<div align="center">

**[⬅️ Voltar: Zammad Nginx](07-zammad-nginx.md)** | **[Próximo: CrowdSec ➡️](09-crowdsec.md)**

</div>

---

*Última atualização: Dezembro 2025*
