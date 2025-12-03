# 🖥️ Instalação do Ubuntu Server 24.04.3 LTS - DMZ

> **Guia de instalação e configuração inicial do sistema operativo para o Webserver DMZ**

---

## 📋 Índice

1. [Requisitos de Sistema](#-requisitos-de-sistema)
2. [Informação da Máquina Virtual](#-informação-da-máquina-virtual)
3. [Processo de Instalação](#-processo-de-instalação)
4. [Configuração de Rede DMZ](#-configuração-de-rede-dmz)
5. [Configuração de Timezone e NTP](#-configuração-de-timezone-e-ntp)
6. [Instalação de Pacotes Base](#-instalação-de-pacotes-base)
7. [Configurações de Segurança](#-configurações-de-segurança)
8. [Verificação Pós-Instalação](#-verificação-pós-instalação)
9. [Referências](#-referências)

---

## 💻 Requisitos de Sistema

### Hardware

| Recurso | Valor | Descrição |
|---------|-------|-----------|
| **RAM** | 794 MB | Memória mínima para Nginx |
| **Disco** | 24 GB | Sistema + logs |
| **Rede** | 1 NIC | Interface na rede DMZ |

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
qm create 102 \
  --name webserver \
  --memory 800 \
  --cores 2 \
  --sockets 1 \
  --net0 virtio,bridge=vmbr2 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:24 \
  --ide2 local:iso/ubuntu-24.04.3-live-server-amd64.iso,media=cdrom \
  --boot order=scsi0;ide2
```

### Parâmetros da VM

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 102 |
| **Nome** | webserver |
| **Bridge** | vmbr2 (DMZ) |
| **Tipo de Disco** | VirtIO SCSI |
| **Tipo de Rede** | VirtIO |

---

## 🔧 Processo de Instalação

### 1. Boot e Seleção de Idioma

1. Iniciar a VM com a ISO do Ubuntu Server
2. Selecionar idioma: **Português (Portugal)**
3. Selecionar layout de teclado: **Portuguese**

### 2. Tipo de Instalação

1. Selecionar **Ubuntu Server (minimized)**
2. Configurar instalação de SSH durante o setup

### 3. Configuração de Disco

```
Método: Use entire disk
Disco: /dev/sda (24 GB)
LVM: Sim
Encriptação: Não
```

**Layout de Partições:**

| Partição | Tamanho | Ponto de Montagem | Filesystem |
|----------|---------|-------------------|------------|
| /dev/sda1 | 1 GB | /boot/efi | FAT32 (EFI) |
| /dev/sda2 | 2 GB | /boot | ext4 |
| /dev/sda3 | ~21 GB | LVM (ubuntu-vg) | - |
| /dev/mapper/ubuntu--vg-root | ~21 GB | / | ext4 |

### 4. Configuração de Utilizador

```bash
Nome: Webserver Admin
Username: webadmin
Password: [Strong Password]
```

### 5. Configuração de Rede (durante instalação)

```yaml
Interface: enp6s18
DHCP: Não (IP estático)
IP: 10.0.0.30/24
Gateway: 10.0.0.1
DNS: 192.168.1.10, 1.1.1.1
```

---

## 🌐 Configuração de Rede DMZ

### Netplan Configuration

Editar `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp6s18:
      addresses:
        - 10.0.0.30/24
      routes:
        - to: default
          via: 10.0.0.1
        # Rota para LAN (via pfSense)
        - to: 192.168.1.0/24
          via: 10.0.0.1
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
sudo hostnamectl set-hostname webserver.fsociety.pt

# Editar /etc/hosts
sudo nano /etc/hosts
```

Conteúdo de `/etc/hosts`:

```
127.0.0.1 localhost
127.0.1.1 webserver.fsociety.pt webserver

10.0.0.30 webserver.fsociety.pt webserver

# Servidores da infraestrutura
10.0.0.1     pfsense.fsociety.pt pfsense
10.0.0.20    mail.fsociety.pt mail
192.168.1.10 dc.fsociety.pt dc
192.168.1.40 files.fsociety.pt files

::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

### Verificar Conectividade

```bash
# Testar conectividade DMZ
ping -c 4 10.0.0.1        # Gateway pfSense
ping -c 4 10.0.0.20       # Mail server
ping -c 4 1.1.1.1         # Internet

# Testar conectividade LAN (via routing)
ping -c 4 192.168.1.10    # Domain Controller
ping -c 4 192.168.1.40    # File Server

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
```

Reiniciar e verificar:

```bash
sudo systemctl restart chrony
sudo systemctl status chrony
chronyc sources
```

---

## 📦 Instalação de Pacotes Base

### Atualizar Sistema

```bash
sudo apt update
sudo apt upgrade -y
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

# Build essentials
sudo apt install -y \
  build-essential \
  make \
  gcc \
  g++
```

---

## 🔒 Configurações de Segurança

### Configurar UFW (Firewall Local)

```bash
# Permitir SSH
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Ativar UFW
sudo ufw --force enable

# Status
sudo ufw status verbose
```

### Configurar Limites de Sistema

Editar `/etc/security/limits.conf`:

```bash
sudo nano /etc/security/limits.conf
```

Adicionar:

```conf
# Limites para Nginx
www-data soft nofile 65536
www-data hard nofile 65536

# Limites globais
* soft nofile 8192
* hard nofile 16384
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
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2

# Aumentar limites de conexões
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 5000

# File handles
fs.file-max = 131072

# Proteção contra IP spoofing
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Desativar ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
```

Aplicar:

```bash
sudo sysctl -p
```

### Fail2ban (será configurado depois)

```bash
# Instalar Fail2ban
sudo apt install -y fail2ban

# Não ativar ainda (será configurado com Nginx)
sudo systemctl disable fail2ban
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
```

### Rede DMZ

```bash
# Interfaces
ip addr show

# Rotas
ip route show

# DNS
cat /etc/resolv.conf

# Hostname
hostname -f

# Testar roteamento para LAN
traceroute 192.168.1.40
```

### Serviços

```bash
# Verificar serviços essenciais
sudo systemctl status ssh
sudo systemctl status chrony
sudo systemctl status systemd-networkd
```

### Firewall

```bash
# Status UFW
sudo ufw status numbered

# iptables
sudo iptables -L -n -v
```

---

## 📝 Checklist Pós-Instalação

- [x] Sistema operativo instalado e atualizado
- [x] Rede DMZ configurada com IP estático (10.0.0.30)
- [x] Hostname definido (webserver.fsociety.pt)
- [x] Rota para LAN configurada
- [x] Timezone configurado (Europe/Lisbon)
- [x] NTP sincronizado
- [x] Pacotes base instalados
- [x] Limites de sistema configurados
- [x] Sysctl otimizado
- [x] UFW configurado (SSH, HTTP, HTTPS)
- [x] Conectividade testada (DMZ, LAN, Internet, DNS)

---

## 🔗 Próximos Passos

No próximo documento, configuraremos:
- Nginx 1.24.0
- Security headers globais
- Rate limiting
- SSL/TLS

---

## 📖 Referências

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Netplan DMZ Configuration](https://netplan.io/)
- [Linux Network Security](https://www.kernel.org/doc/Documentation/networking/)

---

<div align="center">

**[⬅️ Voltar ao README](README.md)** | **[Próximo: Nginx Config ➡️](02-nginx-config.md)**

</div>

---

*Última atualização: Dezembro 2024*
