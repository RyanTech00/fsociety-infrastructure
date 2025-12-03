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

### Política de Retenção

```bash
# Configurar política
proxmox-backup-manager datastore update pve-store \
  --keep-last 7 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --keep-yearly 1
```

### Executar Prune

```bash
# Via CLI no PBS
proxmox-backup-client snapshot prune \
  vm/102 \
  --keep-last 7 \
  --repository root@pam@localhost:pve-store

# Via Web UI
# Datastore → pve-store → Prune & GC → Prune
```

---

## 🗄️ Garbage Collection

Remove chunks órfãos e liberta espaço.

### Executar GC

```bash
# Manual
proxmox-backup-manager garbage-collect pve-store

# Agendar semanal (domingo 03:00)
proxmox-backup-manager garbage-collection schedule update pve-store \
  --schedule "sun 03:00"
```

### Monitorizar GC

```bash
# Ver último GC
cat /backup/pve-store/.gc-status

# Logs
journalctl -u proxmox-backup -f | grep gc
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
