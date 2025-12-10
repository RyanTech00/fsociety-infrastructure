# 🔗 Integração com Proxmox VE

> Guia de integração do Proxmox Backup Server com Proxmox VE, incluindo configuração de storage e autenticação.

---

## 📋 Visão Geral

A integração do PBS com o Proxmox VE permite:
- Backups automáticos via vzdump
- Deduplicação e compressão de backups
- Restore direto pela interface do PVE
- Gestão centralizada de backups

---

## 🔐 Obter Fingerprint do PBS

### Via Web UI do PBS

1. Aceder a `https://192.168.1.30:8007`

2. **Dashboard → Configuration → Certificates**

3. Copiar **Fingerprint (SHA256)**

### Via CLI no PBS

```bash
# SSH para o PBS
ssh root@192.168.1.30

# Obter fingerprint
proxmox-backup-manager cert info | grep Fingerprint

# Saída:
# Fingerprint (sha256): XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

---

## 🛠️ Adicionar PBS Storage no Proxmox VE

### Via Web UI

1. **Datacenter → Storage → Add → Proxmox Backup Server**

2. Configurar:

| Campo | Valor |
|-------|-------|
| **ID** | pbs-store |
| **Server** | 192.168.1.30 |
| **Port** | 8007 |
| **Username** | root@pam |
| **Password** | [password do PBS] |
| **Datastore** | pve-store |
| **Namespace** | (vazio) |
| **Fingerprint** | [copiar do PBS] |
| **Content** | VZDump backup files |
| **Enable** | ✅ Sim |
| **Max Backups per VM** | 0 (ilimitado) |

3. Clicar em **Add**

4. Verificar status: deve mostrar "active"

### Via CLI

```bash
# No Proxmox VE
ssh root@192.168.31.34

# Adicionar storage PBS
pvesm add pbs pbs-store \
  --server 192.168.1.30 \
  --datastore pve-store \
  --username root@pam \
  --password '<password>' \
  --fingerprint 'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX' \
  --content backup

# Verificar
pvesm status | grep pbs-store
```

---

## ✅ Verificar Integração

### Teste de Conectividade

```bash
# No Proxmox VE
pvesm status pbs-store

# Saída esperada:
# pbs-store    pbs    active    44040192    41877504    2162688

# Listar conteúdo
pvesm list pbs-store
```

### Teste de Backup Manual

```bash
# Backup de VM de teste
vzdump 102 --storage pbs-store --mode snapshot --compress zstd

# Verificar no PBS
# Web UI → Datastore → pve-store → Content
# Deve aparecer backup de VM 102
```

---

## 🔐 Configurar Encriptação (Opcional)

### Gerar Chave de Encriptação

```bash
# No Proxmox VE
proxmox-backup-client key create /root/backup-encryption-key.json

# ⚠️ IMPORTANTE: Fazer backup da chave!
# Sem a chave, backups NÃO podem ser restaurados
```

### Adicionar Chave ao Storage

**Via Web UI:**

1. **Datacenter → Storage → pbs-store → Edit**

2. **Encryption Key** → Upload `/root/backup-encryption-key.json`

3. Clicar em **OK**

**Via CLI:**

```bash
# Upload da chave
pvesm set pbs-store --encryption-key /root/backup-encryption-key.json
```

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

**[⬅️ Anterior: Datastore](02-datastore.md)** | **[Índice](README.md)** | **[Próximo: Backup Jobs ➡️](04-backup-jobs.md)**

</div>

---

*Última atualização: Dezembro 2025*
