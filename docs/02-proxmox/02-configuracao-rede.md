# 🌐 Configuração de Rede - Proxmox VE

> Guia completo de configuração de rede do Proxmox VE, incluindo bridges virtuais, interfaces de rede e diagrama de topologia.

---

## 📋 Visão Geral

O Proxmox VE utiliza **Linux bridges** para conectar VMs à rede. Cada bridge funciona como um switch virtual, permitindo que VMs comuniquem entre si e com redes externas.

### Topologia de Rede do Projeto

```
                              INTERNET
                                 │
                                 │ 192.168.31.1 (ISP Router)
                                 │
                   ┌─────────────▼──────────────┐
                   │   Proxmox VE Host          │
                   │   mail.fsociety.pt         │
                   │   192.168.31.34            │
                   │                            │
                   │   ┌──────────────────────┐ │
                   │   │  enx2c16dba588ba     │ │
                   │   │  (USB Ethernet)      │ │
                   │   └──────────┬───────────┘ │
                   │              │             │
                   │   ┌──────────▼───────────┐ │
                   │   │  vmbr0 (WAN Bridge)  │ │
                   │   │  192.168.31.34/24    │ │
                   │   └──────────┬───────────┘ │
                   │              │             │
                   └──────────────┼─────────────┘
                                  │
                   ┌──────────────▼──────────────┐
                   │   pfSense VM (VMID 102)     │
                   │   192.168.31.100/24         │
                   │                             │
                   │   vtnet0 (WAN)  ────┐       │
                   │   vtnet1 (LAN)  ────┼───┐   │
                   │   vtnet2 (DMZ)  ────┼───┼─┐ │
                   └─────────────────────┼───┼─┼─┘
                                         │   │ │
                      ┌──────────────────┘   │ │
                      │  ┌───────────────────┘ │
                      │  │  ┌──────────────────┘
                      │  │  │
         ┌────────────▼──▼──▼────────────┐
         │   Proxmox VE Host             │
         │                               │
         │   ┌─────────────────────────┐ │
         │   │  vmbr1 (LAN Bridge)     │ │
         │   │  192.168.1.0/24         │ │
         │   └──┬───┬───┬──────────────┘ │
         │      │   │   │                │
         │   ┌─────────────────────────┐ │
         │   │  DMZ Bridge             │ │
         │   │  10.0.0.0/24            │ │
         │   └──┬───┬──────────────────┘ │
         └──────┼───┼────────────────────┘
                │   │
        ┌───────▼───▼────────┐
        │   VMs na LAN/DMZ   │
        │   - DC (101)       │
        │   - PBS (105)      │
        │   - Files (106)    │
        │   - Web (104)      │
        │   - Mail (108)     │
        └────────────────────┘
```

---

## 🔌 Interfaces de Rede Físicas

### Interface Principal (WAN)

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | enx2c16dba588ba |
| **Tipo** | USB Ethernet Adapter (Gigabit) |
| **MAC Address** | 2c:16:db:a5:88:ba |
| **Status** | UP |
| **Link Speed** | 1000 Mbps Full Duplex |
| **Bridge** | vmbr0 |

```bash
# Verificar interface física
ip link show enx2c16dba588ba

# Saída esperada:
# 2: enx2c16dba588ba: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
#     link/ether 2c:16:db:a5:88:ba brd ff:ff:ff:ff:ff:ff
```

---

## 🌉 Linux Bridges

### vmbr0 - WAN Bridge (Internet)

**Função:** Conectar o host Proxmox à Internet e permitir acesso externo

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | vmbr0 |
| **IP Address** | 192.168.31.34/24 |
| **Gateway** | 192.168.31.1 |
| **Interface Física** | enx2c16dba588ba |
| **Autostart** | Sim |
| **VLAN Aware** | Não |
| **VMs Conectadas** | pfSense (vtnet0) |

**Configuração em `/etc/network/interfaces`:**

```bash
auto vmbr0
iface vmbr0 inet static
    address 192.168.31.34/24
    gateway 192.168.31.1
    bridge-ports enx2c16dba588ba
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware no
# WAN - Internet Gateway
```

### vmbr1 - LAN Bridge (Rede Interna)

**Função:** Rede interna para servidores (DC, PBS, Files)

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | vmbr1 |
| **IP Address** | Nenhum (manual) |
| **Gateway** | 192.168.1.1 (pfSense) |
| **Interface Física** | Nenhuma (bridge virtual) |
| **Autostart** | Sim |
| **VLAN Aware** | Não |
| **Rede** | 192.168.1.0/24 |

**VMs Conectadas:**
- VMID 101: Proxmox-Backup (192.168.1.30)
- VMID 102: pfSense vtnet1 (192.168.1.1 - gateway)
- VMID 105: Servidor-de-dominio (192.168.1.10)
- VMID 106: Servidor-de-Ficheiros (192.168.1.40)

**Configuração em `/etc/network/interfaces`:**

```bash
auto vmbr1
iface vmbr1 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
# LAN - Internal Network (192.168.1.0/24)
```

### DMZ Bridge (Zona Desmilitarizada)

**Função:** Rede isolada para servidores expostos à Internet

| Parâmetro | Valor |
|-----------|-------|
| **Nome** | DMZ (ou vmbr2) |
| **IP Address** | Nenhum (manual) |
| **Gateway** | 10.0.0.1 (pfSense) |
| **Interface Física** | Nenhuma (bridge virtual) |
| **Autostart** | Sim |
| **VLAN Aware** | Não |
| **Rede** | 10.0.0.0/24 |

**VMs Conectadas:**
- VMID 102: pfSense vtnet2 (10.0.0.1 - gateway)
- VMID 104: Web-Server (10.0.0.30)
- VMID 108: mailcow (10.0.0.20)

**Configuração em `/etc/network/interfaces`:**

```bash
auto DMZ
iface DMZ inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
# DMZ - Demilitarized Zone (10.0.0.0/24)
```

---

## 📄 Ficheiro de Configuração Completo

### /etc/network/interfaces

```bash
# Configuração de Rede - Proxmox VE
# mail.fsociety.pt
# Última atualização: Dezembro 2024

# Loopback interface
auto lo
iface lo inet loopback

# Interface física WAN (USB Ethernet)
iface enx2c16dba588ba inet manual

# vmbr0: WAN Bridge - Acesso à Internet
auto vmbr0
iface vmbr0 inet static
    address 192.168.31.34/24
    gateway 192.168.31.1
    bridge-ports enx2c16dba588ba
    bridge-stp off
    bridge-fd 0
# WAN - Internet Gateway via USB Ethernet

# vmbr1: LAN Bridge - Rede Interna
auto vmbr1
iface vmbr1 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
# LAN - Internal Network (192.168.1.0/24)
# VMs: DC, PBS, File Server, pfSense-LAN

# DMZ Bridge - Zona Desmilitarizada
auto DMZ
iface DMZ inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
# DMZ - Demilitarized Zone (10.0.0.0/24)
# VMs: Web Server, Mailcow, pfSense-DMZ

# Fim da configuração
```

---

## 🛠️ Configuração via Web UI

### Criar Nova Bridge

1. Aceder a **Datacenter → mail → System → Network**

2. Clicar em **Create → Linux Bridge**

3. Preencher campos:

| Campo | Exemplo (vmbr1) | Descrição |
|-------|----------------|-----------|
| **Name** | vmbr1 | Nome da bridge |
| **IPv4/CIDR** | (vazio) | IP do host nesta bridge (opcional) |
| **Gateway** | (vazio) | Gateway (apenas se diferente do padrão) |
| **Autostart** | ✅ Sim | Iniciar automaticamente |
| **VLAN aware** | ❌ Não | Suporte a VLANs (geralmente não necessário) |
| **Bridge ports** | (vazio) | Interface física (se aplicável) |
| **Comment** | LAN - 192.168.1.0/24 | Descrição |

4. Clicar em **Create**

5. Clicar em **Apply Configuration** (ícone no topo)

### Editar Bridge Existente

1. **Datacenter → mail → System → Network**

2. Selecionar bridge (ex: vmbr0)

3. Clicar em **Edit**

4. Modificar conforme necessário

5. **Apply Configuration**

---

## 🔧 Configuração via CLI

### Criar Bridge Manualmente

```bash
# Editar ficheiro de configuração
nano /etc/network/interfaces

# Adicionar nova bridge (exemplo vmbr2)
auto vmbr2
iface vmbr2 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
# Descrição da bridge

# Reiniciar networking (CUIDADO: pode perder conexão)
systemctl restart networking

# Ou recarregar apenas uma interface
ifdown vmbr2 && ifup vmbr2
```

### Verificar Bridges

```bash
# Listar todas as bridges
brctl show

# Saída esperada:
# bridge name     bridge id               STP enabled     interfaces
# DMZ             8000.000000000000       no
# vmbr0           8000.2c16dba588ba       no              enx2c16dba588ba
# vmbr1           8000.000000000000       no

# Ver detalhes de uma bridge específica
ip link show vmbr0
brctl showmacs vmbr0

# Ver IPs atribuídos
ip addr show vmbr0
```

### Testar Conectividade

```bash
# Ping ao gateway WAN
ping -c 4 192.168.31.1

# Ping à Internet
ping -c 4 8.8.8.8
ping -c 4 google.com

# Verificar routing
ip route show

# Saída esperada:
# default via 192.168.31.1 dev vmbr0
# 192.168.31.0/24 dev vmbr0 proto kernel scope link src 192.168.31.34
```

---

## 🔌 Atribuir VMs a Bridges

### Via Web UI

1. Selecionar VM (ex: VMID 105)

2. **Hardware → Network Device → Edit**

3. Configurar:

| Campo | Valor |
|-------|-------|
| **Bridge** | vmbr1 (ou DMZ) |
| **Model** | VirtIO (paravirtualized) |
| **MAC address** | (automático ou manual) |
| **Firewall** | ✅ ou ❌ (conforme necessário) |
| **Disconnect** | ❌ Não |

4. Clicar em **OK**

5. Reiniciar VM para aplicar

### Via CLI

```bash
# Listar configuração de rede da VM
qm config 105 | grep net

# Saída:
# net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr1,firewall=1

# Alterar bridge de uma VM
qm set 105 -net0 virtio,bridge=vmbr1

# Adicionar segunda interface de rede
qm set 102 -net1 virtio,bridge=vmbr1
qm set 102 -net2 virtio,bridge=DMZ

# Verificar
qm config 102 | grep net
```

---

## 📊 Diagrama de Fluxo de Rede

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
│                      192.168.31.0/24                            │
└────────────────────┬────────────────────────────────────────────┘
                     │
         ┌───────────▼─────────────────┐
         │  ISP Router / Gateway       │
         │  192.168.31.1               │
         └───────────┬─────────────────┘
                     │
         ┌───────────▼─────────────────┐
         │  Proxmox VE Host            │
         │  vmbr0: 192.168.31.34       │
         └───────────┬─────────────────┘
                     │
         ┌───────────▼─────────────────┐
         │  pfSense Firewall VM        │
         │  vtnet0: 192.168.31.100     │ WAN
         │  vtnet1: 192.168.1.1        │ LAN
         │  vtnet2: 10.0.0.1           │ DMZ
         └───┬────────────────┬─────────┘
             │                │
    ┌────────▼─────┐    ┌─────▼────────┐
    │ vmbr1 (LAN)  │    │ DMZ Bridge   │
    │ 192.168.1.0  │    │ 10.0.0.0     │
    └────┬─────────┘    └─────┬────────┘
         │                    │
    ┌────▼────────────┐  ┌────▼──────────┐
    │ LAN VMs         │  │ DMZ VMs       │
    │ - DC (.10)      │  │ - Web (.30)   │
    │ - PBS (.30)     │  │ - Mail (.20)  │
    │ - Files (.40)   │  │               │
    └─────────────────┘  └───────────────┘
```

---

## 🔒 Segurança de Rede

### Isolamento de Redes

| Rede | Acesso Internet | Acesso LAN | Acesso DMZ |
|------|----------------|------------|------------|
| **WAN** | ✅ Direto | ❌ Bloqueado | ❌ Bloqueado |
| **LAN** | ✅ Via pfSense | ✅ Total | ⚠️ Controlado |
| **DMZ** | ✅ Restrito | ⚠️ Mínimo | ❌ Isolado |

### Boas Práticas

1. **Não atribuir IPs às bridges LAN/DMZ no host**
   - Manter bridges como "manual" (sem IP)
   - Evita exposição do host às redes internas

2. **Desativar STP em bridges**
   - `bridge-stp off` em ambientes virtuais
   - Reduz latência e evita loops desnecessários

3. **Utilizar VirtIO para VMs**
   - Melhor performance que emulação E1000
   - Requer drivers VirtIO no guest OS

4. **Firewall no pfSense, não no Proxmox**
   - Centralizar regras de firewall no pfSense
   - Simplifica gestão e troubleshooting

---

## 🐛 Troubleshooting

### Problema: VMs não têm conectividade

**Diagnóstico:**

```bash
# Verificar se bridge está UP
ip link show vmbr1

# Verificar se VM está conectada à bridge correta
qm config 105 | grep net

# Dentro da VM, verificar interface
ip addr show
ip route show
```

**Soluções:**

1. Verificar se bridge está ativa
2. Verificar configuração de rede na VM
3. Reiniciar networking na VM
4. Verificar firewall (pfSense ou Proxmox)

### Problema: Host Proxmox perde conectividade após alterações

**Solução:**

```bash
# Backup da configuração antes de editar
cp /etc/network/interfaces /etc/network/interfaces.backup

# Se perder acesso, usar console do Proxmox (físico)
# Restaurar backup:
cp /etc/network/interfaces.backup /etc/network/interfaces
systemctl restart networking

# Ou reverter apenas uma interface:
ifdown vmbr0
ifup vmbr0
```

### Problema: Bridge não aparece na Web UI

**Solução:**

```bash
# Verificar sintaxe do ficheiro
cat /etc/network/interfaces

# Aplicar configuração
ifreload -a

# Se necessário, reiniciar serviço
systemctl restart pve-cluster
systemctl restart pvedaemon
```

---

## 📖 Próximos Passos

Após configurar a rede, prosseguir com:

1. ✅ **Configuração de Rede Concluída**
2. ➡️ [Configuração de Storage](03-storage.md) - Configurar pools de armazenamento
3. ➡️ [Criação de VMs](04-criacao-vms.md) - Criar e configurar VMs

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

**[⬅️ Anterior: Instalação](01-instalacao.md)** | **[Índice](README.md)** | **[Próximo: Storage ➡️](03-storage.md)**

</div>

---

*Última atualização: Dezembro 2024*
