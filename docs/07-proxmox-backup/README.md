# 💾 Proxmox Backup Server - FSociety.pt

> **Sistema de Backup Deduplicado e Encriptado**  
>  
> Documentação completa do Proxmox Backup Server da infraestrutura FSociety.pt, incluindo datastore, integração com Proxmox VE e gestão de backups.

---

## 📋 Informação do Servidor

| Campo | Valor |
|-------|-------|
| **Hostname** | pbs.fsociety.pt |
| **Endereço IP** | 192.168.1.30/24 |
| **Versão PBS** | 4.0.11 (package 4.1.0-1) |
| **Sistema Operativo** | Proxmox Backup Server (Debian-based) |
| **Kernel** | 6.8.x |
| **VM ID** | 101 (no Proxmox VE) |
| **RAM** | 1.5 GB |
| **vCPU** | 1 core |
| **Disco** | 850 GB (expandido de 50 GB) |
| **Zona de Rede** | LAN (192.168.1.0/24) |

---

## 🏗️ Arquitetura de Backup

```
┌────────────────────────────────────────────────────────────┐
│           Infraestrutura de Backup FSociety                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  Proxmox VE Host (192.168.31.34)                     │ │
│  │                                                      │ │
│  │  VMs em Produção:                                    │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │ │
│  │  │ pfSense │ │Web Srv  │ │   DC    │ │  Files  │  │ │
│  │  │  (102)  │ │ (104)   │ │  (105)  │ │  (106)  │  │ │
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘  │ │
│  │       │           │           │           │        │ │
│  │       └───────────┴───────────┴───────────┘        │ │
│  │                       │                            │ │
│  │              vzdump (snapshot mode)                │ │
│  │                       │                            │ │
│  │                       ▼                            │ │
│  │              ┌─────────────────┐                   │ │
│  │              │   pbs-store     │                   │ │
│  │              │ (PBS Storage)   │                   │ │
│  │              └────────┬────────┘                   │ │
│  └───────────────────────┼──────────────────────────┘ │
│                          │                            │
│                          │ Rede LAN                   │
│                          │ 192.168.1.0/24             │
│                          │                            │
│  ┌───────────────────────▼──────────────────────────┐ │
│  │  Proxmox Backup Server (192.168.1.30)           │ │
│  │                                                  │ │
│  │  ┌────────────────────────────────────────────┐ │ │
│  │  │  Datastore: pve-store                      │ │ │
│  │  │  Path: /backup/pve-store                   │ │ │
│  │  │                                            │ │ │
│  │  │  Features:                                 │ │ │
│  │  │  • Deduplicação (chunk-based)             │ │ │
│  │  │  • Compressão (zstd)                      │ │ │
│  │  │  • Encriptação (AES-256)                  │ │ │
│  │  │  • Verificação de integridade             │ │ │
│  │  │  • Retenção: keep-all=1                   │ │ │
│  │  │                                            │ │ │
│  │  │  Capacidade: 42 GB                         │ │ │
│  │  │  Utilizado: 40 GB (95%)                    │ │ │
│  │  │  Disponível: 2 GB                          │ │ │
│  │  └────────────────────────────────────────────┘ │ │
│  │                                                  │ │
│  │  Backups Agendados:                              │ │
│  │  • 02:00 - pfSense (102)                        │ │
│  │  • 02:30 - Web, DC, Files (104, 105, 106)      │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 💾 Datastore Configurado

### pve-store

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | pve-store |
| **Path** | /backup/pve-store |
| **Capacidade Total** | 834 GB |
| **Utilizado** | 41 GB (5%) |
| **Disponível** | 762 GB |
| **Garbage Collection** | Ativo (semanal) |
| **Verify Job** | Configurado |
| **Prune Schedule** | daily (PBS 4.x) |

**Conteúdo:**
- Backups de VMs do Proxmox VE
- Snapshots incrementais
- Metadados e índices
- Chunks deduplica dos

---

## 🔐 Segurança e Encriptação

### Encriptação

| Aspecto | Configuração |
|---------|--------------|
| **Método** | AES-256-GCM |
| **Key Storage** | Client-side (Proxmox VE) |
| **Fingerprint** | Configurado no PVE |
| **Status** | Ativa |

**Características:**
- ✅ Encriptação end-to-end
- ✅ Chave gerida no cliente (PVE)
- ✅ PBS não tem acesso aos dados decifrados
- ⚠️ Backup da chave é CRÍTICO

### Autenticação

| Método | Detalhes |
|--------|----------|
| **Utilizador** | root@pam |
| **Email** | hugodanielsilvacorreia@gmail.com |
| **API Token** | Configurado para PVE |
| **TLS/SSL** | Certificado auto-assinado |
| **Port** | 8007 (HTTPS) |

---

## 📊 Estatísticas de Backup

### Resumo de Utilização

| Métrica | Valor |
|---------|-------|
| **Total de Backups** | ~20 (estimado) |
| **VMs com Backup** | 4 (102, 104, 105, 106) |
| **Frequência** | Diária |
| **Taxa de Deduplicação** | ~60-70% (estimado) |
| **Compressão** | zstd |
| **Taxa de Sucesso** | 95%+ |

### Tamanho dos Backups (Estimado)

| VM | Disco Alocado | Backup Size (aprox) |
|----|---------------|---------------------|
| **102 (pfSense)** | 50 GB | ~8 GB |
| **104 (Web-Server)** | 50 GB | ~10 GB |
| **105 (DC)** | 50 GB | ~12 GB |
| **106 (Files)** | 50 GB | ~15 GB |

> **Nota**: Tamanhos reais variam devido a deduplicação e compressão

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Instalação do PBS como VM |
| 2 | [Datastore](02-datastore.md) | Configuração do datastore pve-store |
| 3 | [Integração PVE](03-integracao-pve.md) | Adicionar PBS ao Proxmox VE |
| 4 | [Backup Jobs](04-backup-jobs.md) | Agendamento e políticas |
| 5 | [Restore](05-restore.md) | Restauro de VMs e ficheiros |
| 6 | [Manutenção](06-manutencao.md) | Prune, GC e monitorização |

---

## 🔗 Integrações

```
                    ┌─────────────────────┐
                    │  Proxmox VE Host    │
                    │  192.168.31.34      │
                    │                     │
                    │  Storage: pbs-store │
                    └──────────┬──────────┘
                               │
                               │ HTTPS (8007)
                               │ API Calls
                               │
                ┌──────────────▼─────────────┐
                │  Proxmox Backup Server     │
                │  192.168.1.30              │
                │                            │
                │  • Recebe backups          │
                │  • Deduplica chunks        │
                │  • Comprime dados          │
                │  • Encripta (se ativo)     │
                │  • Verifica integridade    │
                └────────────────────────────┘
```

### Fluxo de Backup

1. **Proxmox VE** inicia backup job (vzdump)
2. **Snapshot** da VM é criado (sem downtime)
3. **Dados** são lidos do snapshot
4. **Chunks** são criados e deduplica dos
5. **Compressão** zstd é aplicada
6. **Encriptação** (opcional) é aplicada
7. **Transfer** para PBS via HTTPS
8. **PBS** armazena chunks no datastore
9. **Metadata** e índice são atualizados
10. **Notificação** de sucesso/falha

---

## 🎯 Vantagens do PBS

### vs. Backup Tradicional (vzdump local)

| Aspecto | PBS | vzdump local |
|---------|-----|--------------|
| **Deduplicação** | ✅ Sim | ❌ Não |
| **Compressão** | ✅ zstd | ⚠️ gzip/lzo |
| **Encriptação** | ✅ AES-256 | ❌ Não |
| **Incremental** | ✅ Chunk-based | ⚠️ Full only |
| **Verificação** | ✅ Automática | ❌ Manual |
| **Restore** | ✅ Rápido | ⚠️ Lento |
| **Espaço** | ✅ Eficiente | ❌ Redundante |

### Funcionalidades Principais

1. **Deduplicação Chunk-Based**
   - Blocos duplicados são armazenados uma vez
   - Economia de 60-80% de espaço

2. **Incremental Forever**
   - Apenas mudanças são backup
   - Sem necessidade de full backups periódicos

3. **Verificação de Integridade**
   - Checksums de todos os chunks
   - Deteção de corrupção

4. **Restore Rápido**
   - Restore de VMs completas
   - Restore de ficheiros individuais
   - Mount de backups como filesystem

5. **Gestão Centralizada**
   - Interface web intuitiva
   - API completa
   - Múltiplos datastores

---

## 📊 Dashboard e Monitorização

### Métricas Disponíveis

**Via Web UI (https://192.168.1.30:8007)**

1. **Dashboard**
   - Status do servidor
   - Utilização de recursos
   - Últimos backups
   - Tarefas ativas

2. **Datastore**
   - Capacidade total/usada
   - Número de backups
   - Taxa de deduplicação
   - Últim o GC

3. **Tasks**
   - Backups em progresso
   - Histórico de tarefas
   - Logs detalhados

4. **Content**
   - Lista de backups por VM
   - Snapshots disponíveis
   - Tamanho e data

---

## 🔧 Acesso e Gestão

### Interface Web

```
URL: https://192.168.1.30:8007
Utilizador: root@pam
Password: [configurado na instalação]
```

### CLI (SSH)

```bash
# Conectar via SSH
ssh root@192.168.1.30

# Comandos principais
proxmox-backup-manager datastore list
proxmox-backup-manager garbage-collect
proxmox-backup-manager verify
```

### API

```bash
# Endpoint da API
https://192.168.1.30:8007/api2/json

# Autenticação via token
# Configurado no PVE storage
```

---

## ✅ Estado Atual da Capacidade

### Capacidade Após Expansão

| Métrica | Valor | Status |
|---------|-------|--------|
| **Capacidade** | 834 GB | ✅ Adequado |
| **Utilizado** | 41 GB | ✅ 5% |
| **Disponível** | 762 GB | ✅ Excelente |

> **Nota**: ext4 reserva ~4% para root (≈31 GB), por isso a soma não é exata.

**Ações Tomadas:**

1. ✅ **Disco Expandido**
   - De 50 GB para 850 GB
   - Procedimento documentado em [Manutenção](06-manutencao.md)

2. ✅ **Garbage Collection**
   - Recuperados 4.6 GB
   - Taxa de deduplicação: 26.53x

3. ✅ **Prune-Jobs Configurados**
   - Schedule: daily
   - Keep-daily: 7, Keep-weekly: 4, Keep-monthly: 6

---

## 📖 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| **PBS Documentation** | https://pbs.proxmox.com/docs/ |
| **PBS Admin Guide** | https://pbs.proxmox.com/docs/administration-guide.html |
| **PBS API** | https://pbs.proxmox.com/docs/api-viewer/index.html |
| **PBS Forum** | https://forum.proxmox.com/forums/proxmox-backup-server.61/ |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2024*
