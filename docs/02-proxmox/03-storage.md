# 💾 Configuração de Storage - Proxmox VE

> Guia completo de configuração de storage no Proxmox VE, incluindo LVM thin provisioning, storage pools e boas práticas.

---

## 📋 Visão Geral

O Proxmox VE suporta diversos tipos de storage para armazenar VMs, containers, backups, ISOs e templates. O projeto FSociety utiliza uma combinação de **HDD** para capacidade e **NVMe** para performance.

### Arquitetura de Storage

```
┌──────────────────────────────────────────────────────────────┐
│                  Proxmox VE Host Storage                     │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Disco 1: /dev/sda (HDD 931.5 GB)                     │  │
│  │  ┌──────────────┐  ┌───────────────────────────────┐ │  │
│  │  │  sda1: EFI   │  │  sda2: Boot (1 GB)            │ │  │
│  │  │  1 GB        │  │  ext4                         │ │  │
│  │  └──────────────┘  └───────────────────────────────┘ │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  sda3: LVM PV (pve VG)                           │ │  │
│  │  │  ┌────────────────┐  ┌──────────────────────┐   │ │  │
│  │  │  │ pve-root       │  │ pve-data             │   │ │  │
│  │  │  │ 96 GB (37%)    │  │ 794 GB (15%)         │   │ │  │
│  │  │  │ → local (dir)  │  │ → local-lvm (thin)   │   │ │  │
│  │  │  │   /var/lib/vz  │  │   VMs/Containers     │   │ │  │
│  │  │  └────────────────┘  └──────────────────────┘   │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Disco 2: /dev/nvme0n1 (NVMe 223.6 GB)                │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │  nvme0n1p1: LVM PV (pve-nvme VG)                 │ │  │
│  │  │  ┌────────────────┐  ┌──────────────────────┐   │ │  │
│  │  │  │ pve-nvme-swap  │  │ pve-nvme-data        │   │ │  │
│  │  │  │ 8 GB           │  │ 200 GB (12%)         │   │ │  │
│  │  │  │ → swap         │  │ → pve-nvme (thin)    │   │ │  │
│  │  │  │                │  │   VMs Críticas       │   │ │  │
│  │  │  └────────────────┘  └──────────────────────┘   │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Storage Remoto: pbs-store (PBS)                      │  │
│  │  192.168.1.30:8007                                    │  │
│  │  42 GB (95% utilizado)                                │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 💿 Discos Físicos

### /dev/sda - HDD 931.5 GB

| Partição | Tamanho | Tipo | Utilização |
|----------|---------|------|------------|
| **sda1** | 1 GB | EFI | Boot EFI |
| **sda2** | 1 GB | ext4 | /boot |
| **sda3** | ~929 GB | LVM | Volume Group "pve" |

```bash
# Ver layout de partições
fdisk -l /dev/sda

# Saída esperada:
# Device       Start        End    Sectors  Size Type
# /dev/sda1     2048    2099199    2097152    1G EFI System
# /dev/sda2  2099200    4196351    2097152    1G Linux filesystem
# /dev/sda3  4196352 1953525134 1949328783  929G Linux LVM
```

### /dev/nvme0n1 - NVMe 223.6 GB

| Partição | Tamanho | Tipo | Utilização |
|----------|---------|------|------------|
| **nvme0n1p1** | ~223 GB | LVM | Volume Group "pve-nvme" |

```bash
# Ver layout de partições
fdisk -l /dev/nvme0n1

# Saída esperada:
# Device           Start       End   Sectors  Size Type
# /dev/nvme0n1p1    2048 468862127 468860080  223G Linux LVM
```

---

## 🗂️ Storage Pools Configurados

### 1. local (Directory - HDD)

**Tipo:** Directory  
**Path:** `/var/lib/vz`  
**Dispositivo:** `/dev/pve/root` (LVM LV em /dev/sda)

| Parâmetro | Valor |
|-----------|-------|
| **ID** | local |
| **Tipo** | dir |
| **Path** | /var/lib/vz |
| **Capacidade** | 96 GB |
| **Utilizado** | 36 GB (37%) |
| **Disponível** | 60 GB |
| **Conteúdo** | VZDump backup files, ISO images, Container templates |
| **Compartilhado** | Não |
| **Ativo** | Sim |

**Características:**
- ✅ Ideal para ISOs, templates e backups
- ✅ Fácil de gerir e fazer backup
- ❌ Não suporta snapshots de VMs
- ❌ Performance limitada (HDD)

**Utilização:**
```bash
# Ver espaço
df -h /var/lib/vz

# Upload de ISO
# Via Web UI: local → ISO Images → Upload

# Via CLI:
cd /var/lib/vz/template/iso
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
```

### 2. local-lvm (LVM-Thin - HDD)

**Tipo:** LVM-Thin  
**Volume Group:** pve  
**Thin Pool:** data

| Parâmetro | Valor |
|-----------|-------|
| **ID** | local-lvm |
| **Tipo** | lvmthin |
| **Volume Group** | pve |
| **Thin Pool** | data |
| **Capacidade** | 794 GB |
| **Utilizado** | 119 GB (15%) |
| **Disponível** | 675 GB |
| **Conteúdo** | Disk image, Container |
| **Compartilhado** | Não |
| **Ativo** | Sim |

**Características:**
- ✅ Suporta snapshots de VMs
- ✅ Thin provisioning (over-provisioning possível)
- ✅ Grande capacidade (HDD 1TB)
- ❌ Performance média (HDD)

**VMs Armazenadas:**
- VMID 101: Proxmox-Backup (50 GB)
- VMID 104: Web-Server (50 GB)
- VMID 106: Servidor-de-Ficheiros (50 GB)
- VMID 108: mailcow

```bash
# Ver volume group
vgs pve

# Ver logical volumes
lvs pve

# Ver thin pool
lvs -a pve/data

# Ver utilização detalhada
lvs -a -o +lv_metadata_size,lv_size,data_percent,metadata_percent pve/data
```

### 3. pve-nvme (LVM-Thin - NVMe)

**Tipo:** LVM-Thin  
**Volume Group:** pve-nvme  
**Thin Pool:** data

| Parâmetro | Valor |
|-----------|-------|
| **ID** | pve-nvme |
| **Tipo** | lvmthin |
| **Volume Group** | pve-nvme |
| **Thin Pool** | data |
| **Capacidade** | 200 GB |
| **Utilizado** | 24 GB (12%) |
| **Disponível** | 176 GB |
| **Conteúdo** | Disk image, Container |
| **Compartilhado** | Não |
| **Ativo** | Sim |

**Características:**
- ✅ **Alta performance** (NVMe SSD)
- ✅ Suporta snapshots
- ✅ Thin provisioning
- ⚠️ Capacidade limitada (224 GB)

**VMs Armazenadas (Críticas):**
- VMID 102: pfSense (50 GB)
- VMID 105: Servidor-de-dominio (50 GB)

```bash
# Ver volume group NVMe
vgs pve-nvme

# Ver logical volumes
lvs pve-nvme

# Ver performance do NVMe
hdparm -Tt /dev/nvme0n1

# Saída esperada:
# Timing cached reads:   ~30000 MB/sec
# Timing buffered disk reads: ~3000 MB/sec
```

### 4. pbs-store (Proxmox Backup Server - Remoto)

**Tipo:** PBS (Proxmox Backup Server)  
**Servidor:** 192.168.1.30:8007

| Parâmetro | Valor |
|-----------|-------|
| **ID** | pbs-store |
| **Tipo** | pbs |
| **Servidor** | 192.168.1.30 |
| **Datastore** | pve-store |
| **Utilizador** | root@pam |
| **Capacidade** | 42 GB |
| **Utilizado** | 40 GB (95%) |
| **Disponível** | 2 GB |
| **Conteúdo** | VZDump backup files |
| **Encriptação** | Sim (fingerprint configurado) |

**Características:**
- ✅ Backups deduplic ados e comprimidos
- ✅ Encriptação de backups
- ✅ Verificação de integridade
- ⚠️ Requer VM separada para PBS

---

## ⚙️ Configuração de Storage

### Ficheiro /etc/pve/storage.cfg

```bash
# Configuração de Storage - Proxmox VE
# mail.fsociety.pt

# Directory storage (local)
dir: local
	path /var/lib/vz
	content iso,vztmpl,backup
	maxfiles 3
	shared 0

# LVM-Thin storage (HDD)
lvmthin: local-lvm
	thinpool data
	vgname pve
	content rootdir,images
	nodes mail

# LVM-Thin storage (NVMe - Alta Performance)
lvmthin: pve-nvme
	thinpool data
	vgname pve-nvme
	content rootdir,images
	nodes mail

# Proxmox Backup Server (remoto)
pbs: pbs-store
	datastore pve-store
	server 192.168.1.30
	content backup
	fingerprint XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
	username root@pam
	port 8007
```

### Ver Configuração Atual

```bash
# Ver storage.cfg
cat /etc/pve/storage.cfg

# Listar todos os storages
pvesm status

# Saída esperada:
# Name            Type     Status           Total            Used       Available
# local            dir     active       98703360        36700160        57318144
# local-lvm    lvmthin     active      834109440       125304832       708804608
# pbs-store        pbs     active       44040192        41877504         2162688
# pve-nvme     lvmthin     active      209715200        25165824       184549376
```

---

## 🛠️ Gestão de Storage

### Adicionar Storage via Web UI

#### Directory Storage

1. **Datacenter → Storage → Add → Directory**

| Campo | Valor |
|-------|-------|
| **ID** | backup-local |
| **Directory** | /mnt/backup |
| **Content** | VZDump backup files |
| **Nodes** | mail |
| **Enable** | ✅ Sim |
| **Shared** | ❌ Não |

2. Clicar em **Add**

#### LVM-Thin Storage

1. **Datacenter → Storage → Add → LVM-Thin**

| Campo | Valor |
|-------|-------|
| **ID** | pve-nvme |
| **Volume group** | pve-nvme |
| **Thin Pool** | data |
| **Content** | Disk image, Container |
| **Nodes** | mail |

2. Clicar em **Add**

### Adicionar Storage via CLI

```bash
# Adicionar directory storage
pvesm add dir backup-local --path /mnt/backup --content backup

# Adicionar LVM-Thin storage
pvesm add lvmthin pve-nvme --vgname pve-nvme --thinpool data --content images,rootdir

# Remover storage
pvesm remove <storage-id>

# Desativar storage
pvesm set <storage-id> --disable 1

# Ativar storage
pvesm set <storage-id> --disable 0
```

---

## 🔧 LVM Thin Provisioning

### Verificar Thin Pool

```bash
# Ver estado do thin pool
lvs -a pve/data

# Saída esperada:
# LV              VG  Attr       LSize   Pool Origin Data%  Meta%
# data            pve twi-aotz-- 794.00g              15.00  1.50

# Monitorizar em tempo real
watch -n 2 'lvs -a pve/data'
```

### Expandir Thin Pool

Se o thin pool estiver cheio:

```bash
# Ver espaço disponível no VG
vgs pve

# Expandir thin pool
lvextend -L +100G /dev/pve/data

# Ou usar percentagem do espaço livre
lvextend -l +50%FREE /dev/pve/data

# Verificar nova capacidade
lvs pve/data
```

### Over-Provisioning

Thin provisioning permite alocar mais espaço do que fisicamente disponível:

```bash
# Exemplo:
# Thin Pool: 794 GB
# VMs alocadas: 5 x 50 GB = 250 GB
# Utilização real: 119 GB (15%)

# Cálculo de over-provision:
# Alocado total: 250 GB
# Capacidade física: 794 GB
# Ratio: 250/794 = 31.5% (seguro)

# Recomendado: Não exceder 200% de over-provision
```

---

## 📊 Monitorização de Storage

### Via Web UI

**Datacenter → mail → Disks**

Mostra:
- Utilização por disco
- SMART status
- Health

**Datacenter → Storage**

Mostra:
- Capacidade total
- Espaço usado/disponível
- Status (ativo/inativo)

### Via CLI

```bash
# Resumo de storage
pvesm status

# Detalhes de um storage específico
pvesm list local

# Espaço em disco
df -h

# Utilização LVM
vgs
lvs

# SMART health
smartctl -H /dev/sda
smartctl -H /dev/nvme0n1

# I/O stats
iostat -x 2
```

---

## 🎯 Boas Práticas

### Escolha de Storage para VMs

| Tipo de VM | Storage Recomendado | Motivo |
|------------|---------------------|--------|
| **Firewall (pfSense)** | pve-nvme (NVMe) | Alta performance de I/O necessária |
| **Domain Controller** | pve-nvme (NVMe) | Acesso rápido a LDAP/DNS |
| **File Server** | local-lvm (HDD) | Grande capacidade para ficheiros |
| **Web Server** | local-lvm (HDD) | I/O moderado |
| **Mail Server** | local-lvm (HDD) | Grande capacidade para emails |
| **Backup Server** | local-lvm (HDD) | Capacidade mais importante que velocidade |

### Gestão de Espaço

1. **Monitorizar regularmente**
   ```bash
   # Adicionar a crontab
   0 */6 * * * /usr/sbin/pvesm status | mail -s "Proxmox Storage Status" admin@fsociety.pt
   ```

2. **Configurar alertas**
   - Datacenter → Options → Email Settings
   - Configurar threshold para alertas (ex: 80%)

3. **Limpar backups antigos**
   ```bash
   # Listar backups
   pvesm list local --content backup
   
   # Remover backup específico
   pvesm free local:backup/vzdump-qemu-102-2024_12_01-02_00_00.vma.zst
   ```

4. **Utilizar PBS para backups**
   - Deduplicação economiza espaço
   - Retenção automática configurável

### Thin Provisioning

1. **Não over-provisionar excessivamente**
   - Manter ratio < 200%
   - Monitorizar Data% regularmente

2. **Configurar alertas**
   ```bash
   # Criar script de monitorização
   nano /usr/local/bin/check-thin-pool.sh
   ```
   
   ```bash
   #!/bin/bash
   THRESHOLD=80
   USAGE=$(lvs --noheadings -o data_percent pve/data | tr -d ' ')
   if [ ${USAGE%.*} -gt $THRESHOLD ]; then
       echo "Thin pool acima de $THRESHOLD%: ${USAGE}%" | \
       mail -s "ALERTA: Thin Pool pve/data" admin@fsociety.pt
   fi
   ```

3. **Expandir proativamente**
   - Adicionar espaço antes de atingir 90%

---

## 🐛 Troubleshooting

### Problema: Thin pool cheio

**Sintoma:** Erro ao iniciar VMs ou criar discos

**Solução:**

```bash
# Verificar utilização
lvs pve/data

# Se Data% > 95%, expandir:
lvextend -L +50G /dev/pve/data

# Ou adicionar novo disco e estender VG
pvcreate /dev/sdX
vgextend pve /dev/sdX
lvextend -L +100G /dev/pve/data
```

### Problema: Storage não aparece na Web UI

**Solução:**

```bash
# Verificar ficheiro de configuração
cat /etc/pve/storage.cfg

# Verificar se storage está montado
df -h
mount | grep vz

# Reiniciar serviços
systemctl restart pve-cluster
systemctl restart pvedaemon
```

### Problema: Performance lenta em VMs

**Diagnóstico:**

```bash
# Verificar I/O wait
top
# Observar %wa (I/O wait)

# Ver I/O por disco
iostat -x 2

# Ver VMs com mais I/O
iotop
```

**Solução:**
- Mover VMs críticas para NVMe
- Adicionar mais RAM (cache)
- Considerar SSD adicional

---

## 📖 Próximos Passos

Após configurar storage, prosseguir com:

1. ✅ **Storage Configurado**
2. ➡️ [Criação de VMs](04-criacao-vms.md) - Criar e configurar VMs
3. ➡️ [Backup](05-backup-config.md) - Configurar backups automáticos

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

**[⬅️ Anterior: Configuração de Rede](02-configuracao-rede.md)** | **[Índice](README.md)** | **[Próximo: Criação de VMs ➡️](04-criacao-vms.md)**

</div>

---

*Última atualização: Dezembro 2024*
