# 🔄 Restore de Backups

> Guia de restauro de VMs e ficheiros individuais a partir do Proxmox Backup Server.

---

## 📋 Tipos de Restore

1. **Full VM Restore**: Restaurar VM completa
2. **File-Level Restore**: Restaurar ficheiros específicos
3. **Mount Backup**: Montar backup como filesystem

---

## 🖥️ Restore de VM Completa

### Via Proxmox VE Web UI

1. Selecionar **VM → Backup**

2. Selecionar backup desejado

3. Clicar em **Restore**

4. Configurar:

| Opção | Valor |
|-------|-------|
| **Storage** | pve-nvme ou local-lvm |
| **VM ID** | 102 (mesmo) ou novo ID |
| **Unique** | ✅ Se clonar |
| **Start after restore** | Conforme necessário |

5. Clicar em **Restore**

### Via CLI

```bash
# Listar backups disponíveis
pvesm list pbs-store

# Restaurar para VM original
qmrestore pbs-store:backup/vm/102/2024-12-01T02:00:00Z 102 \
  --storage pve-nvme

# Restaurar para nova VM (clone)
qmrestore pbs-store:backup/vm/102/2024-12-01T02:00:00Z 110 \
  --storage pve-nvme \
  --unique 1
```

---

## 📂 Restore de Ficheiros Individuais

### Montar Backup

```bash
# No PBS ou no PVE (com proxmox-backup-client)
proxmox-backup-client mount \
  vm/105/2024-12-01T02:30:00Z \
  /mnt/backup-mount \
  --repository root@pam@192.168.1.30:pve-store

# Navegar e copiar ficheiros
ls /mnt/backup-mount
cp /mnt/backup-mount/etc/samba/smb.conf /tmp/

# Desmontar
umount /mnt/backup-mount
```

---

## ✅ Verificar Restore

```bash
# Após restore, verificar VM
qm list
qm config 102

# Iniciar VM
qm start 102

# Verificar logs de boot
qm terminal 102
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

**[⬅️ Anterior: Backup Jobs](04-backup-jobs.md)** | **[Índice](README.md)** | **[Próximo: Manutenção ➡️](06-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2024*
