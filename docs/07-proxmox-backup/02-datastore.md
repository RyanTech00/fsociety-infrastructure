# 💾 Configuração de Datastore - Proxmox Backup Server

> Guia de configuração de datastores no Proxmox Backup Server, incluindo criação, gestão e garbage collection.

---

## 📋 Visão Geral

Um **datastore** é o local onde o PBS armazena backups. Cada datastore é um diretório no filesystem que cont ém:
- Chunks de dados deduplica dos
- Índices de backups
- Metadados
- Snapshots

### Arquitetura do Datastore

```
/backup/pve-store/                  <- Datastore root
├── .chunks/                        <- Chunks deduplica dos (dados reais)
│   ├── 0000/
│   ├── 0001/
│   ├── ...
│   └── ffff/
├── ct/                             <- Backups de containers
├── vm/                             <- Backups de VMs
│   ├── 102/                        <- VM ID 102 (pfSense)
│   │   ├── 2024-12-01T02:00:00Z/  <- Snapshot timestamp
│   │   │   ├── index.json.blob    <- Índice do backup
│   │   │   ├── drive-scsi0.img.fidx <- Índice de disco
│   │   │   └── qemu-server.conf.blob
│   │   └── 2024-12-02T02:00:00Z/
│   ├── 104/                        <- VM ID 104
│   ├── 105/                        <- VM ID 105
│   └── 106/                        <- VM ID 106
└── .gc-status                      <- Estado do garbage collection
```

---

## 🗂️ Datastore do Projeto: pve-store

### Especificações

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | pve-store |
| **Path** | /backup/pve-store |
| **Filesystem** | ext4 |
| **Capacidade** | 42 GB |
| **Utilizado** | 40 GB (95%) |
| **Disponível** | 2 GB |
| **GC Mode** | Week day schedule |
| **Verify Schedule** | Configurado |

---

## 🛠️ Criar Datastore

### Via Web UI

1. **Datastore → Add Datastore**

2. Preencher campos:

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Name** | pve-store | ID do datastore |
| **Backing Path** | /backup/pve-store | Path absoluto |
| **GC Schedule** | weekly (opcional) | Garbage collection |
| **Prune Schedule** | (vazio) | Prune automático |
| **Verify Schedule** | (vazio) | Verificação |
| **Comment** | Datastore principal | Descrição |

3. Clicar em **Add**

### Via CLI

```bash
# SSH para o PBS
ssh root@192.168.1.30

# Criar diretório
mkdir -p /backup/pve-store

# Criar datastore
proxmox-backup-manager datastore create pve-store /backup/pve-store

# Verificar
proxmox-backup-manager datastore list
```

---

## 📁 Preparar Filesystem

### Opção 1: Usar Disco Existente (Projeto FSociety)

```bash
# Verificar espaço disponível
df -h /

# Criar diretório para datastore
mkdir -p /backup/pve-store

# Definir permissões
chown backup:backup /backup/pve-store
chmod 750 /backup/pve-store
```

### Opção 2: Adicionar Disco Dedicado

Se adicionar disco separado para backups:

#### No Proxmox VE (adicionar disco à VM)

```bash
# Adicionar disco de 500GB à VM 101
qm set 101 -scsi1 local-lvm:500

# Ou criar em storage específico
qm set 101 -scsi1 pve-nvme:500
```

#### No PBS (formatar e montar)

```bash
# Listar discos
lsblk

# Saída esperada:
# sdb      8:16   0  500G  0 disk

# Criar partição
fdisk /dev/sdb
# n (nova), p (primária), 1, [Enter], [Enter], w (write)

# Formatar com ext4
mkfs.ext4 -L backup-data /dev/sdb1

# Criar diretório de montagem
mkdir -p /backup/pve-store

# Montar
mount /dev/sdb1 /backup/pve-store

# Adicionar ao fstab
echo "/dev/sdb1 /backup/pve-store ext4 defaults 0 2" >> /etc/fstab

# Verificar
df -h /backup/pve-store

# Definir permissões
chown backup:backup /backup/pve-store
chmod 750 /backup/pve-store
```

### Opção 3: Usar ZFS (Recomendado para Grandes Datastores)

```bash
# Criar pool ZFS
zpool create -o ashift=12 backup-pool /dev/sdb

# Criar dataset
zfs create -o compression=lz4 -o atime=off backup-pool/pve-store

# Definir montagem
zfs set mountpoint=/backup/pve-store backup-pool/pve-store

# Verificar
zfs list
df -h /backup/pve-store
```

---

## ⚙️ Configurar Datastore

### Políticas de Retenção (Prune)

#### Via Web UI

1. **Datastore → pve-store → Prune & GC**

2. Configurar:

| Opção | Valor | Descrição |
|-------|-------|-----------|
| **Keep Last** | 7 | Manter últimos 7 backups |
| **Keep Daily** | 7 | 1 backup/dia por 7 dias |
| **Keep Weekly** | 4 | 1 backup/semana por 4 semanas |
| **Keep Monthly** | 3 | 1 backup/mês por 3 meses |
| **Keep Yearly** | 1 | 1 backup/ano |

3. Clicar em **OK**

#### Via CLI

```bash
# Configurar política de retenção
proxmox-backup-manager datastore update pve-store \
  --keep-last 7 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --keep-yearly 1
```

#### Configuração Atual do Projeto

```bash
# keep-all=1
# Mantém TODOS os backups (1 de cada)
# Adequado para ambientes de teste/desenvolvimento
# ⚠️ Em produção, usar política mais granular
```

### Garbage Collection (GC)

Remove chunks órfãos e liberta espaço.

#### Agendar GC

```bash
# Via CLI - Agendar GC semanal (domingo às 03:00)
proxmox-backup-manager garbage-collection schedule update pve-store \
  --schedule "sun 03:00"

# Ver agenda
proxmox-backup-manager garbage-collection schedule show pve-store
```

#### Executar GC Manualmente

```bash
# Via CLI
proxmox-backup-manager garbage-collect pve-store

# Via Web UI
# Datastore → pve-store → Prune & GC → Garbage Collect
```

**Processo de GC:**

1. **Mark Phase**: Identificar chunks em uso
2. **Sweep Phase**: Remover chunks não referenciados
3. **Update Stats**: Atualizar estatísticas de espaço

### Verificação de Integridade

Verifica checksums de todos os chunks.

#### Agendar Verificação

```bash
# Verificação mensal (1º domingo do mês às 04:00)
proxmox-backup-manager verify-job create monthly-verify \
  --datastore pve-store \
  --schedule "sun 1 04:00"

# Verificar job criado
proxmox-backup-manager verify-job list
```

#### Executar Verificação Manual

```bash
# Via CLI - verificar datastore completo
proxmox-backup-client snapshot verify-all \
  --repository root@pam@localhost:pve-store

# Verificar apenas um backup
proxmox-backup-client snapshot verify \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store
```

---

## 📊 Monitorização do Datastore

### Via Web UI

**Datastore → pve-store**

Métricas visíveis:
- **Disk Usage**: Espaço usado/disponível
- **Estimated Full Date**: Previsão de enchimento
- **Deduplication Factor**: Taxa de deduplicação
- **Backup Count**: Número de backups
- **Snapshot Count**: Número de snapshots

### Via CLI

```bash
# Status do datastore
proxmox-backup-manager datastore status pve-store

# Estatísticas detalhadas
proxmox-backup-client datastore status \
  --repository root@pam@localhost:pve-store

# Listar todos os backups
proxmox-backup-client snapshot list \
  --repository root@pam@localhost:pve-store

# Informação de um backup específico
proxmox-backup-client snapshot info \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store
```

### Script de Monitorização

```bash
# Criar script
nano /usr/local/bin/pbs-datastore-check.sh
```

```bash
#!/bin/bash
# Monitorização de Datastore PBS

DATASTORE="pve-store"
THRESHOLD=90
MAILTO="admin@fsociety.pt"

# Obter utilização
USAGE=$(df -h /backup/pve-store | awk 'NR==2 {print $5}' | sed 's/%//')

# Alertar se > 90%
if [ $USAGE -gt $THRESHOLD ]; then
    echo "ALERTA: Datastore $DATASTORE está ${USAGE}% cheio!" | \
    mail -s "PBS Datastore Alert" $MAILTO
fi

# Estatísticas
proxmox-backup-client datastore status \
  --repository root@pam@localhost:$DATASTORE \
  | mail -s "PBS Datastore Status" $MAILTO
```

```bash
# Tornar executável
chmod +x /usr/local/bin/pbs-datastore-check.sh

# Agendar execução diária
cat >> /etc/cron.d/pbs-datastore-check << EOF
# PBS datastore check diário às 08:00
0 8 * * * root /usr/local/bin/pbs-datastore-check.sh
EOF
```

---

## 🔧 Gestão de Backups no Datastore

### Listar Backups

```bash
# Listar todos
proxmox-backup-client snapshot list \
  --repository root@pam@localhost:pve-store

# Listar apenas VM 102
proxmox-backup-client snapshot list \
  --repository root@pam@localhost:pve-store \
  vm/102
```

### Remover Backup Específico

```bash
# Via CLI
proxmox-backup-client snapshot remove \
  vm/102/2024-11-01T02:00:00Z \
  --repository root@pam@localhost:pve-store

# Via Web UI
# Datastore → pve-store → Content
# VM → Selecionar backup → Remove
```

### Proteger Backup (Prevent Prune)

```bash
# Proteger backup crítico
proxmox-backup-client snapshot protect \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store

# Desproteger
proxmox-backup-client snapshot unprotect \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store
```

---

## 🎯 Boas Práticas

### 1. Capacidade do Datastore

- Planear 3-4x o tamanho total das VMs
- Considerar taxa de mudança dos dados
- Monitorizar crescimento regularmente

**Cálculo:**
```
VMs totais: 200 GB
Taxa de mudança: 10% diário
Retenção: 30 dias

Espaço necessário ≈ 200 GB + (200 GB × 10% × 30 dias) = 800 GB
Com deduplicação (70%): 800 GB × 0.3 = 240 GB
```

### 2. Filesystem

| Cenário | Recomendado |
|---------|-------------|
| < 100 GB | ext4 |
| 100 GB - 1 TB | ext4 ou XFS |
| > 1 TB | ZFS |
| Performance crítica | ZFS com SSD cache |

### 3. Garbage Collection

- Executar GC semanalmente
- Agendar fora do horário de backups
- Monitorizar duração do GC

### 4. Verificação

- Verificar mensalmente
- Mais frequente para dados críticos
- Alertar em caso de corrupção

---

## 🐛 Troubleshooting

### Problema: Datastore cheio (95%)

**Soluções:**

```bash
# 1. Executar GC
proxmox-backup-manager garbage-collect pve-store

# 2. Remover backups antigos (prune)
proxmox-backup-client snapshot prune \
  vm/102 \
  --keep-last 3 \
  --repository root@pam@localhost:pve-store

# 3. Expandir filesystem
# Se em LVM:
lvextend -L +100G /dev/mapper/pve-backup
resize2fs /dev/mapper/pve-backup

# 4. Adicionar disco adicional (novo datastore)
```

### Problema: GC muito lento

**Causas:**
- Muitos chunks
- I/O lento
- Fragmentação

**Soluções:**
```bash
# Verificar I/O
iostat -x 2

# Se em HDD, considerar:
# 1. Mover para SSD
# 2. Otimizar filesystem
# 3. Executar GC com menos frequência
```

### Problema: Backup corrompido

**Verificar:**
```bash
# Verificar backup específico
proxmox-backup-client snapshot verify \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store

# Se corrompido, remover e fazer novo backup
proxmox-backup-client snapshot remove \
  vm/102/2024-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store
```

---

## 📖 Próximos Passos

Após configurar datastore:

1. ✅ **Datastore Criado**
2. ➡️ [Integração com PVE](03-integracao-pve.md) - Adicionar PBS ao Proxmox VE
3. ➡️ [Backup Jobs](04-backup-jobs.md) - Configurar backups automáticos

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

**[⬅️ Anterior: Instalação](01-instalacao.md)** | **[Índice](README.md)** | **[Próximo: Integração PVE ➡️](03-integracao-pve.md)**

</div>

---

*Última atualização: Dezembro 2024*
