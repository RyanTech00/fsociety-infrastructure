# 🔧 Manutenção do Domain Controller

> **Guia de backup, monitorização e troubleshooting do Domain Controller**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Backup do Samba AD](#-backup-do-samba-ad)
3. [Monitorização com Netdata](#-monitorização-com-netdata)
4. [Troubleshooting Comum](#-troubleshooting-comum)
5. [Comandos Úteis](#-comandos-úteis)
6. [Atualizações e Upgrades](#-atualizações-e-upgrades)
7. [Recuperação de Desastres](#-recuperação-de-desastres)
8. [Referências](#-referências)

---

## 📖 Visão Geral

### Tarefas de Manutenção

| Tarefa | Frequência | Descrição |
|--------|------------|-----------|
| Backup AD | Diário | Backup da base de dados do AD |
| Verificação de logs | Diário | Análise de erros e alertas |
| Atualização de sistema | Semanal | Patches de segurança |
| Verificação de replicação | Semanal | (Se houver múltiplos DCs) |
| Limpeza de contas | Mensal | Remover contas inativas |
| Teste de restore | Trimestral | Validar backups |

---

## 💾 Backup do Samba AD

### Estratégia de Backup

```
┌─────────────────────────────────────────────────────────────┐
│                    BACKUP STRATEGY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   DIÁRIO    │    │   SEMANAL   │    │   MENSAL    │     │
│  │  (7 dias)   │    │  (4 semanas)│    │  (12 meses) │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              /backup/samba-ad/                       │   │
│  │  ├── daily/                                          │   │
│  │  ├── weekly/                                         │   │
│  │  └── monthly/                                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Script de Backup

**Ficheiro:** `/usr/local/bin/backup-samba-ad.sh`

```bash
#!/bin/bash
#===============================================================================
# Backup Script for Samba AD DC
# Domain: fsociety.pt
# Server: dc.fsociety.pt
#===============================================================================

# Configurações
BACKUP_DIR="/backup/samba-ad"
DATE=$(date +%Y%m%d_%H%M%S)
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)
RETENTION_DAILY=7
RETENTION_WEEKLY=4
RETENTION_MONTHLY=12

# Diretórios
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"

# Criar estrutura
mkdir -p $DAILY_DIR $WEEKLY_DIR $MONTHLY_DIR

# Logging
LOG_FILE="/var/log/samba-backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "=========================================="
log "Iniciando backup do Samba AD DC"
log "=========================================="

# Verificar se o Samba está em execução
if ! systemctl is-active --quiet samba-ad-dc; then
    log "ERRO: Samba AD DC não está em execução!"
    exit 1
fi

# Backup usando samba-tool
log "Executando samba-tool domain backup online..."
BACKUP_FILE="$DAILY_DIR/samba-ad-backup-$DATE.tar.bz2"

sudo samba-tool domain backup online \
    --targetdir="$DAILY_DIR" \
    --server=localhost \
    -U Administrator%'P@ssw0rd123!'

if [ $? -eq 0 ]; then
    log "Backup criado com sucesso: $BACKUP_FILE"
else
    log "ERRO: Falha ao criar backup!"
    exit 1
fi

# Backup adicional de ficheiros de configuração
log "Backup de configurações..."
CONFIG_BACKUP="$DAILY_DIR/samba-config-$DATE.tar.gz"
tar -czf $CONFIG_BACKUP \
    /etc/samba/smb.conf \
    /etc/krb5.conf \
    /etc/dhcp/dhcpd.conf \
    /etc/freeradius/3.0/ \
    /etc/crowdsec/ \
    2>/dev/null

log "Configurações guardadas em: $CONFIG_BACKUP"

# Rotação - Backup Semanal (Domingo)
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    log "Criando backup semanal..."
    cp $BACKUP_FILE "$WEEKLY_DIR/samba-ad-weekly-$DATE.tar.bz2"
fi

# Rotação - Backup Mensal (Dia 1)
if [ "$DAY_OF_MONTH" -eq "01" ]; then
    log "Criando backup mensal..."
    cp $BACKUP_FILE "$MONTHLY_DIR/samba-ad-monthly-$DATE.tar.bz2"
fi

# Limpeza de backups antigos
log "Limpando backups antigos..."

# Diários - manter últimos 7
find $DAILY_DIR -name "*.tar.bz2" -mtime +$RETENTION_DAILY -delete
find $DAILY_DIR -name "*.tar.gz" -mtime +$RETENTION_DAILY -delete

# Semanais - manter últimos 4
find $WEEKLY_DIR -name "*.tar.bz2" -mtime +$((RETENTION_WEEKLY * 7)) -delete

# Mensais - manter últimos 12
find $MONTHLY_DIR -name "*.tar.bz2" -mtime +$((RETENTION_MONTHLY * 30)) -delete

# Verificar espaço em disco
DISK_USAGE=$(df -h $BACKUP_DIR | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log "AVISO: Uso de disco acima de 80% ($DISK_USAGE%)"
fi

# Resumo
log "=========================================="
log "Backup concluído!"
log "Tamanho do backup: $(du -h $BACKUP_FILE | cut -f1)"
log "Espaço utilizado no backup: $(du -sh $BACKUP_DIR | cut -f1)"
log "=========================================="

exit 0
```

### Configurar Cron Job

```bash
# Tornar script executável
sudo chmod +x /usr/local/bin/backup-samba-ad.sh

# Criar diretório de backup
sudo mkdir -p /backup/samba-ad

# Adicionar ao cron (diariamente às 02:00)
sudo crontab -e
```

**Adicionar linha:**

```cron
0 2 * * * /usr/local/bin/backup-samba-ad.sh >> /var/log/samba-backup.log 2>&1
```

### Verificar Backups

```bash
# Listar backups
ls -la /backup/samba-ad/daily/

# Verificar integridade
tar -tjf /backup/samba-ad/daily/samba-ad-backup-*.tar.bz2 | head -20

# Ver log de backup
tail -50 /var/log/samba-backup.log
```

---

## 📊 Monitorização com Netdata

### Instalação

```bash
# Instalar Netdata
curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh
bash /tmp/netdata-kickstart.sh --stable-channel
```

### Acesso

| Parâmetro | Valor |
|-----------|-------|
| **URL** | http://192.168.1.10:19999 |
| **Porta** | 19999 |
| **Protocolo** | HTTP |

### Configuração

**Ficheiro:** `/etc/netdata/netdata.conf`

```ini
[global]
    run as user = netdata
    web files owner = root
    web files group = root
    bind to = 192.168.1.10

[web]
    bind to = 192.168.1.10:19999
    allow connections from = 192.168.1.0/24 localhost

[plugins]
    enable running new plugins = yes
    check for new plugins every = 60
```

### Alertas Configurados

**Ficheiro:** `/etc/netdata/health.d/samba.conf`

```yaml
# Alerta de uso de CPU do Samba
alarm: samba_cpu_usage
on: apps.cpu
class: Utilization
component: Samba
lookup: average -5m percentage of samba
units: %
every: 1m
warn: $this > 80
crit: $this > 95
info: Samba CPU usage is high

# Alerta de memória do Samba
alarm: samba_memory_usage
on: apps.mem
class: Utilization
component: Samba
lookup: average -5m absolute of samba
units: MiB
every: 1m
warn: $this > 500
crit: $this > 800
info: Samba memory usage is high

# Alerta de disco
alarm: disk_space_usage
on: disk.space
class: Utilization
component: Disk
lookup: average -1m percentage
units: %
every: 1m
warn: $this > 80
crit: $this > 90
info: Disk space is running low
```

### Verificar Netdata

```bash
# Estado do serviço
sudo systemctl status netdata

# Testar acesso
curl -s http://localhost:19999/api/v1/info | jq .

# Ver métricas do sistema
curl -s "http://localhost:19999/api/v1/data?chart=system.cpu&after=-60"
```

---

## 🔍 Troubleshooting Comum

### Problemas de Autenticação

| Sintoma | Causa Provável | Solução |
|---------|----------------|---------|
| "Clock skew too great" | Diferença de tempo | Sincronizar NTP |
| "KDC unreachable" | DNS ou rede | Verificar DNS SRV |
| "Pre-authentication failed" | Password errada | Reset password |
| "Account locked" | Tentativas falhadas | Desbloquear conta |

### Verificar Sincronização de Tempo

```bash
# Verificar diferença
timedatectl status

# Forçar sincronização
sudo systemctl restart systemd-timesyncd

# Verificar NTP
ntpdate -q pool.ntp.org
```

### Desbloquear Conta

```bash
# Ver estado da conta
sudo samba-tool user show username

# Desbloquear
sudo samba-tool user setexpiry username --noexpiry

# Reset de password
sudo samba-tool user setpassword username --newpassword='NovaPassword123!'
```

### Problemas de DNS

```bash
# Testar resolução
host dc.fsociety.pt localhost
host -t SRV _ldap._tcp.fsociety.pt localhost
host -t SRV _kerberos._tcp.fsociety.pt localhost

# Verificar zonas
sudo samba-tool dns zonelist dc.fsociety.pt -U Administrator

# Reiniciar serviço
sudo systemctl restart samba-ad-dc
```

### Problemas de LDAP

```bash
# Testar bind
ldapwhoami -H ldap://localhost -D "Administrator@fsociety.pt" -W

# Pesquisar utilizador
ldapsearch -H ldap://localhost -x -D "Administrator@fsociety.pt" -W \
    -b "DC=fsociety,DC=pt" "(sAMAccountName=testuser)"

# Verificar conexões LDAP
ss -tlnp | grep :389
```

### Problemas de SMB

```bash
# Testar partilhas
smbclient -L localhost -U Administrator

# Verificar sintaxe do smb.conf
testparm

# Ver conexões ativas
smbstatus

# Logs detalhados
sudo tail -f /var/log/samba/log.smbd
```

---

## 📝 Comandos Úteis

### Gestão de Utilizadores

```bash
# Criar utilizador
sudo samba-tool user create username 'Password123!' \
    --given-name="Nome" \
    --surname="Apelido" \
    --mail-address="email@fsociety.pt" \
    --userou="OU=TI,OU=FSociety"

# Listar utilizadores
sudo samba-tool user list

# Ver detalhes
sudo samba-tool user show username

# Desativar utilizador
sudo samba-tool user disable username

# Ativar utilizador
sudo samba-tool user enable username

# Eliminar utilizador
sudo samba-tool user delete username

# Reset password
sudo samba-tool user setpassword username
```

### Gestão de Grupos

```bash
# Criar grupo
sudo samba-tool group add groupname \
    --description="Descrição do grupo" \
    --groupou="OU=Grupos,OU=FSociety"

# Listar grupos
sudo samba-tool group list

# Adicionar membro
sudo samba-tool group addmembers groupname username

# Remover membro
sudo samba-tool group removemembers groupname username

# Ver membros
sudo samba-tool group listmembers groupname
```

### Gestão de DNS

```bash
# Adicionar registo A
sudo samba-tool dns add dc.fsociety.pt fsociety.pt hostname A 192.168.1.X -U Administrator

# Remover registo
sudo samba-tool dns delete dc.fsociety.pt fsociety.pt hostname A 192.168.1.X -U Administrator

# Listar registos
sudo samba-tool dns query dc.fsociety.pt fsociety.pt @ ALL -U Administrator

# Ver zonas
sudo samba-tool dns zonelist dc.fsociety.pt -U Administrator
```

### Gestão de GPOs

```bash
# Listar GPOs
sudo samba-tool gpo listall

# Ver GPO
sudo samba-tool gpo show {GPO-GUID}

# Criar GPO
sudo samba-tool gpo create "Nome da GPO" -U Administrator
```

### Verificações de Sistema

```bash
# Estado dos serviços
systemctl status samba-ad-dc
systemctl status isc-dhcp-server
systemctl status freeradius
systemctl status crowdsec

# Verificar portas
ss -tlnp | grep -E "(53|88|389|445|636|1812)"

# Espaço em disco
df -h

# Memória
free -h

# CPU e processos
htop
```

### Logs

```bash
# Samba AD DC
sudo tail -f /var/log/samba/log.samba

# Autenticação
sudo tail -f /var/log/auth.log

# DHCP
sudo tail -f /var/log/dhcpd.log

# FreeRADIUS
sudo tail -f /var/log/freeradius/radius.log

# CrowdSec
sudo tail -f /var/log/crowdsec/crowdsec.log

# Todos os logs importantes
sudo tail -f /var/log/samba/log.samba /var/log/auth.log /var/log/syslog
```

---

## 🔄 Atualizações e Upgrades

### Atualizações de Segurança

```bash
# Verificar atualizações disponíveis
sudo apt update
sudo apt list --upgradable

# Instalar atualizações de segurança
sudo apt upgrade -y

# Atualizações automáticas
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### Upgrade do Samba

```bash
# IMPORTANTE: Fazer backup antes!
/usr/local/bin/backup-samba-ad.sh

# Verificar versão atual
samba --version

# Atualizar
sudo apt update
sudo apt install --only-upgrade samba

# Reiniciar serviços
sudo systemctl restart samba-ad-dc

# Verificar funcionamento
samba-tool domain level show
```

### Reinício Planeado

```bash
# Notificar utilizadores (se possível)
wall "O servidor DC será reiniciado em 10 minutos para manutenção"

# Agendar reinício
sudo shutdown -r +10 "Manutenção programada"

# Cancelar (se necessário)
sudo shutdown -c
```

---

## 🆘 Recuperação de Desastres

### Restore do Backup

```bash
# 1. Parar serviços
sudo systemctl stop samba-ad-dc
sudo systemctl stop isc-dhcp-server
sudo systemctl stop freeradius

# 2. Fazer backup do estado atual (por segurança)
sudo mv /var/lib/samba /var/lib/samba.old

# 3. Restaurar do backup
sudo samba-tool domain backup restore \
    --backup-file=/backup/samba-ad/daily/samba-ad-backup-XXXXXXXX.tar.bz2 \
    --targetdir=/var/lib/samba \
    --newservername=dc

# 4. Verificar configuração
testparm

# 5. Reiniciar serviços
sudo systemctl start samba-ad-dc
sudo systemctl start isc-dhcp-server
sudo systemctl start freeradius

# 6. Verificar funcionamento
samba-tool domain level show
```

### Checklist Pós-Restore

- [ ] Verificar resolução DNS
- [ ] Testar autenticação Kerberos
- [ ] Testar acesso LDAP
- [ ] Verificar partilhas SMB
- [ ] Testar DHCP
- [ ] Testar autenticação RADIUS
- [ ] Verificar CrowdSec

### Contactos de Emergência

| Função | Contacto |
|--------|----------|
| Administrador de Sistemas | admin@fsociety.pt |
| Suporte Técnico | suporte@fsociety.pt |

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| Samba Backup/Restore | https://wiki.samba.org/index.php/Back_up_and_Restoring_a_Samba_AD_DC |
| Samba Administration | https://wiki.samba.org/index.php/Samba_AD_DC_Administration |
| Netdata Documentation | https://learn.netdata.cloud/ |

### Artigos Técnicos

1. **Samba AD DC Maintenance** - Samba Wiki
2. **Linux Server Monitoring with Netdata** - Netdata Blog
3. **Disaster Recovery for Active Directory** - Microsoft Docs

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 🔗 Navegação

| Anterior | Índice | Próximo |
|----------|--------|---------|
| [← Shares e Permissões](08-shares-permissoes.md) | [📚 Índice](README.md) | [Documentação Principal →](../index.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-manutenção-do-domain-controller)**

---

*Última atualização: Dezembro 2024*

</div>
