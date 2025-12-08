# 📅 Backup Jobs e Políticas

> Configuração de backup jobs automáticos, políticas de retenção e notificações.

---

## 📋 Backup Jobs Configurados

### Resumo dos Jobs Agendados

| VMs | Nome | Schedule | Storage | Modo | Compressão |
|-----|------|----------|---------|------|------------|
| 102 | pfSense | 02:00 diário | pbs-store | snapshot | zstd |
| 104, 105, 106, 108 | Web-Server, DC, Files | 02:30 diário | pbs-store | snapshot | zstd |

### Job 1: pfSense (VMID 102)

| Parâmetro | Valor |
|-----------|-------|
| **Schedule** | 02:00 diário |
| **VMs** | 102 (pfSense) |
| **Storage** | pbs-store |
| **Mode** | snapshot |
| **Compression** | zstd |
| **Retention** | keep-all=1 |

### Job 2: Servidores (VMID 104, 105, 106)

| Parâmetro | Valor |
|-----------|-------|
| **Schedule** | 02:30 diário |
| **VMs** | 104 (Web-Server), 105 (Servidor-de-dominio), 106 (Servidor-de-Ficheiros) |
| **Storage** | pbs-store |
| **Mode** | snapshot |
| **Compression** | zstd |
| **Retention** | keep-all=1 |

### Estado dos Backups Existentes

| VM | Nome | Último Backup | Quantidade |
|----|------|---------------|------------|
| 100 | (removida) | 2025-11-06 | 4 |
| 102 | pfSense | 2025-12-01 | 4 |
| 103 | (removida) | 2025-11-06 | 4 |
| 104 | Web-Server | 2025-12-01 | 4 |
| 105 | Servidor-de-dominio | 2025-11-06 | 3 |
| 106 | Servidor-de-Ficheiros | 2025-11-06 | 3 |
| 108 | mailcow | (pendente) | 0 |

---

## ⚙️ Configurar Backup Jobs

### Via Proxmox VE Web UI

1. **Datacenter → Backup → Add**

2. Configurar job:

| Campo | Valor |
|-------|-------|
| **Node** | mail |
| **Storage** | pbs-store |
| **Schedule** | 02:00 |
| **Day of week** | mon,tue,wed,thu,fri,sat,sun |
| **Selection mode** | Include selected VMs |
| **VM Selection** | 102 |
| **Send email to** | admin@fsociety.pt |
| **Email** | On failure |
| **Compression** | ZSTD |
| **Mode** | Snapshot |
| **Enable** | ✅ Sim |

3. Clicar em **Create**

---

## 📊 Monitorizar Backups

### Via PBS Web UI

**Datastore → pve-store → Content**

Ver:
- Lista de backups por VM
- Timestamp de cada backup
- Tamanho
- Status de verificação

### Logs de Backup

```bash
# No Proxmox VE
grep vzdump /var/log/syslog | tail -50

# No PBS
journalctl -u proxmox-backup -f
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

**[⬅️ Anterior: Integração PVE](03-integracao-pve.md)** | **[Índice](README.md)** | **[Próximo: Restore ➡️](05-restore.md)**

</div>

---

*Última atualização: Dezembro 2024*
