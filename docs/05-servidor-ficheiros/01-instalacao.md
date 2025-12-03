# 🖥️ Instalação do Ubuntu Server 24.04.3 LTS

> **Guia de instalação e configuração inicial do sistema operativo para o Servidor de Ficheiros**

---

## 📋 Índice

1. [Requisitos de Sistema](#-requisitos-de-sistema)
2. [Informação da Máquina Virtual](#-informação-da-máquina-virtual)
3. [Processo de Instalação](#-processo-de-instalação)
4. [Configuração de Rede](#-configuração-de-rede)
5. [Configuração de Timezone e NTP](#-configuração-de-timezone-e-ntp)
6. [Instalação de Pacotes Base](#-instalação-de-pacotes-base)
7. [Configurações de Sistema](#-configurações-de-sistema)
8. [Verificação Pós-Instalação](#-verificação-pós-instalação)
9. [Referências](#-referências)

---

## 💻 Requisitos de Sistema

### Hardware

| Recurso | Valor | Descrição |
|---------|-------|-----------|
| **vCPU** | 4 cores | Intel i5-7300HQ |
| **RAM** | 2 GB | Memória para Nextcloud + Zammad |
| **Disco** | 48 GB | Sistema + dados |
| **Rede** | 1 NIC | Interface na rede LAN |

### Software

| Componente | Versão | Descrição |
|------------|--------|-----------|
| **Sistema Operativo** | Ubuntu Server 24.04.3 LTS | Noble Numbat |
| **Kernel** | 6.8.0-generic | Kernel Linux |
| **Hypervisor** | Proxmox VE 8.x | Virtualização KVM |

---

## 🖥️ Informação da Máquina Virtual

### Configuração no Proxmox

```bash
# Criação da VM no Proxmox
qm create 103 \
  --name files \
  --memory 2048 \
  --cores 4 \
  --sockets 1 \
  --net0 virtio,bridge=vmbr1 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:48 \
  --ide2 local:iso/ubuntu-24.04.3-live-server-amd64.iso,media=cdrom \
  --boot order=scsi0;ide2
```

### Parâmetros da VM

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 103 |
| **Nome** | files |
| **Bridge** | vmbr1 (LAN) |
| **Tipo de Disco** | VirtIO SCSI |
| **Tipo de Rede** | VirtIO |

---

## 🔧 Processo de Instalação

### 1. Boot e Seleção de Idioma

1. Iniciar a VM com a ISO do Ubuntu Server
2. Selecionar idioma: **Português (Portugal)**
3. Selecionar layout de teclado: **Portuguese**

### 2. Tipo de Instalação

1. Selecionar **Ubuntu Server**
2. Configurar instalação de SSH durante o setup

### 3. Configuração de Disco

```
Método: Use entire disk
Disco: /dev/sda (48 GB)
LVM: Sim
Encriptação: Não
```

**Layout de Partições:**

| Partição | Tamanho | Ponto de Montagem | Filesystem |
|----------|---------|-------------------|------------|
| /dev/sda1 | 1 GB | /boot/efi | FAT32 (EFI) |
| /dev/sda2 | 2 GB | /boot | ext4 |
| /dev/sda3 | ~45 GB | LVM (ubuntu-vg) | - |
| /dev/mapper/ubuntu--vg-root | ~20 GB | / | ext4 |
| /dev/mapper/ubuntu--vg-var | ~15 GB | /var | ext4 |
| /dev/mapper/ubuntu--vg-home | ~10 GB | /mnt/data | ext4 |

### 4. Configuração de Utilizador

```bash
Nome: FSociety Admin
Username: fsadmin
Password: [Strong Password]
```

### 5. Configuração de Rede (durante instalação)

```yaml
Interface: enp6s18
DHCP: Não (IP estático)
IP: 192.168.1.40/24
Gateway: 192.168.1.1
DNS: 192.168.1.10, 1.1.1.1
```

### 6. Pacotes Opcionais

Durante a instalação, selecionar:
- ✅ OpenSSH Server
- ❌ Não selecionar outros snaps ou pacotes

---

## 🌐 Configuração de Rede

### Netplan Configuration

Editar `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp6s18:
      addresses:
        - 192.168.1.40/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 192.168.1.10
          - 1.1.1.1
        search:
          - fsociety.pt
```

Aplicar configuração:

```bash
sudo netplan apply
```

### Configurar Hostname

```bash
# Definir hostname
sudo hostnamectl set-hostname files.fsociety.pt

# Editar /etc/hosts
sudo nano /etc/hosts
```

Conteúdo de `/etc/hosts`:

```
127.0.0.1 localhost
127.0.1.1 files.fsociety.pt files

192.168.1.40 files.fsociety.pt files

# Servidores da infraestrutura
192.168.1.1  pfsense.fsociety.pt pfsense
192.168.1.10 dc.fsociety.pt dc
10.0.0.20    mail.fsociety.pt mail
10.0.0.30    webserver.fsociety.pt webserver

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

### Verificar Conectividade

```bash
# Testar conectividade
ping -c 4 192.168.1.1    # Gateway
ping -c 4 192.168.1.10   # Domain Controller
ping -c 4 1.1.1.1        # Internet

# Verificar DNS
nslookup dc.fsociety.pt
nslookup fsociety.pt
```

---

## ⏰ Configuração de Timezone e NTP

### Configurar Timezone

```bash
# Ver timezone atual
timedatectl

# Configurar timezone para Lisboa
sudo timedatectl set-timezone Europe/Lisbon

# Verificar
timedatectl
```

### Configurar NTP

```bash
# Instalar chrony
sudo apt update
sudo apt install -y chrony

# Editar configuração
sudo nano /etc/chrony/chrony.conf
```

Adicionar servidores NTP:

```conf
# Usar Domain Controller como servidor primário
server 192.168.1.10 iburst prefer

# Servidores públicos como backup
server 0.pt.pool.ntp.org iburst
server 1.pt.pool.ntp.org iburst
server 2.pt.pool.ntp.org iburst
```

Reiniciar e verificar:

```bash
# Reiniciar chrony
sudo systemctl restart chrony

# Verificar status
sudo systemctl status chrony

# Ver fontes NTP
chronyc sources

# Ver tracking
chronyc tracking
```

---

## 📦 Instalação de Pacotes Base

### Atualizar Sistema

```bash
# Atualizar lista de pacotes
sudo apt update

# Atualizar sistema
sudo apt upgrade -y

# Atualizar kernel e pacotes críticos
sudo apt dist-upgrade -y
```

### Pacotes Essenciais

```bash
# Ferramentas básicas
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  nano \
  htop \
  net-tools \
  dnsutils \
  traceroute \
  tcpdump \
  iotop \
  iftop \
  sysstat \
  unzip \
  zip \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Ferramentas de rede
sudo apt install -y \
  bridge-utils \
  vlan \
  ifenslave

# Ferramentas de segurança
sudo apt install -y \
  ufw \
  fail2ban \
  iptables-persistent

# Build essentials (para compilação futura)
sudo apt install -y \
  build-essential \
  make \
  gcc \
  g++
```

---

## ⚙️ Configurações de Sistema

### Configurar UFW (Uncomplicated Firewall)

```bash
# Desabilitar UFW por enquanto (configuraremos depois)
sudo ufw disable

# Status
sudo ufw status
```

### Configurar Limites de Sistema

Editar `/etc/security/limits.conf`:

```bash
sudo nano /etc/security/limits.conf
```

Adicionar:

```conf
# Limites para Apache/PHP/Nextcloud
www-data soft nofile 8192
www-data hard nofile 16384

# Limites para PostgreSQL
postgres soft nofile 4096
postgres hard nofile 8192

# Limites para Zammad
zammad soft nofile 4096
zammad hard nofile 8192
```

### Configurar Sysctl

Editar `/etc/sysctl.conf`:

```bash
sudo nano /etc/sysctl.conf
```

Adicionar:

```conf
# Otimizações de rede
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Proteção contra SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Aumentar limites de conexões
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000

# File handles
fs.file-max = 65536
```

Aplicar:

```bash
sudo sysctl -p
```

### Criar Diretórios de Montagem

```bash
# Criar diretório para dados do Nextcloud
sudo mkdir -p /mnt/data
sudo chown -R www-data:www-data /mnt/data
sudo chmod 750 /mnt/data
```

---

## ✅ Verificação Pós-Instalação

### Sistema Operativo

```bash
# Versão do OS
lsb_release -a

# Kernel
uname -r

# Uptime
uptime

# Memória
free -h

# Disco
df -h

# CPU
lscpu
```

### Rede

```bash
# Interfaces
ip addr show

# Rotas
ip route show

# DNS
cat /etc/resolv.conf

# Hostname
hostname -f
```

### Serviços

```bash
# Verificar serviços essenciais
sudo systemctl status ssh
sudo systemctl status chrony
sudo systemctl status systemd-networkd
sudo systemctl status systemd-resolved
```

### Logs

```bash
# Ver logs do sistema
sudo journalctl -xe

# Ver últimos boots
sudo journalctl --list-boots

# Ver logs do boot atual
sudo journalctl -b
```

---

## 📝 Checklist Pós-Instalação

- [x] Sistema operativo instalado e atualizado
- [x] Rede configurada com IP estático
- [x] Hostname definido (files.fsociety.pt)
- [x] Timezone configurado (Europe/Lisbon)
- [x] NTP sincronizado com DC
- [x] Pacotes base instalados
- [x] Limites de sistema configurados
- [x] Sysctl otimizado
- [x] Diretórios criados
- [x] Conectividade testada (LAN, Internet, DNS)

---

## 📖 Referências

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Netplan Documentation](https://netplan.io/)
- [Systemd Documentation](https://www.freedesktop.org/wiki/Software/systemd/)
- [Linux System Administrator's Guide](https://tldp.org/LDP/sag/html/)

---

<div align="center">

**[⬅️ Voltar ao README](README.md)** | **[Próximo: Nextcloud Instalação ➡️](02-nextcloud.md)**

</div>

---

*Última atualização: Dezembro 2024*
