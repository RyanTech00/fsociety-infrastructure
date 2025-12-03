# 🔧 Manutenção do PBS

> Guia de manutenção do Proxmox Backup Server, incluindo prune, garbage collection e monitorização.

---

## 📋 Tarefas de Manutenção

| Frequência | Tarefa |
|------------|--------|
| **Diária** | Verificar backups executados |
| **Semanal** | Garbage Collection |
| **Mensal** | Verificação de integridade |
| **Trimestral** | Atualizações do PBS |

---

## 🗑️ Prune (Remover Backups Antigos)

### Política de Retenção Configurada

No PBS 4.x, a retenção é configurada através de **prune-jobs** automáticos.

| Período | Quantidade | Descrição |
|---------|------------|-----------|
| **Diários** | 7 | Últimos 7 dias |
| **Semanais** | 4 | Últimas 4 semanas |
| **Mensais** | 6 | Últimos 6 meses |

### Configurar Prune-Job (PBS 4.x)

No PBS 4.x, use prune-jobs para automatizar a limpeza:

```bash
# Criar prune job
proxmox-backup-manager prune-job create pve-store-prune \
  --store pve-store \
  --schedule daily \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

# Listar prune jobs
proxmox-backup-manager prune-job list

# Ver detalhes de um prune job
proxmox-backup-manager prune-job show pve-store-prune

# Remover prune job (se necessário)
proxmox-backup-manager prune-job remove pve-store-prune
```

### Configurar Política de Retenção (Método Alternativo)

```bash
# Configurar política no datastore
proxmox-backup-manager datastore update pve-store \
  --keep-last 7 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
```

### Executar Prune Manual

```bash
# Via CLI no PBS
proxmox-backup-client snapshot prune \
  vm/102 \
  --keep-last 7 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --repository root@pam@localhost:pve-store

# Via Web UI
# Datastore → pve-store → Prune & GC → Prune
```

---

## 🗄️ Garbage Collection

Remove chunks órfãos e liberta espaço em disco.

### O Que é Garbage Collection?

**Garbage Collection (GC)** identifica e remove:
- Chunks que não são mais referenciados por nenhum backup
- Dados órfãos de backups removidos
- Blocos duplicados desnecessários

### Executar GC Manual

```bash
# Executar GC no datastore
proxmox-backup-manager garbage-collection start pve-store

# Ver status do GC
proxmox-backup-manager task list | grep garbage

# Via Web UI
# Datastore → pve-store → Prune & GC → Garbage Collect
```

### Agendar GC Automático

```bash
# Configurar GC semanal no datastore
proxmox-backup-manager datastore update pve-store --gc-schedule weekly

# Ou definir dia/hora específico (domingo 03:00)
proxmox-backup-manager garbage-collection schedule update pve-store \
  --schedule "sun 03:00"

# Ver agenda de GC
proxmox-backup-manager garbage-collection schedule show pve-store
```

### Resultados de GC - Exemplo Real

Após executar GC no projeto FSociety:

```bash
proxmox-backup-manager garbage-collection start pve-store
```

**Resultados:**
- **Removed garbage**: 4.633 GiB
- **Original data usage**: 800 GiB
- **On-Disk usage**: 30.16 GiB (3.77%)
- **Deduplication factor**: 26.53x

**Benefícios:**
- Recuperação de 4.6 GB de espaço
- Taxa de deduplicação excelente (26.53x)
- Apenas 3.77% do espaço original necessário

### Monitorizar GC

```bash
# Ver último GC
cat /backup/pve-store/.gc-status

# Logs do GC
journalctl -u proxmox-backup -f | grep gc

# Estatísticas do datastore
proxmox-backup-manager datastore status pve-store
```

---

## ✅ Verificação de Integridade

### Verificar Backup

```bash
# Verificar backup específico
proxmox-backup-client snapshot verify \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store

# Verificar todos
proxmox-backup-client snapshot verify-all \
  --repository root@pam@localhost:pve-store
```

### Agendar Verificação

```bash
# Mensal (1º domingo 04:00)
proxmox-backup-manager verify-job create monthly-verify \
  --datastore pve-store \
  --schedule "sun 1 04:00"
```

---

## 📊 Monitorização

### Espaço em Disco

```bash
# Verificar espaço
df -h /backup/pve-store

# Alertar se > 90%
USAGE=$(df -h /backup/pve-store | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $USAGE -gt 90 ]; then
    echo "ALERTA: Datastore ${USAGE}% cheio!"
fi
```

### Status do PBS

```bash
# Status geral
proxmox-backup-manager status

# Status de datastores
proxmox-backup-manager datastore list

# Tasks recentes
proxmox-backup-manager task list --limit 20
```

---

## 🔄 Atualizações

### Atualizar PBS

```bash
# SSH para o PBS
ssh root@192.168.1.30

# Atualizar
apt update
apt dist-upgrade -y

# Verificar versão
proxmox-backup-manager version

# Reiniciar se necessário
reboot
```

---

## 💾 Expansão de Disco

### Quando Expandir

Expandir o disco do PBS quando:
- Utilização > 85%
- Espaço disponível < 50 GB
- Erro ENOSPC ocorrer

### Procedimento Completo

#### 1. Expandir no Host Proxmox VE

```bash
# No host Proxmox VE (via SSH)
# Verificar tamanho atual
qm config 101 | grep scsi0

# Expandir disco (exemplo: adicionar 400GB)
qm resize 101 scsi0 +400G

# Confirmar mudança
qm config 101 | grep scsi0
```

#### 2. Expandir no PBS (VM 101)

```bash
# SSH para o PBS
ssh root@192.168.1.30

# 1. Instalar ferramenta growpart
apt update && apt install cloud-guest-utils -y

# 2. Verificar layout atual
lsblk
df -h /

# 3. Expandir partição (exemplo: /dev/sda3)
growpart /dev/sda 3

# 4. Expandir Physical Volume (LVM)
pvresize /dev/sda3

# 5. Expandir Logical Volume (usar todo espaço livre)
lvextend -l +100%FREE /dev/pbs/root

# 6. Expandir filesystem (ext4)
resize2fs /dev/pbs/root

# 7. Verificar resultado
df -h /
lsblk
```

### Exemplo Real - Projeto FSociety

**Situação Inicial:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/pbs/root    41G   41G     0 100% /
```

**Comandos Executados:**

```bash
# No Proxmox VE
qm resize 101 scsi0 +400G

# No PBS
apt update && apt install cloud-guest-utils -y
growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE /dev/pbs/root
resize2fs /dev/pbs/root
```

**Resultado Final:**
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/pbs/root   834G   41G  762G   5% /
```

**Métricas:**
- **Antes**: 41 GB (100% cheio)
- **Depois**: 834 GB (5% usado, 762 GB livres)
- **Expansão**: +793 GB
- **Estado**: ✅ Resolvido

---

## 🐛 Troubleshooting

### Problema: Disco Cheio (ENOSPC)

**Sintomas:**
```
Error: unable to start garbage collection job - ENOSPC: No space left on device
unable to create backup - ENOSPC: No space left on device
```

**Diagnóstico:**
```bash
# Verificar espaço
df -h /

# Verificar utilização do datastore
du -sh /backup/pve-store/
```

**Solução:**

```bash
# 1. Verificar espaço atual
df -h /

# 2. Expandir disco no host (ver secção "Expansão de Disco" acima)
# No Proxmox VE:
qm resize VMID scsi0 +SIZE

# 3. Expandir no PBS
apt update && apt install cloud-guest-utils -y
growpart /dev/sda 3
pvresize /dev/sda3
lvextend -l +100%FREE /dev/pbs/root
resize2fs /dev/pbs/root

# 4. Executar GC para recuperar espaço
proxmox-backup-manager garbage-collection start pve-store

# 5. Verificar resultado
df -h /
```

### Problema: GC Não Liberta Espaço

**Causas possíveis:**
- Backups protegidos
- Prune não executado
- Chunks ainda em uso

**Solução:**
```bash
# 1. Executar prune primeiro
proxmox-backup-client snapshot prune \
  vm/102 \
  --keep-last 7 \
  --repository root@pam@localhost:pve-store

# 2. Depois executar GC
proxmox-backup-manager garbage-collection start pve-store

# 3. Verificar backups protegidos
proxmox-backup-client snapshot list \
  --repository root@pam@localhost:pve-store
```

### Problema: Backup Lento

**Diagnóstico:**
```bash
# Verificar I/O do disco
iostat -x 2

# Verificar load
uptime

# Verificar logs
journalctl -u proxmox-backup -f
```

**Soluções:**
- Usar compressão mais leve (lz4 em vez de zstd)
- Aumentar RAM do PBS
- Mover datastore para SSD/NVMe
- Agendar backups fora do horário de pico

### Problema: Prune-Job Falha

**Verificar configuração:**
```bash
# Listar prune jobs
proxmox-backup-manager prune-job list

# Ver detalhes
proxmox-backup-manager prune-job show pve-store-prune

# Ver logs
journalctl -u proxmox-backup | grep prune
```

**Recriar job:**
```bash
# Remover job problemático
proxmox-backup-manager prune-job remove pve-store-prune

# Criar novo
proxmox-backup-manager prune-job create pve-store-prune \
  --store pve-store \
  --schedule daily \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
```

---

## 📊 Estado do Datastore - Configuração Final

| Campo | Valor |
|-------|-------|
| **Nome** | pve-store |
| **Path** | /backup/pve-store |
| **Capacidade** | 834 GB |
| **Utilizado** | 41 GB (5%) |
| **Disponível** | 762 GB |
| **GC Schedule** | weekly |
| **Prune Schedule** | daily |
| **Notification** | notification-system |

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

**[⬅️ Anterior: Restore](05-restore.md)** | **[Índice](README.md)** | **[Voltar à Documentação Principal ⬆️](../index.md)**

</div>

---

*Última atualização: Dezembro 2024*
