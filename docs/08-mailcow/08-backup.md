# 💾 Backup e Restore

> **Estratégias e procedimentos de backup para proteção de dados do Mailcow**

---

## 📋 Índice

1. [Dados a Fazer Backup](#-dados-a-fazer-backup)
2. [Backup dos Dados](#-backup-dos-dados)
3. [Backup da Base de Dados](#-backup-da-base-de-dados)
4. [Scripts de Backup](#-scripts-de-backup)
5. [Backup Automático](#-backup-automático)
6. [Restore de Dados](#-restore-de-dados)
7. [Disaster Recovery](#-disaster-recovery)

---

## 📁 Dados a Fazer Backup

### Estrutura de Diretórios

```
/opt/mailcow-dockerized/
├── mailcow.conf                    # Configuração principal
├── docker-compose.yml              # Composição dos containers
├── docker-compose.override.yml     # Overrides customizados
└── data/
    ├── vmail/                      # Emails (Maildir)
    │   └── fsociety.pt/
    │       ├── ryan.barbosa/
    │       ├── hugo.correia/
    │       └── ...
    ├── dkim/                       # Chaves DKIM
    │   └── fsociety.pt.dkim
    ├── assets/
    │   ├── ssl/                    # Certificados SSL
    │   └── mysql/                  # Backups MySQL automáticos
    ├── conf/
    │   ├── rspamd/                 # Configurações Rspamd
    │   ├── postfix/                # Configurações Postfix
    │   ├── dovecot/                # Configurações Dovecot
    │   └── sogo/                   # Configurações SOGo
    └── redis/                      # Dados Redis (cache)
```

### Prioridades de Backup

| Diretório | Prioridade | Tamanho Estimado | Frequência |
|-----------|------------|------------------|------------|
| **vmail/** | 🔴 Crítico | ~10-50 GB | Diário |
| **MySQL DB** | 🔴 Crítico | ~500 MB | Diário |
| **dkim/** | 🟠 Alto | ~10 KB | Semanal |
| **mailcow.conf** | 🟠 Alto | ~5 KB | Após alterações |
| **conf/** | 🟠 Alto | ~50 MB | Semanal |
| **assets/ssl/** | 🟡 Médio | ~10 KB | Mensal |
| **redis/** | 🟢 Baixo | ~100 MB | Não necessário (cache) |

---

## 📦 Backup dos Dados

### Backup Manual Completo

```bash
#!/bin/bash
# Backup completo do Mailcow

BACKUP_DIR="/backup/mailcow"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/mailcow_backup_$DATE"

# Criar diretório de backup
mkdir -p "$BACKUP_PATH"

# Parar Mailcow (opcional, garante consistência)
cd /opt/mailcow-dockerized
# docker compose down

# Backup de dados
echo "Backing up vmail..."
rsync -avz --progress data/vmail/ "$BACKUP_PATH/vmail/"

echo "Backing up configs..."
rsync -avz --progress data/conf/ "$BACKUP_PATH/conf/"
rsync -avz --progress data/dkim/ "$BACKUP_PATH/dkim/"
rsync -avz --progress data/assets/ssl/ "$BACKUP_PATH/ssl/"

# Backup de configurações
cp mailcow.conf "$BACKUP_PATH/"
cp docker-compose.override.yml "$BACKUP_PATH/" 2>/dev/null

# Backup MySQL
echo "Backing up MySQL..."
docker compose exec -T mysql-mailcow \
  mysqldump --default-character-set=utf8mb4 \
  -u root -p$(grep DBROOT mailcow.conf | cut -d= -f2) \
  --all-databases > "$BACKUP_PATH/mysql_all_databases.sql"

# Reiniciar Mailcow
# docker compose up -d

# Comprimir backup
echo "Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "mailcow_backup_$DATE.tar.gz" "mailcow_backup_$DATE"
rm -rf "mailcow_backup_$DATE"

echo "Backup completo: $BACKUP_DIR/mailcow_backup_$DATE.tar.gz"
```

### Backup Incremental (rsync)

```bash
#!/bin/bash
# Backup incremental usando rsync

BACKUP_DIR="/backup/mailcow"
CURRENT="$BACKUP_DIR/current"
DATE=$(date +%Y%m%d)
SNAPSHOT="$BACKUP_DIR/snapshot_$DATE"

# Criar snapshot usando hardlinks (economiza espaço)
rsync -av --delete --link-dest="$CURRENT" \
  /opt/mailcow-dockerized/data/vmail/ \
  "$SNAPSHOT/"

# Atualizar link "current"
rm -f "$CURRENT"
ln -s "$SNAPSHOT" "$CURRENT"

echo "Backup incremental criado: $SNAPSHOT"
```

---

## 🗄️ Backup da Base de Dados

### Backup MySQL Manual

```bash
# Obter password do root
cd /opt/mailcow-dockerized
MYSQL_ROOT_PASS=$(grep DBROOT mailcow.conf | cut -d= -f2)

# Backup de todas as bases de dados
docker compose exec -T mysql-mailcow \
  mysqldump -u root -p"$MYSQL_ROOT_PASS" \
  --all-databases \
  --single-transaction \
  --quick \
  --lock-tables=false \
  > /backup/mysql_backup_$(date +%Y%m%d).sql

# Comprimir
gzip /backup/mysql_backup_$(date +%Y%m%d).sql
```

### Backup Apenas da Base Mailcow

```bash
# Backup específico da base mailcow
docker compose exec -T mysql-mailcow \
  mysqldump -u root -p"$MYSQL_ROOT_PASS" \
  --databases mailcow \
  --single-transaction \
  > /backup/mailcow_db_$(date +%Y%m%d).sql
```

### Backup Automático via Mailcow

O Mailcow tem backups automáticos configurados:

```bash
# Localização dos backups automáticos
ls -lh /opt/mailcow-dockerized/data/assets/mysql/

# Backups diários são criados automaticamente
# Retenção: 7 dias (padrão)
```

---

## 📝 Scripts de Backup

### Script Completo de Backup

```bash
#!/bin/bash
# /usr/local/bin/mailcow-backup.sh

set -e

# Configurações
MAILCOW_DIR="/opt/mailcow-dockerized"
BACKUP_BASE="/backup/mailcow"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
LOG_FILE="/var/log/mailcow-backup.log"

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Iniciando backup do Mailcow..."

# Criar diretório de backup
BACKUP_DIR="$BACKUP_BASE/$DATE"
mkdir -p "$BACKUP_DIR"

# Obter password MySQL
cd "$MAILCOW_DIR"
MYSQL_ROOT_PASS=$(grep DBROOT mailcow.conf | cut -d= -f2)

# 1. Backup MySQL
log "Backup da base de dados MySQL..."
docker compose exec -T mysql-mailcow \
  mysqldump -u root -p"$MYSQL_ROOT_PASS" \
  --all-databases \
  --single-transaction \
  --quick \
  --lock-tables=false \
  | gzip > "$BACKUP_DIR/mysql_all.sql.gz"

# 2. Backup vmail (emails)
log "Backup dos emails (vmail)..."
rsync -az --info=progress2 \
  "$MAILCOW_DIR/data/vmail/" \
  "$BACKUP_DIR/vmail/"

# 3. Backup configurações
log "Backup das configurações..."
cp "$MAILCOW_DIR/mailcow.conf" "$BACKUP_DIR/"
[ -f "$MAILCOW_DIR/docker-compose.override.yml" ] && \
  cp "$MAILCOW_DIR/docker-compose.override.yml" "$BACKUP_DIR/"

# 4. Backup DKIM keys
log "Backup das chaves DKIM..."
rsync -az "$MAILCOW_DIR/data/dkim/" "$BACKUP_DIR/dkim/"

# 5. Backup Rspamd configs
log "Backup das configurações Rspamd..."
rsync -az "$MAILCOW_DIR/data/conf/rspamd/" "$BACKUP_DIR/rspamd/"

# 6. Backup SSL certificates
log "Backup dos certificados SSL..."
rsync -az "$MAILCOW_DIR/data/assets/ssl/" "$BACKUP_DIR/ssl/"

# Comprimir backup
log "Comprimindo backup..."
cd "$BACKUP_BASE"
tar -czf "${DATE}.tar.gz" "$DATE" --remove-files

# Limpar backups antigos
log "Limpando backups com mais de $RETENTION_DAYS dias..."
find "$BACKUP_BASE" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

# Calcular tamanho
BACKUP_SIZE=$(du -sh "$BACKUP_BASE/${DATE}.tar.gz" | cut -f1)
log "Backup concluído: ${DATE}.tar.gz ($BACKUP_SIZE)"

# Verificar integridade
log "Verificando integridade do backup..."
tar -tzf "$BACKUP_BASE/${DATE}.tar.gz" > /dev/null && \
  log "Integridade verificada: OK" || \
  log "ERRO: Falha na verificação de integridade"

log "Backup finalizado com sucesso!"
```

### Tornar Script Executável

```bash
# Copiar script
sudo nano /usr/local/bin/mailcow-backup.sh
# (colar conteúdo do script acima)

# Tornar executável
sudo chmod +x /usr/local/bin/mailcow-backup.sh

# Testar
sudo /usr/local/bin/mailcow-backup.sh
```

---

## ⏰ Backup Automático

### Configurar Cron

```bash
# Editar crontab do root
sudo crontab -e
```

**Adicionar linha:**
```bash
# Backup diário às 02:00
0 2 * * * /usr/local/bin/mailcow-backup.sh >> /var/log/mailcow-backup.log 2>&1

# Backup semanal completo aos domingos às 03:00
0 3 * * 0 /usr/local/bin/mailcow-backup-full.sh >> /var/log/mailcow-backup.log 2>&1
```

### Verificar Cron

```bash
# Listar tarefas agendadas
sudo crontab -l

# Ver log de execução
tail -f /var/log/mailcow-backup.log
```

### Notificação por Email

Adicionar ao script:

```bash
# No final do script
ADMIN_EMAIL="ryan.barbosa@fsociety.pt"
SUBJECT="Backup Mailcow $(hostname) - $DATE"

if [ $? -eq 0 ]; then
    echo "Backup concluído com sucesso em $(date)" | \
      mail -s "$SUBJECT - OK" "$ADMIN_EMAIL"
else
    echo "ERRO no backup em $(date)" | \
      mail -s "$SUBJECT - FALHOU" "$ADMIN_EMAIL"
fi
```

---

## ♻️ Restore de Dados

### Restore Completo

```bash
#!/bin/bash
# Script de restore completo

BACKUP_FILE="/backup/mailcow/20251203_020000.tar.gz"
RESTORE_DIR="/tmp/mailcow_restore"
MAILCOW_DIR="/opt/mailcow-dockerized"

# Extrair backup
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

cd "$MAILCOW_DIR"

# Parar Mailcow
echo "Parando Mailcow..."
docker compose down

# Restaurar vmail
echo "Restaurando emails..."
rsync -av --delete "$RESTORE_DIR/*/vmail/" "$MAILCOW_DIR/data/vmail/"

# Restaurar configurações
echo "Restaurando configurações..."
cp "$RESTORE_DIR/*/mailcow.conf" "$MAILCOW_DIR/"
cp "$RESTORE_DIR/*/docker-compose.override.yml" "$MAILCOW_DIR/" 2>/dev/null

# Restaurar DKIM
echo "Restaurando DKIM..."
rsync -av "$RESTORE_DIR/*/dkim/" "$MAILCOW_DIR/data/dkim/"

# Restaurar MySQL
echo "Restaurando MySQL..."
docker compose up -d mysql-mailcow
sleep 10

MYSQL_ROOT_PASS=$(grep DBROOT mailcow.conf | cut -d= -f2)
gunzip < "$RESTORE_DIR/*/mysql_all.sql.gz" | \
  docker compose exec -T mysql-mailcow \
  mysql -u root -p"$MYSQL_ROOT_PASS"

# Iniciar Mailcow
echo "Iniciando Mailcow..."
docker compose up -d

echo "Restore concluído!"
```

### Restore Apenas de Mailbox Específica

```bash
# Restaurar apenas uma conta
BACKUP="/backup/mailcow/20251203/vmail/fsociety.pt/ryan.barbosa"
MAILBOX="/opt/mailcow-dockerized/data/vmail/fsociety.pt/ryan.barbosa"

# Parar Dovecot
docker compose stop dovecot-mailcow

# Restaurar
rsync -av "$BACKUP/" "$MAILBOX/"

# Corrigir permissões
docker compose exec dovecot-mailcow \
  chown -R 5000:5000 /var/vmail/fsociety.pt/ryan.barbosa

# Reiniciar Dovecot
docker compose start dovecot-mailcow

# Reconstruir índices
docker compose exec dovecot-mailcow \
  doveadm force-resync -u ryan.barbosa@fsociety.pt '*'
```

### Restore de Base de Dados

```bash
# Restaurar apenas MySQL
BACKUP_SQL="/backup/mysql_backup_20251203.sql.gz"

cd /opt/mailcow-dockerized
MYSQL_ROOT_PASS=$(grep DBROOT mailcow.conf | cut -d= -f2)

# Parar containers que usam MySQL
docker compose stop postfix-mailcow dovecot-mailcow sogo-mailcow

# Restaurar
gunzip < "$BACKUP_SQL" | \
  docker compose exec -T mysql-mailcow \
  mysql -u root -p"$MYSQL_ROOT_PASS"

# Reiniciar
docker compose start postfix-mailcow dovecot-mailcow sogo-mailcow
```

---

## 🚨 Disaster Recovery

### Cenário: Perda Completa do Servidor

1. **Preparar novo servidor:**
   - Instalar Ubuntu/Debian
   - Instalar Docker e Docker Compose
   - Configurar rede (mesmo IP se possível)

2. **Instalar Mailcow:**
   ```bash
   sudo git clone https://github.com/mailcow/mailcow-dockerized /opt/mailcow-dockerized
   cd /opt/mailcow-dockerized
   ```

3. **Restaurar configuração:**
   ```bash
   # Copiar mailcow.conf do backup
   cp /backup/mailcow/latest/mailcow.conf .
   ```

4. **Iniciar containers:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

5. **Restaurar dados:**
   ```bash
   # Seguir procedimento de restore completo
   ```

### Documentação de Recuperação

Manter documentado:
- Localização dos backups
- Passwords críticas (em cofre seguro)
- Procedimentos de restore
- Contactos de emergência
- Configurações de DNS/firewall

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

**[⬅️ Anterior: Registos DNS](07-dns-records.md)** | **[Índice](README.md)** | **[Próximo: Integração Zammad ➡️](09-integracao-zammad.md)**

</div>

---

*Última atualização: Dezembro 2025*
