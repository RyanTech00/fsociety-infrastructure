# 🖥️ Proxmox VE - FSociety.pt

> **Plataforma de Virtualização da Infraestrutura**  
>  
> Documentação completa do Proxmox Virtual Environment da infraestrutura FSociety.pt, incluindo configuração de rede, storage, VMs e backup.

---

## 📋 Informação do Sistema

| Campo | Valor |
|-------|-------|
| **Hostname** | mail.fsociety.pt |
| **Versão** | Proxmox VE 9.0.3 |
| **Kernel** | 6.14.8-2-pve |
| **CPU** | Intel Core i5-7300HQ @ 2.50GHz (4 cores, 1 thread/core) |
| **RAM Total** | 16 GB |
| **RAM Utilizada** | ~12 GB |
| **Swap** | 8 GB |
| **Disco** | HDD 1TB + NVMe 224GB |

---

## 🏗️ Arquitetura de Virtualização

```
┌────────────────────────────────────────────────────────────────┐
│             Proxmox VE Host (mail.fsociety.pt)                 │
│                    192.168.31.34/24                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Storage Pools:                                                │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   local     │  │  local-lvm   │  │  pve-nvme    │          │
│  │   96 GB     │  │  794 GB      │  │  200 GB      │          │
│  │   (37%)     │  │  (15%)       │  │  (12%)       │          │
│  │  dir/HDD    │  │ lvmthin/HDD  │  │ lvmthin/NVMe │          │
│  └─────────────┘  └──────────────┘  └──────────────┘          │
│                                                                │
│  Network Bridges:                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  vmbr0 (WAN): 192.168.31.34/24 - USB Ethernet           │ │
│  │  vmbr1 (LAN): 192.168.1.0/24 - Manual                   │ │
│  │  DMZ: 10.0.0.0/24 - Manual                              │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  Virtual Machines:                                             │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ 101: Proxmox-Backup    | 1.5GB RAM | local-lvm | LAN   │  │
│  │ 102: PfSense           | 2GB RAM   | pve-nvme  | ALL   │  │
│  │ 104: Web-Server        | 1GB RAM   | local-lvm | DMZ   │  │
│  │ 105: Servidor-dominio  | 2GB RAM   | pve-nvme  | LAN   │  │
│  │ 106: Servidor-Ficheiros| 2GB RAM   | local-lvm | LAN   │  │
│  │ 107: Ubuntu-Desktop    | 2GB RAM   | -         | -     │  │
│  │ 108: mailcow           | 6GB RAM   | local-lvm | DMZ   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 💾 Storage Configuration

| Nome | Tipo | Tamanho Total | Utilizado | Conteúdo | Dispositivo |
|------|------|---------------|-----------|----------|-------------|
| **local** | dir | 96 GB | 37% (36 GB) | backup, iso, vztmpl | /dev/sda (HDD) |
| **local-lvm** | lvmthin | 794 GB | 15% (119 GB) | images, rootdir | /dev/sda (HDD) |
| **pve-nvme** | lvmthin | 200 GB | 12% (24 GB) | images, rootdir | /dev/nvme0n1 (NVMe) |
| **pbs-store** | pbs | 42 GB | 95% (40 GB) | backup | Remoto (192.168.1.30) |

### Discos Físicos

| Dispositivo | Tipo | Capacidade | Utilização |
|-------------|------|------------|------------|
| **sda** | HDD | 931.5 GB | pve-root (96GB) + pve-data (794GB) |
| **nvme0n1** | NVMe SSD | 223.6 GB | pve-nvme-data (200GB) + swap (8GB) |

---

## 🔌 Network Bridges

| Bridge | Endereço IP | Função | Interface Física |
|--------|-------------|--------|------------------|
| **vmbr0** | 192.168.31.34/24 | WAN - Acesso Internet | enx2c16dba588ba (USB Ethernet) |
| **vmbr1** | - (manual) | LAN - Rede Interna (192.168.1.0/24) | none (bridge virtual) |
| **DMZ** | - (manual) | DMZ - Zona Desmilitarizada (10.0.0.0/24) | none (bridge virtual) |

---

## 🖥️ Máquinas Virtuais

| VMID | Nome | Estado | RAM | vCPU | Disco | Storage | IP | Função |
|------|------|--------|-----|------|-------|---------|-----|--------|
| **101** | Proxmox-Backup | ✅ Running | 1.5 GB | 1 | 50 GB | local-lvm | 192.168.1.30 | PBS |
| **102** | PfSense | ✅ Running | 2 GB | 2 | 50 GB | pve-nvme | 192.168.1.1 | Firewall/Router |
| **104** | Web-Server | ✅ Running | 1 GB | 1 | 50 GB | local-lvm | 10.0.0.30 | Nginx DMZ |
| **105** | Servidor-de-dominio | ✅ Running | 2 GB | 2 | 50 GB | pve-nvme | 192.168.1.10 | Samba AD DC |
| **106** | Servidor-de-Ficheiros | ✅ Running | 2 GB | 4 | 50 GB | local-lvm | 192.168.1.40 | Nextcloud/Zammad |
| **107** | Ubuntu-Desktop | ⏸️ Stopped | 2 GB | 2 | 50 GB | - | - | Testes |
| **108** | mailcow | ✅ Running | 6 GB | 2 | - | local-lvm | 10.0.0.20 | Email |

**Total de recursos alocados:**
- RAM: 16.5 GB alocados (16 GB disponíveis)
- vCPUs: 14 cores alocados (4 cores físicos)
- Disco: ~350 GB alocados

---

## 📦 Backup Jobs (vzdump)

| VMs | Horário | Storage | Modo | Compressão | Retenção |
|-----|---------|---------|------|------------|----------|
| **102** (pfSense) | 02:00 | pbs-store | snapshot | zstd | keep-all=1 |
| **104, 105, 106** | 02:30 | pbs-store | snapshot | zstd | keep-all=1 |

**Configuração de Backup:**
- Modo: Snapshot (sem downtime)
- Compressão: zstd (rápido e eficiente)
- Destino: Proxmox Backup Server (192.168.1.30)
- Encriptação: Ativa

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Instalação](01-instalacao.md) | Instalação do Proxmox VE e configuração inicial |
| 2 | [Configuração de Rede](02-configuracao-rede.md) | Bridges, VLANs e diagrama de rede |
| 3 | [Storage](03-storage.md) | Configuração de storage pools e LVM |
| 4 | [Criação de VMs](04-criacao-vms.md) | Criação e configuração de VMs |
| 5 | [Backup e PBS](05-backup-config.md) | Integração com Proxmox Backup Server |
| 6 | [Manutenção](06-manutencao.md) | Atualizações, monitorização e troubleshooting |

---

## 🔗 Integrações

```
                     ┌─────────────────────┐
                     │   Proxmox VE Host   │
                     │  192.168.31.34      │
                     └──────────┬──────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│  Proxmox      │      │   pfSense     │      │   VMs em      │
│  Backup       │      │   Firewall    │      │   Produção    │
│  Server       │      │               │      │               │
│  192.168.1.30 │      │ 192.168.1.1   │      │ 7 VMs ativas  │
└───────────────┘      └───────────────┘      └───────────────┘
```

| Integração | Tipo | Descrição |
|------------|------|-----------|
| **PBS (192.168.1.30)** | Backup | Backups agendados automáticos |
| **pfSense (VMID 102)** | Rede | Firewall e gateway para todas as VMs |
| **Storage NVMe** | Performance | VMs críticas (pfSense, DC) |
| **Storage HDD** | Capacidade | VMs de serviços gerais |

---

## 📊 Estatísticas de Utilização

| Métrica | Valor |
|---------|-------|
| **VMs em Execução** | 6 de 7 |
| **Utilização CPU** | ~45% (média) |
| **Utilização RAM** | 75% (12GB/16GB) |
| **Storage local** | 37% utilizado |
| **Storage local-lvm** | 15% utilizado |
| **Storage pve-nvme** | 12% utilizado |
| **Uptime Médio** | 99.5% |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

## 📖 Referências

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Proxmox Community Forum](https://forum.proxmox.com/)

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Instalação ➡️](01-instalacao.md)**

</div>

---

*Última atualização: Dezembro 2025*
