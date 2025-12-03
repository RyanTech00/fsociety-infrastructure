# 🔧 Instalação do Mailcow

> **Guia completo de instalação do Mailcow Dockerized no servidor de email FSociety.pt**

---

## 📋 Índice

1. [Requisitos de Sistema](#-requisitos-de-sistema)
2. [Informação da VM](#-informação-da-vm)
3. [Preparação do Sistema](#-preparação-do-sistema)
4. [Instalação do Docker](#-instalação-do-docker)
5. [Instalação do Mailcow](#-instalação-do-mailcow)
6. [Configuração Inicial](#-configuração-inicial)
7. [Inicialização dos Containers](#-inicialização-dos-containers)
8. [Verificação Pós-Instalação](#-verificação-pós-instalação)

---

## 💻 Requisitos de Sistema

### Hardware Mínimo

| Recurso | Recomendado | Implementado | Descrição |
|---------|-------------|--------------|-----------|
| **vCPU** | 2+ | 2 | Processadores virtuais |
| **RAM** | 6 GB+ | 6 GB | Memória para 18 containers |
| **Disco** | 20 GB+ | 24 GB | Sistema + dados + logs |
| **Rede** | 1 Gbps | 1 Gbps | Interface na DMZ |

### Software

| Componente | Versão Mínima | Descrição |
|------------|---------------|-----------|
| **Sistema Operativo** | Ubuntu 20.04+ / Debian 11+ | Linux 64-bit |
| **Docker** | 20.10+ | Container runtime |
| **Docker Compose** | 2.0+ | Orquestração de containers |
| **Kernel** | 4.18+ | Suporte completo a containers |

### Portas Necessárias

| Porta | Protocolo | Serviço | Descrição |
|-------|-----------|---------|-----------|
| 25 | TCP | SMTP | Email submission (MTA-to-MTA) |
| 80 | TCP | HTTP | Redirect para HTTPS |
| 110 | TCP | POP3 | Email retrieval (inseguro) |
| 143 | TCP | IMAP | Email retrieval |
| 443 | TCP | HTTPS | Web interface, API |
| 465 | TCP | SMTPS | SMTP over SSL |
| 587 | TCP | SMTP Submission | SMTP com STARTTLS |
| 993 | TCP | IMAPS | IMAP over SSL |
| 995 | TCP | POP3S | POP3 over SSL |
| 4190 | TCP | Sieve | Filtros de email |

---

## 🖥️ Informação da VM

### Configuração no Proxmox

```bash
# Criação da VM no Proxmox VE
qm create 108 \
  --name mailcow \
  --memory 6144 \
  --cores 2 \
  --sockets 1 \
  --net0 virtio,bridge=vmbr0,tag=10 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:24 \
  --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom \
  --boot order=scsi0;ide2
```

### Parâmetros da VM

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **VM ID** | 108 | Identificador no Proxmox |
| **Nome** | mailcow | Hostname da VM |
| **IP** | 10.0.0.20 | Endereço na DMZ |
| **Gateway** | 10.0.0.1 | pfSense DMZ interface |
| **DNS** | 192.168.1.10 | Domain Controller |
| **Bridge** | vmbr0 (VLAN 10) | DMZ network |
| **Hostname** | mail.fsociety.pt | FQDN público |

---

## 🛠️ Preparação do Sistema

### 1. Atualizar o Sistema

```bash
# Atualizar lista de pacotes
sudo apt update

# Atualizar pacotes instalados
sudo apt upgrade -y

# Instalar pacotes essenciais
sudo apt install -y curl wget git nano vim htop net-tools
```

### 2. Configurar Hostname

```bash
# Definir hostname
sudo hostnamectl set-hostname mail.fsociety.pt

# Adicionar entrada no /etc/hosts
echo "10.0.0.20 mail.fsociety.pt mail" | sudo tee -a /etc/hosts

# Verificar
hostnamectl
```

**Saída esperada:**
```
   Static hostname: mail.fsociety.pt
         Icon name: computer-vm
           Chassis: vm
```

### 3. Configurar Rede Estática

```bash
# Editar netplan
sudo nano /etc/netplan/00-installer-config.yaml
```

**Conteúdo:**
```yaml
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 10.0.0.20/24
      routes:
        - to: default
          via: 10.0.0.1
      nameservers:
        addresses:
          - 192.168.1.10
          - 1.1.1.1
        search:
          - fsociety.pt
```

```bash
# Aplicar configuração
sudo netplan apply

# Verificar
ip addr show ens18
```

### 4. Configurar Timezone

```bash
# Definir timezone para Europa/Lisboa
sudo timedatectl set-timezone Europe/Lisbon

# Verificar
timedatectl
```

---

## 🐳 Instalação do Docker

### 1. Remover Versões Antigas (se existirem)

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
```

### 2. Instalar Dependências

```bash
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

### 3. Adicionar Repositório Docker

```bash
# Adicionar chave GPG oficial do Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Adicionar repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4. Instalar Docker Engine

```bash
# Atualizar índice de pacotes
sudo apt update

# Instalar Docker e plugins
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Verificar instalação
docker --version
docker compose version
```

**Saída esperada:**
```
Docker version 24.0.7, build afdd53b
Docker Compose version v2.23.0
```

### 5. Configurar Permissões

```bash
# Adicionar utilizador ao grupo docker
sudo usermod -aG docker $USER

# Ativar e iniciar Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verificar status
sudo systemctl status docker
```

### 6. Testar Docker

```bash
# Executar container de teste
docker run hello-world
```

---

## 📦 Instalação do Mailcow

### 1. Criar Diretório Base

```bash
# Criar diretório de instalação
sudo mkdir -p /opt/mailcow-dockerized
cd /opt/mailcow-dockerized
```

### 2. Clonar Repositório

```bash
# Clonar a última versão estável
sudo git clone https://github.com/mailcow/mailcow-dockerized.git .

# Verificar branch
git branch
```

### 3. Gerar Configuração

O script `generate_config.sh` cria o ficheiro `mailcow.conf` com configurações personalizadas:

```bash
# Executar script de configuração
sudo ./generate_config.sh
```

**Interação durante execução:**

```
Mail server hostname (FQDN) - this is not your mail domain, 
but your mail server's hostname: mail.fsociety.pt

Timezone [Europe/Berlin]: Europe/Lisbon

Which branch of mailcow do you want to use?

Available Branches:
- master branch (stable updates) | default, recommended [1]
- nightly branch (unstable updates, testing) | not-production ready [2]
Choose the Branch with it´s number [1/2] 1
```

### 4. Verificar Configuração Gerada

```bash
# Ver configuração principal
cat mailcow.conf | grep -v "^#" | grep -v "^$"
```

**Principais variáveis:**
```bash
MAILCOW_HOSTNAME=mail.fsociety.pt
MAILCOW_TZ=Europe/Lisbon
```

---

## ⚙️ Configuração Inicial

### 1. Ajustar mailcow.conf

Editar configurações adicionais antes da primeira inicialização:

```bash
sudo nano mailcow.conf
```

**Configurações importantes:**

```bash
# Hostname público
MAILCOW_HOSTNAME=mail.fsociety.pt

# Timezone
MAILCOW_TZ=Europe/Lisbon

# Let's Encrypt (produção)
SKIP_LETS_ENCRYPT=n
ACME_CONTACT=admin@fsociety.pt

# Bind IPs (0.0.0.0 para aceitar todas)
HTTP_PORT=80
HTTPS_PORT=443
HTTP_BIND=0.0.0.0
HTTPS_BIND=0.0.0.0

# SQL
DBNAME=mailcow
DBUSER=mailcow
DBPASS=<gerada_automaticamente>
DBROOT=<gerada_automaticamente>

# Configurações de email
MAILDIR_SUB=Maildir
```

### 2. Configurar Limites de Sistema

```bash
# Aumentar limites de file descriptors
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Configurar sysctl
sudo nano /etc/sysctl.conf
```

**Adicionar:**
```
vm.overcommit_memory=1
net.core.somaxconn=65535
```

```bash
# Aplicar
sudo sysctl -p
```

---

## 🚀 Inicialização dos Containers

### 1. Pull das Imagens Docker

```bash
cd /opt/mailcow-dockerized

# Download de todas as imagens (pode demorar 10-15 minutos)
sudo docker compose pull
```

### 2. Iniciar Mailcow

```bash
# Iniciar todos os containers em background
sudo docker compose up -d
```

**Saída esperada:**
```
[+] Running 18/18
 ✔ Container mailcowdockerized-unbound-mailcow-1           Started
 ✔ Container mailcowdockerized-mysql-mailcow-1             Started
 ✔ Container mailcowdockerized-redis-mailcow-1             Started
 ✔ Container mailcowdockerized-clamd-mailcow-1             Started
 ✔ Container mailcowdockerized-olefy-mailcow-1             Started
 ✔ Container mailcowdockerized-memcached-mailcow-1         Started
 ✔ Container mailcowdockerized-postfix-mailcow-1           Started
 ✔ Container mailcowdockerized-dovecot-mailcow-1           Started
 ✔ Container mailcowdockerized-rspamd-mailcow-1            Started
 ✔ Container mailcowdockerized-php-fpm-mailcow-1           Started
 ✔ Container mailcowdockerized-sogo-mailcow-1              Started
 ✔ Container mailcowdockerized-nginx-mailcow-1             Started
 ✔ Container mailcowdockerized-acme-mailcow-1              Started
 ✔ Container mailcowdockerized-netfilter-mailcow-1         Started
 ✔ Container mailcowdockerized-watchdog-mailcow-1          Started
 ✔ Container mailcowdockerized-dockerapi-mailcow-1         Started
 ✔ Container mailcowdockerized-ofelia-mailcow-1            Started
 ✔ Container mailcowdockerized-postfix-tlspol-mailcow-1    Started
```

### 3. Verificar Status dos Containers

```bash
# Listar containers
sudo docker compose ps
```

Todos os 18 containers devem estar com status `Up`:
- nginx-mailcow
- postfix-mailcow
- dovecot-mailcow
- rspamd-mailcow
- clamd-mailcow
- sogo-mailcow
- mysql-mailcow
- redis-mailcow
- php-fpm-mailcow
- acme-mailcow
- unbound-mailcow
- netfilter-mailcow
- watchdog-mailcow
- dockerapi-mailcow
- ofelia-mailcow
- olefy-mailcow
- memcached-mailcow
- postfix-tlspol-mailcow

---

## ✅ Verificação Pós-Instalação

### 1. Verificar Logs

```bash
# Ver logs de todos os containers
sudo docker compose logs --tail=50

# Ver logs de um container específico
sudo docker compose logs -f nginx-mailcow
```

### 2. Testar Acesso Web

```bash
# Teste local
curl -I http://localhost

# Teste HTTPS (após Let's Encrypt)
curl -I https://mail.fsociety.pt
```

### 3. Aceder à Interface Web

**URL:** https://mail.fsociety.pt

**Credenciais padrão:**
- **Utilizador:** `admin`
- **Password:** `moohoo`

⚠️ **IMPORTANTE:** Alterar a password imediatamente após o primeiro login!

### 4. Verificar Portas Abertas

```bash
# Verificar portas em escuta
sudo ss -tlnp | grep -E ':(25|80|110|143|443|465|587|993|995|4190)'
```

### 5. Verificar Let's Encrypt

```bash
# Ver logs do ACME (Let's Encrypt)
sudo docker compose logs acme-mailcow

# Certificado deve ser gerado automaticamente
sudo docker compose exec acme-mailcow ls -la /var/lib/acme/certs/
```

### 6. Comandos Úteis

```bash
# Parar todos os containers
sudo docker compose down

# Reiniciar Mailcow
sudo docker compose restart

# Ver uso de recursos
sudo docker stats

# Atualizar Mailcow
sudo ./update.sh
```

---

## 🔐 Primeiros Passos Pós-Instalação

### 1. Alterar Password de Admin

1. Aceder a https://mail.fsociety.pt
2. Login: `admin` / `moohoo`
3. Ir a **System** → **Administrator**
4. Alterar password para uma forte

### 2. Adicionar Domínio

Seguir o guia [03-dominios-mailboxes.md](03-dominios-mailboxes.md)

### 3. Configurar DNS

Seguir o guia [07-dns-records.md](07-dns-records.md)

### 4. Configurar Rspamd

Seguir o guia [04-rspamd.md](04-rspamd.md)

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

**[⬅️ Anterior: README](README.md)** | **[Índice](README.md)** | **[Próximo: Configuração ➡️](02-configuracao.md)**

</div>

---

*Última atualização: Dezembro 2024*
