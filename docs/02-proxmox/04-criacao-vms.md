# 🖥️ Criação de VMs - Proxmox VE

> Guia completo de criação e configuração de máquinas virtuais no Proxmox VE, incluindo exemplos das VMs do projeto FSociety.

---

## 📋 Visão Geral

O Proxmox VE suporta criação de VMs via interface web (GUI) e linha de comandos (CLI). Este guia cobre ambos os métodos e detalha a configuração de cada VM do projeto.

---

## 🛠️ Criação de VM via Web UI

### Passo a Passo

1. **Clicar em "Create VM"** no canto superior direito

2. **General Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Node** | Node onde criar a VM | mail |
| **VM ID** | ID único (100-999999) | 102 |
| **Name** | Nome da VM | PfSense |
| **Resource Pool** | Pool opcional | (vazio) |
| **Start at boot** | Iniciar automaticamente | ✅ |

3. **OS Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Use CD/DVD disc image** | Usar ISO | ✅ |
| **Storage** | Storage do ISO | local |
| **ISO image** | Ficheiro ISO | pfSense-CE-2.8.1.iso |
| **Type** | Tipo de SO | Other |
| **Guest OS** | Sistema operativo | Other |

4. **System Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Graphic card** | Placa gráfica | Default |
| **Machine** | Tipo de máquina | Default (i440fx) |
| **SCSI Controller** | Controlador SCSI | VirtIO SCSI single |
| **BIOS** | Tipo de BIOS | Default (SeaBIOS) |
| **Add TPM** | Trusted Platform Module | ❌ |
| **Qemu Agent** | Agente QEMU | ✅ (para Linux) |

5. **Disks Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Bus/Device** | Tipo de disco | SCSI / VirtIO Block 0 |
| **Storage** | Storage pool | pve-nvme |
| **Disk size (GiB)** | Tamanho do disco | 50 |
| **Cache** | Modo de cache | Write back (default) |
| **Discard** | TRIM/Discard | ✅ (para SSD) |
| **SSD emulation** | Emular SSD | ✅ (se SSD) |
| **IO thread** | Thread de I/O dedicada | ✅ |

6. **CPU Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Sockets** | Número de sockets | 1 |
| **Cores** | Cores por socket | 2 |
| **Type** | Tipo de CPU | host (ou kvm64) |
| **CPU units** | Prioridade CPU (100-500000) | 1024 (default) |

7. **Memory Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Memory (MiB)** | RAM total | 2048 |
| **Minimum memory** | RAM mínima (ballooning) | 512 |
| **Ballooning Device** | Dispositivo de ballooning | ✅ |

8. **Network Tab**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Bridge** | Bridge de rede | vmbr0 |
| **VLAN Tag** | Tag VLAN (opcional) | (vazio) |
| **Model** | Modelo de NIC | VirtIO (paravirtualized) |
| **MAC address** | Endereço MAC | (auto) |
| **Firewall** | Firewall da bridge | ❌ |
| **Disconnect** | Iniciar desconectada | ❌ |

9. **Confirm**

Rever todas as configurações e clicar em **Finish**

---

## 💻 Criação de VM via CLI

### Sintaxe Básica

```bash
# Criar VM básica
qm create <vmid> \
  --name <nome> \
  --memory <ram-mb> \
  --cores <num-cores> \
  --net0 virtio,bridge=<bridge> \
  --scsi0 <storage>:<size>

# Exemplo completo
qm create 105 \
  --name Servidor-de-dominio \
  --memory 2048 \
  --cores 2 \
  --sockets 1 \
  --cpu host \
  --ostype l26 \
  --net0 virtio,bridge=vmbr1,firewall=0 \
  --scsi0 pve-nvme:50 \
  --scsihw virtio-scsi-pci \
  --boot order=scsi0 \
  --onboot 1 \
  --agent 1
```

### Comandos Úteis

```bash
# Listar todas as VMs
qm list

# Ver configuração de uma VM
qm config <vmid>

# Modificar configuração
qm set <vmid> --<parametro> <valor>

# Iniciar VM
qm start <vmid>

# Parar VM
qm stop <vmid>

# Reiniciar VM
qm reboot <vmid>

# Remover VM
qm destroy <vmid>

# Clonar VM
qm clone <vmid> <novo-vmid> --name <novo-nome>
```

---

## 🔧 VMs do Projeto FSociety

### VMID 101: Proxmox-Backup

**Função:** Proxmox Backup Server  
**SO:** Proxmox Backup Server 4.0.11

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 101 |
| **Nome** | Proxmox-Backup |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 1536 MB (1.5 GB) |
| **vCPU** | 1 core |
| **Disco** | 50 GB |
| **Storage** | local-lvm (HDD) |
| **Network** | vmbr1 (LAN) |
| **IP** | 192.168.1.30/24 |
| **Gateway** | 192.168.1.1 (pfSense) |

**Criação via CLI:**

```bash
qm create 101 \
  --name Proxmox-Backup \
  --memory 1536 \
  --cores 1 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --scsihw virtio-scsi-pci \
  --onboot 1 \
  --agent 1
```

---

### VMID 102: PfSense

**Função:** Firewall e Router (Four-Legged)  
**SO:** pfSense CE 2.8.1 (FreeBSD 15.0-CURRENT)

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 102 |
| **Nome** | PfSense |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 2048 MB (2 GB) |
| **vCPU** | 2 cores |
| **Disco** | 50 GB |
| **Storage** | pve-nvme (NVMe) |
| **Network 0** | vmbr0 (WAN) - 192.168.31.100/24 |
| **Network 1** | vmbr1 (LAN) - 192.168.1.1/24 |
| **Network 2** | DMZ - 10.0.0.1/24 |

**Criação via CLI:**

```bash
qm create 102 \
  --name PfSense \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1 \
  --net2 virtio,bridge=DMZ \
  --scsi0 pve-nvme:50 \
  --scsihw virtio-scsi-pci \
  --onboot 1
```

> **Nota:** pfSense não usa qemu-agent (FreeBSD)

---

### VMID 104: Web-Server

**Função:** Nginx Reverse Proxy (DMZ)  
**SO:** Ubuntu Server 24.04 LTS

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 104 |
| **Nome** | Web-Server |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 1024 MB (1 GB) |
| **vCPU** | 1 core |
| **Disco** | 50 GB |
| **Storage** | local-lvm (HDD) |
| **Network** | DMZ |
| **IP** | 10.0.0.30/24 |
| **Gateway** | 10.0.0.1 (pfSense) |

**Criação via CLI:**

```bash
qm create 104 \
  --name Web-Server \
  --memory 1024 \
  --cores 1 \
  --net0 virtio,bridge=DMZ \
  --scsi0 local-lvm:50 \
  --scsihw virtio-scsi-pci \
  --onboot 1 \
  --agent 1
```

---

### VMID 105: Servidor-de-dominio

**Função:** Samba AD DC (Domain Controller)  
**SO:** Ubuntu Server 24.04.3 LTS

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 105 |
| **Nome** | Servidor-de-dominio |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 2048 MB (2 GB) |
| **vCPU** | 2 cores |
| **Disco** | 50 GB |
| **Storage** | pve-nvme (NVMe) |
| **Network** | vmbr1 (LAN) |
| **IP** | 192.168.1.10/24 |
| **Gateway** | 192.168.1.1 (pfSense) |

**Criação via CLI:**

```bash
qm create 105 \
  --name Servidor-de-dominio \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 pve-nvme:50 \
  --scsihw virtio-scsi-pci \
  --onboot 1 \
  --agent 1
```

---

### VMID 106: Servidor-de-Ficheiros

**Função:** Nextcloud + Zammad  
**SO:** Ubuntu Server 24.04 LTS

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 106 |
| **Nome** | Servidor-de-Ficheiros |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 2048 MB (2 GB) |
| **vCPU** | 4 cores |
| **Disco** | 50 GB |
| **Storage** | local-lvm (HDD) |
| **Network** | vmbr1 (LAN) |
| **IP** | 192.168.1.40/24 |
| **Gateway** | 192.168.1.1 (pfSense) |

**Criação via CLI:**

```bash
qm create 106 \
  --name Servidor-de-Ficheiros \
  --memory 2048 \
  --cores 4 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --scsihw virtio-scsi-pci \
  --onboot 1 \
  --agent 1
```

---

### VMID 107: Ubuntu-Desktop

**Função:** VM de Testes  
**SO:** Ubuntu Desktop

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 107 |
| **Nome** | Ubuntu-Desktop |
| **Estado** | Stopped |
| **Start at boot** | Não |
| **RAM** | 2048 MB (2 GB) |
| **vCPU** | 2 cores |
| **Disco** | 50 GB |
| **Storage** | - |
| **Network** | vmbr1 (LAN) |

---

### VMID 108: mailcow

**Função:** Servidor de Email  
**SO:** Debian (com Docker)

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 108 |
| **Nome** | mailcow |
| **Estado** | Running |
| **Start at boot** | Sim |
| **RAM** | 6144 MB (6 GB) |
| **vCPU** | 2 cores |
| **Disco** | (volumes Docker) |
| **Storage** | local-lvm (HDD) |
| **Network** | DMZ |
| **IP** | 10.0.0.20/24 |
| **Gateway** | 10.0.0.1 (pfSense) |

**Criação via CLI:**

```bash
qm create 108 \
  --name mailcow \
  --memory 6144 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=DMZ \
  --scsi0 local-lvm:100 \
  --scsihw virtio-scsi-pci \
  --onboot 1 \
  --agent 1
```

---

## 📦 Templates e Cloud-Init

### Criar Template de VM

Templates permitem criar VMs rapidamente a partir de uma base pré-configurada.

```bash
# 1. Criar VM base
qm create 9000 \
  --name ubuntu-2404-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:20

# 2. Importar imagem cloud
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

# 3. Importar para VM
qm importdisk 9000 ubuntu-24.04-server-cloudimg-amd64.img local-lvm

# 4. Anexar disco à VM
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0

# 5. Configurar Cloud-Init
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket --vga serial0

# 6. Configurar Cloud-Init defaults
qm set 9000 --ciuser ubuntu
qm set 9000 --cipassword <password>
qm set 9000 --sshkey ~/.ssh/id_rsa.pub
qm set 9000 --ipconfig0 ip=dhcp

# 7. Converter para template
qm template 9000
```

### Criar VM a partir de Template

```bash
# Clonar template
qm clone 9000 110 --name nova-vm --full

# Configurar Cloud-Init específico
qm set 110 --ipconfig0 ip=192.168.1.50/24,gw=192.168.1.1

# Iniciar VM
qm start 110
```

---

## 🎯 Boas Práticas

### Alocação de Recursos

1. **CPU**
   - Não sobre-alocar: Total vCPUs ≤ 2x cores físicos
   - Usar `host` CPU type para melhor performance
   - Reservar 1-2 cores para o host

2. **RAM**
   - Ativar ballooning para flexibilidade
   - Reservar 2-4 GB para o host
   - Monitorizar usage real vs alocado

3. **Storage**
   - VMs críticas → NVMe (pfSense, DC)
   - VMs com muitos dados → HDD (Files, Mail)
   - Ativar discard para SSDs

### Segurança

1. **Rede**
   - Conectar VMs às bridges corretas
   - Desativar firewall da bridge (usar pfSense)
   - Não expor VMs diretamente à WAN

2. **Isolamento**
   - VMs públicas → DMZ
   - VMs internas → LAN
   - Sem comunicação direta DMZ ↔ LAN

3. **Atualizações**
   - Manter VMs atualizadas
   - Testar updates em VM de teste primeiro

### Performance

1. **Usar VirtIO**
   - Network: virtio
   - Disk: SCSI com VirtIO SCSI controller
   - Melhor performance que emulação

2. **Ativar QEMU Agent**
   - Permite shutdown graceful
   - Sincronização de tempo
   - Informação de sistema

3. **Cache Mode**
   - Write back (default): Bom equilíbrio
   - Write through: Mais seguro, mais lento
   - None: Para alguns casos específicos

---

## 🐛 Troubleshooting

### Problema: VM não inicia

**Diagnóstico:**

```bash
# Ver logs
qm start <vmid>

# Ver configuração
qm config <vmid>

# Ver logs detalhados
tail -f /var/log/pve/tasks/active
```

**Soluções comuns:**

1. Verificar se storage está acessível
2. Verificar se bridge existe
3. Verificar se há recursos suficientes
4. Verificar configuração de boot

### Problema: Performance baixa

**Diagnóstico:**

```bash
# Ver utilização de recursos
qm monitor <vmid>

# Dentro da VM:
top
iostat -x 2
```

**Soluções:**

1. Aumentar RAM/CPU
2. Mover disco para storage mais rápido
3. Verificar if VirtIO está ativo
4. Ativar IO threads

### Problema: Rede não funciona

**Verificações:**

```bash
# Verificar bridge
brctl show

# Verificar configuração da VM
qm config <vmid> | grep net

# Dentro da VM:
ip addr
ip route
ping 8.8.8.8
```

---

## 📖 Próximos Passos

Após criar VMs, prosseguir com:

1. ✅ **VMs Criadas**
2. ➡️ [Configuração de Backup](05-backup-config.md) - Backups automáticos
3. ➡️ [Manutenção](06-manutencao.md) - Gestão e manutenção

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

**[⬅️ Anterior: Storage](03-storage.md)** | **[Índice](README.md)** | **[Próximo: Backup ➡️](05-backup-config.md)**

</div>

---

*Última atualização: Dezembro 2024*
