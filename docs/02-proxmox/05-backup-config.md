# 💾 Configuração de Backup - Proxmox VE

> Guia completo de configuração de backups no Proxmox VE, incluindo integração com Proxmox Backup Server, agendamento e encriptação.

---

## 📋 Visão Geral

O Proxmox VE oferece várias opções para backup de VMs e containers:
- **vzdump**: Ferramenta nativa de backup
- **Proxmox Backup Server (PBS)**: Solução dedicada com deduplicação
- **Storage local**: Backups em disco local
- **Storage remoto**: NFS, CIFS, PBS

### Estratégia de Backup do Projeto

```
┌─────────────────────────────────────────────────────────┐
│              Estratégia de Backup FSociety              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Proxmox VE Host (192.168.31.34)                       │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Backup Jobs (vzdump)                            │  │
│  │                                                  │  │
│  │  Job 1: VMID 102 (pfSense)                      │  │
│  │  • Horário: 02:00 (diário)                      │  │
│  │  • Storage: pbs-store                           │  │
│  │  • Modo: snapshot                               │  │
│  │  • Compressão: zstd                             │  │
│  │                                                  │  │
│  │  Job 2: VMID 104, 105, 106                      │  │
│  │  • Horário: 02:30 (diário)                      │  │
│  │  • Storage: pbs-store                           │  │
│  │  • Modo: snapshot                               │  │
│  │  • Compressão: zstd                             │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │                                   │
└─────────────────────┼───────────────────────────────────┘
                      │
                      │ Rede LAN (192.168.1.0/24)
                      │
         ┌────────────▼────────────┐
         │  Proxmox Backup Server  │
         │  192.168.1.30:8007      │
         │                         │
         │  Datastore: pve-store   │
         │  Path: /backup/pve-store│
         │  Capacidade: 42 GB      │
         │  Utilizado: 40 GB (95%) │
         │                         │
         │  Features:              │
         │  • Deduplicação         │
         │  • Encriptação          │
         │  • Verificação          │
         │  • Retenção: keep-all=1 │
         └─────────────────────────┘
```

---

## 🔧 Configuração do PBS no Proxmox VE

### Adicionar PBS Storage via Web UI

1. **Datacenter → Storage → Add → Proxmox Backup Server**

| Campo | Valor |
|-------|-------|
| **ID** | pbs-store |
| **Server** | 192.168.1.30 |
| **Port** | 8007 |
| **Username** | root@pam |
| **Password** | [password do PBS] |
| **Datastore** | pve-store |
| **Namespace** | (vazio) |
| **Fingerprint** | [gerado automaticamente ou copiado do PBS] |
| **Enable** | ✅ Sim |
| **Content** | VZDump backup files |

2. Clicar em **Add**

3. Verificar se storage está ativo:
   - **Datacenter → Storage → pbs-store**
   - Status deve estar "active"

### Adicionar PBS Storage via CLI

```bash
# Obter fingerprint do PBS
# No servidor PBS:
proxmox-backup-manager cert info | grep Fingerprint

# Saída:
# Fingerprint (sha256): XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX

# No Proxmox VE:
pvesm add pbs pbs-store \
  --server 192.168.1.30 \
  --datastore pve-store \
  --username root@pam \
  --password <password> \
  --fingerprint XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX \
  --content backup

# Verificar
pvesm status | grep pbs-store
```

### Configurar Encriptação

A encriptação protege os backups no PBS.

```bash
# Gerar chave de encriptação
proxmox-backup-client key create master-key.json --kdf none

# Guardar chave em local seguro!
# IMPORTANTE: Sem a chave, backups não podem ser restaurados!

# Adicionar fingerprint ao Proxmox VE
# Datacenter → Storage → pbs-store → Edit
# Encryption Key: Upload master-key.json
```

---

## 📅 Backup Jobs

### Job 1: pfSense (VMID 102)

**Configuração:**

| Parâmetro | Valor |
|-----------|-------|
| **Node** | mail |
| **Storage** | pbs-store |
| **Day of week** | Todos os dias |
| **Start Time** | 02:00 |
| **Selection Mode** | Include selected VMs |
| **VMs** | 102 (PfSense) |
| **Mode** | Snapshot |
| **Compression** | ZSTD |
| **Enabled** | ✅ Sim |
| **Email notification** | Always |

**Criar via Web UI:**

1. **Datacenter → Backup → Add**

2. Preencher campos conforme tabela acima

3. **Schedule:** `0 2 * * *` (cron format)

4. Clicar em **Create**

**Criar via CLI:**

```bash
# Criar backup job
vzdump 102 \
  --storage pbs-store \
  --mode snapshot \
  --compress zstd \
  --mailnotification always \
  --mailto admin@fsociety.pt

# Agendar com crontab (alternativa ao Web UI)
cat >> /etc/cron.d/vzdump << EOF
# Backup diário pfSense às 02:00
0 2 * * * root /usr/bin/vzdump 102 --storage pbs-store --mode snapshot --compress zstd --quiet 1 --mailnotification always
EOF
```

### Job 2: Servidores (VMID 104, 105, 106)

**Configuração:**

| Parâmetro | Valor |
|-----------|-------|
| **Node** | mail |
| **Storage** | pbs-store |
| **Day of week** | Todos os dias |
| **Start Time** | 02:30 |
| **Selection Mode** | Include selected VMs |
| **VMs** | 104, 105, 106 |
| **Mode** | Snapshot |
| **Compression** | ZSTD |
| **Enabled** | ✅ Sim |
| **Email notification** | On failure |

**Criar via CLI:**

```bash
# Backup múltiplas VMs
vzdump 104 105 106 \
  --storage pbs-store \
  --mode snapshot \
  --compress zstd \
  --mailnotification failure \
  --mailto admin@fsociety.pt

# Agendar
cat >> /etc/cron.d/vzdump << EOF
# Backup diário servidores às 02:30
30 2 * * * root /usr/bin/vzdump 104 105 106 --storage pbs-store --mode snapshot --compress zstd --quiet 1 --mailnotification failure
EOF
```

---

## ⚙️ Modos de Backup

### Snapshot Mode (Recomendado)

- **Vantagem**: Zero downtime, backup consistente
- **Requisitos**: LVM-Thin ou ZFS
- **Uso**: VMs em produção

```bash
vzdump <vmid> --mode snapshot
```

### Stop Mode

- **Vantagem**: Backup mais rápido e consistente
- **Desvantagem**: VM é parada durante backup
- **Uso**: VMs não-críticas ou manutenção programada

```bash
vzdump <vmid> --mode stop
```

### Suspend Mode

- **Vantagem**: Pausa VM (mantém estado de memória)
- **Desvantagem**: VM não disponível durante backup
- **Uso**: Casos específicos

```bash
vzdump <vmid> --mode suspend
```

---

## 🗜️ Compressão

### Algoritmos Disponíveis

| Algoritmo | Velocidade | Ratio | Uso CPU | Recomendado |
|-----------|------------|-------|---------|-------------|
| **zstd** | Rápida | Bom | Moderado | ✅ Sim (default) |
| **lzo** | Muito rápida | Fraco | Baixo | Backups rápidos |
| **gzip** | Moderada | Bom | Moderado | Compatibilidade |

```bash
# ZSTD (recomendado)
vzdump <vmid> --compress zstd

# LZO (mais rápido, menos compressão)
vzdump <vmid> --compress lzo

# GZIP (compatibilidade)
vzdump <vmid> --compress gzip
```

---

## 🔐 Encriptação de Backups

### Configurar no Backup Job

```bash
# Gerar chave de encriptação
proxmox-backup-client key create /root/backup-encryption-key.json

# Backup com encriptação
vzdump <vmid> \
  --storage pbs-store \
  --mode snapshot \
  --compress zstd \
  --notes-template "{{guestname}} - {{vmid}} - {{cluster}}"

# Nota: Encriptação é configurada no PBS, não no vzdump
```

### No Proxmox Backup Server

1. **Configuration → Encryption**

2. Upload da chave de encriptação

3. Todos os backups serão automaticamente encriptados

> **⚠️ IMPORTANTE**: Guardar chave de encriptação em local seguro!  
> Sem a chave, backups NÃO podem ser restaurados!

---

## 📊 Políticas de Retenção

### Configurar Retenção no PBS

**Via Web UI do PBS:**

1. Aceder a `http://192.168.1.30:8007`

2. **Datastore → pve-store → Prune & GC**

3. Configurar política:

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **Keep Last** | 7 | Manter últimos 7 backups |
| **Keep Daily** | 7 | Manter 1 backup por dia (7 dias) |
| **Keep Weekly** | 4 | Manter 1 backup por semana (4 semanas) |
| **Keep Monthly** | 3 | Manter 1 backup por mês (3 meses) |
| **Keep Yearly** | 1 | Manter 1 backup por ano |

**Via CLI do PBS:**

```bash
# No servidor PBS
proxmox-backup-manager datastore update pve-store \
  --keep-last 7 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --keep-yearly 1
```

### Configuração Atual do Projeto

```bash
# Projeto FSociety: keep-all=1
# Mantém todos os backups (1 de cada)
# Útil para testing/development
# PRODUÇÃO: Usar política mais robusta acima
```

---

## 🔄 Restore de Backups

### Via Web UI

1. **Selecionar VM** (ex: VMID 102)

2. **Backup** (tab no painel da VM)

3. Selecionar backup e clicar em **Restore**

4. Configurar:

| Opção | Descrição |
|-------|-----------|
| **Storage** | Storage de destino |
| **VM ID** | Mesmo ID ou novo |
| **Unique** | Gerar novos MACs (se clonar) |
| **Start after restore** | Iniciar automaticamente |

5. Clicar em **Restore**

### Via CLI

```bash
# Listar backups disponíveis
pvesm list pbs-store

# Saída:
# pbs-store:backup/vm/102/2025-12-01T02:00:00Z
# pbs-store:backup/vm/104/2025-12-01T02:30:00Z

# Restaurar para VM original
qmrestore pbs-store:backup/vm/102/2025-12-01T02:00:00Z 102 \
  --storage pve-nvme

# Restaurar para nova VM (clone)
qmrestore pbs-store:backup/vm/102/2025-12-01T02:00:00Z 110 \
  --storage pve-nvme \
  --unique 1

# Restaurar e iniciar
qmrestore pbs-store:backup/vm/102/2025-12-01T02:00:00Z 102 \
  --storage pve-nvme \
  --start 1
```

### Restauro de Ficheiros Individuais

PBS permite restaurar ficheiros específicos sem restaurar VM completa.

```bash
# Montar backup como filesystem
proxmox-backup-client mount \
  backup/vm/105/2025-12-01T02:30:00Z \
  /mnt/backup-mount

# Copiar ficheiros necessários
cp /mnt/backup-mount/etc/samba/smb.conf /tmp/

# Desmontar
umount /mnt/backup-mount
```

---

## 📧 Notificações por Email

### Configurar Email no Proxmox VE

```bash
# Editar configuração
nano /etc/pve/datacenter.cfg

# Adicionar:
email_from: proxmox@fsociety.pt
http: proxmox-ve.fsociety.pt

# Configurar Postfix
dpkg-reconfigure postfix
# Selecionar: Satellite system
# Smarthost: [seu servidor SMTP]

# Testar email
echo "Teste de backup Proxmox" | mail -s "Teste Backup" admin@fsociety.pt
```

### Configurar Notificações em Backup Jobs

```bash
# Always: Sempre notificar
--mailnotification always

# On failure: Apenas se falhar
--mailnotification failure

# Never: Nunca notificar
--mailnotification never
```

---

## 🛠️ Gestão de Backups

### Listar Backups

```bash
# Via CLI
pvesm list pbs-store

# Ver detalhes de um backup
proxmox-backup-client snapshot list \
  --repository root@pam@192.168.1.30:pve-store

# Via Web UI
# Storage → pbs-store → Content
```

### Remover Backups Antigos

```bash
# Remover backup específico via Web UI
# Storage → pbs-store → Content → Selecionar → Remove

# Via CLI (no PBS)
proxmox-backup-client snapshot remove \
  vm/102/2025-11-01T02:00:00Z \
  --repository root@pam@localhost:pve-store
```

### Verificar Integridade

```bash
# No PBS
proxmox-backup-client snapshot verify \
  vm/102/2025-12-01T02:00:00Z \
  --repository root@pam@localhost:pve-store

# Verificar todos os backups
proxmox-backup-manager verify-job create datastore1 \
  --schedule daily
```

---

## 🎯 Boas Práticas

### 1. Testar Restores Regularmente

```bash
# Mensalmente, restaurar backup para testar
qmrestore pbs-store:backup/vm/102/latest 999 --storage local-lvm
qm start 999
# Verificar funcionamento
qm destroy 999
```

### 2. Monitorizar Espaço do PBS

```bash
# Verificar espaço
pvesm status | grep pbs-store

# Se > 90%, aumentar storage ou ajustar retenção
```

### 3. Backup da Configuração do Proxmox VE

```bash
# Backup manual da configuração
tar czf /var/lib/vz/dump/pve-config-$(date +%Y%m%d).tar.gz \
  /etc/pve \
  /etc/network/interfaces \
  /etc/hosts

# Agendar backup semanal
cat >> /etc/cron.d/pve-config-backup << EOF
# Backup configuração PVE todas as segundas às 01:00
0 1 * * 1 root tar czf /var/lib/vz/dump/pve-config-\$(date +\%Y\%m\%d).tar.gz /etc/pve /etc/network/interfaces /etc/hosts
EOF
```

### 4. Documentar Chaves de Encriptação

- Guardar chaves em cofre seguro
- Documentar localização
- Testar restore com chave

### 5. Offsite Backup

Para máxima segurança, considerar:
- Backup do PBS para storage externo
- Replicação para outro datacenter
- Cloud backup (S3, etc.)

---

## 🐛 Troubleshooting

### Problema: Backup falha com "out of space"

**Solução:**

```bash
# Verificar espaço no PBS
pvesm status | grep pbs-store

# No PBS, executar garbage collection
proxmox-backup-manager garbage-collect pve-store

# Ajustar política de retenção
# Remover backups antigos manualmente se necessário
```

### Problema: Backup muito lento

**Diagnóstico:**

```bash
# Ver progresso
tail -f /var/log/pve/tasks/active

# Ver I/O
iostat -x 2
```

**Soluções:**

1. Usar compressão mais rápida (lzo)
2. Agendar durante horários de baixa utilização
3. Verificar rede entre PVE e PBS
4. Considerar storage mais rápido

### Problema: Não consigo restaurar backup encriptado

**Causa:** Chave de encriptação perdida ou incorreta

**Solução:**

1. Localizar chave de encriptação backup
2. Importar chave no PBS
3. Tentar restore novamente

> Se chave foi perdida, backup NÃO pode ser recuperado!

---

## 📖 Próximos Passos

Após configurar backups:

1. ✅ **Backups Configurados**
2. ➡️ [Manutenção](06-manutencao.md) - Atualizações e monitorização
3. ➡️ [PBS Documentation](../07-proxmox-backup/README.md) - Detalhes do PBS

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

**[⬅️ Anterior: Criação de VMs](04-criacao-vms.md)** | **[Índice](README.md)** | **[Próximo: Manutenção ➡️](06-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2025*
