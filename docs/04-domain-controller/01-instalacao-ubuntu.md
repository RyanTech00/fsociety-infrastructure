# 🖥️ Instalação do Ubuntu Server 24.04.3 LTS

> **Guia de instalação e configuração inicial do sistema operativo para o Domain Controller**

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

### Hardware Mínimo

| Recurso | Valor | Descrição |
|---------|-------|-----------|
| **vCPU** | 1 | Processador virtual |
| **RAM** | 1.4 GB | Memória mínima para Samba AD |
| **Disco** | 24 GB | Espaço para sistema e logs |
| **Rede** | 1 NIC | Interface na rede LAN |

### Software

| Componente | Versão | Descrição |
|------------|--------|-----------|
| **Sistema Operativo** | Ubuntu Server 24.04.3 LTS | Noble Numbat |
| **Kernel** | 6.8.0-88-generic | Kernel Linux |
| **Hypervisor** | Proxmox VE 8.x | Virtualização KVM |

---

## 🖥️ Informação da Máquina Virtual

### Configuração no Proxmox

```bash
# Criação da VM no Proxmox
qm create 101 \
  --name dc \
  --memory 1434 \
  --cores 1 \
  --sockets 1 \
  --net0 virtio,bridge=vmbr1 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:24 \
  --ide2 local:iso/ubuntu-24.04.3-live-server-amd64.iso,media=cdrom \
  --boot order=scsi0;ide2
```

### Parâmetros da VM

| Parâmetro | Valor |
|-----------|-------|
| **VM ID** | 101 |
| **Nome** | dc |
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

1. Selecionar **Ubuntu Server (minimized)**
2. Não instalar OpenSSH durante a instalação (será configurado depois)

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
| ubuntu--vg-ubuntu--lv | ~21 GB | / | ext4 |

### 4. Configuração de Utilizador

| Campo | Valor |
|-------|-------|
| **Nome** | Administrador |
| **Nome do servidor** | dc |
| **Username** | sysadmin |
| **Password** | [password segura] |

### 5. Instalação SSH (Opcional)

Durante a instalação, pode optar por instalar o OpenSSH Server ou fazê-lo posteriormente.

---

## 🌐 Configuração de Rede

### Ficheiro Netplan

**Localização:** `/etc/netplan/00-installer-config.yaml`

```yaml
# Configuração de rede estática para Domain Controller
# dc.fsociety.pt - 192.168.1.10

network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      addresses:
        - 192.168.1.10/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 127.0.0.1
          - 192.168.1.1
        search:
          - fsociety.pt
      dhcp4: false
      dhcp6: false
```

### Aplicar Configuração

```bash
# Validar configuração
sudo netplan try

# Aplicar configuração
sudo netplan apply

# Verificar configuração
ip addr show ens18
ip route show
```

### Verificação de Conectividade

```bash
# Testar gateway
ping -c 4 192.168.1.1

# Testar DNS externo
ping -c 4 8.8.8.8

# Testar resolução de nomes
nslookup google.com
```

---

## ⏰ Configuração de Timezone e NTP

### Configurar Timezone

```bash
# Verificar timezone atual
timedatectl

# Listar timezones disponíveis
timedatectl list-timezones | grep Lisbon

# Definir timezone para Lisboa
sudo timedatectl set-timezone Europe/Lisbon

# Verificar alteração
timedatectl
```

### Configurar NTP

O systemd-timesyncd é o cliente NTP padrão do Ubuntu.

```bash
# Verificar estado do NTP
timedatectl show-timesync --all

# Configurar servidores NTP
sudo nano /etc/systemd/timesyncd.conf
```

**Conteúdo de `/etc/systemd/timesyncd.conf`:**

```ini
[Time]
NTP=pt.pool.ntp.org
FallbackNTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
```

```bash
# Reiniciar serviço NTP
sudo systemctl restart systemd-timesyncd

# Verificar sincronização
timedatectl timesync-status
```

### Saída Esperada

```
               Local time: Mon 2024-12-02 18:30:00 WET
           Universal time: Mon 2024-12-02 18:30:00 UTC
                 RTC time: Mon 2024-12-02 18:30:00
                Time zone: Europe/Lisbon (WET, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

---

## 📦 Instalação de Pacotes Base

### Atualizar Sistema

```bash
# Atualizar lista de pacotes
sudo apt update

# Atualizar pacotes instalados
sudo apt upgrade -y

# Instalar atualizações de segurança
sudo apt dist-upgrade -y
```

### Pacotes Essenciais

```bash
# Ferramentas de sistema
sudo apt install -y \
    vim \
    htop \
    net-tools \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release

# Ferramentas de rede
sudo apt install -y \
    dnsutils \
    bind9-dnsutils \
    iputils-ping \
    traceroute \
    tcpdump \
    nmap
```

### Pacotes para Samba AD DC

```bash
# Pacotes necessários para Samba AD DC
sudo apt install -y \
    samba \
    samba-common \
    samba-common-bin \
    samba-dsdb-modules \
    samba-vfs-modules \
    winbind \
    libpam-winbind \
    libnss-winbind \
    krb5-user \
    krb5-config \
    libkrb5-dev
```

**Durante a instalação do krb5-user, fornecer:**

| Pergunta | Resposta |
|----------|----------|
| Default Kerberos realm | FSOCIETY.PT |
| Kerberos servers for your realm | dc.fsociety.pt |
| Administrative server | dc.fsociety.pt |

### Pacotes para DHCP

```bash
# ISC DHCP Server
sudo apt install -y isc-dhcp-server
```

### Pacotes para FreeRADIUS

```bash
# FreeRADIUS com módulo LDAP
sudo apt install -y \
    freeradius \
    freeradius-ldap \
    freeradius-utils
```

### Pacotes para Monitorização

```bash
# Netdata para monitorização
curl -s https://my-netdata.io/kickstart.sh | sudo bash -s -- --stable-channel
```

---

## ⚙️ Configurações de Sistema

### Hostname

```bash
# Definir hostname
sudo hostnamectl set-hostname dc

# Verificar hostname
hostnamectl
```

### Ficheiro /etc/hosts

```bash
sudo nano /etc/hosts
```

**Conteúdo:**

```
127.0.0.1       localhost
192.168.1.10    dc.fsociety.pt dc

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

### Desativar systemd-resolved (Importante para Samba DNS)

```bash
# Parar e desativar systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Remover link simbólico
sudo rm /etc/resolv.conf

# Criar novo resolv.conf
sudo nano /etc/resolv.conf
```

**Conteúdo de `/etc/resolv.conf`:**

```
# DNS local do Samba AD
nameserver 127.0.0.1
nameserver 192.168.1.1
search fsociety.pt
```

```bash
# Proteger ficheiro contra alterações automáticas
sudo chattr +i /etc/resolv.conf
```

### Limites de Sistema

```bash
sudo nano /etc/security/limits.conf
```

**Adicionar no final:**

```
# Limites para Samba
*               soft    nofile          16384
*               hard    nofile          32768
```

---

## ✅ Verificação Pós-Instalação

### Verificar Sistema

```bash
# Informação do sistema
hostnamectl

# Verificar kernel
uname -a

# Verificar memória
free -h

# Verificar disco
df -h
```

### Verificar Rede

```bash
# Interface de rede
ip addr show

# Tabela de routing
ip route show

# Resolução DNS
cat /etc/resolv.conf

# Testar DNS
nslookup dc.fsociety.pt
```

### Verificar Serviços

```bash
# Listar serviços ativos
systemctl list-units --type=service --state=running

# Verificar NTP
timedatectl status
```

### Verificar Pacotes Instalados

```bash
# Verificar Samba
samba --version

# Verificar Kerberos
kinit --version

# Verificar DHCP
dhcpd --version

# Verificar FreeRADIUS
freeradius -v
```

### Saída Esperada

```
# hostnamectl
 Static hostname: dc
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
         Boot ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  Virtualization: kvm
Operating System: Ubuntu 24.04.3 LTS
          Kernel: Linux 6.8.0-88-generic
    Architecture: x86-64
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| Ubuntu Server Guide | https://ubuntu.com/server/docs |
| Netplan Documentation | https://netplan.io/reference |
| Samba Wiki | https://wiki.samba.org |
| systemd-timesyncd | https://www.freedesktop.org/software/systemd/man/systemd-timesyncd.service.html |

### Artigos e Tutoriais

1. **Ubuntu 24.04 Server Installation** - Canonical Documentation
2. **Setting Up Static IP on Ubuntu** - Ubuntu Community Wiki
3. **Preparing Ubuntu for Samba AD DC** - Samba Wiki

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 🔗 Navegação

| Anterior | Índice | Próximo |
|----------|--------|---------|
| [← README](README.md) | [📚 Índice](README.md) | [Samba AD DC →](02-samba-ad-dc.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#️-instalação-do-ubuntu-server-24043-lts)**

---

*Última atualização: Dezembro 2024*

</div>
