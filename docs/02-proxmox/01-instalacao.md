# 📦 Instalação do Proxmox VE

> Guia completo de instalação do Proxmox VE 9.0.3, incluindo requisitos de hardware, criação de USB bootável e configuração inicial.

---

## 📋 Requisitos de Hardware

### Mínimos

| Componente | Especificação Mínima |
|------------|---------------------|
| **CPU** | Intel Core i3 ou AMD Ryzen 3 com suporte a virtualização (Intel VT-x/AMD-V) |
| **RAM** | 4 GB (8 GB recomendado) |
| **Disco** | 32 GB (SSD recomendado) |
| **Rede** | 1 Gbps Ethernet |

### Recomendados para Produção

| Componente | Especificação Recomendada |
|------------|--------------------------|
| **CPU** | Intel Core i5/i7 ou AMD Ryzen 5/7 com 4+ cores |
| **RAM** | 16 GB ou mais |
| **Disco** | 120 GB+ SSD/NVMe para sistema + HDD para VMs |
| **Rede** | 1 Gbps+ Ethernet (múltiplas interfaces recomendadas) |

### Hardware do Projeto FSociety

| Componente | Especificação |
|------------|---------------|
| **CPU** | Intel Core i5-7300HQ @ 2.50GHz |
| **Cores** | 4 cores, 1 thread/core |
| **RAM** | 16 GB DDR4 |
| **Disco 1** | HDD 1TB (sda) - Storage de VMs |
| **Disco 2** | NVMe 224GB (nvme0n1) - VMs críticas + Swap |
| **Rede** | USB Ethernet Adapter (Gigabit) |

---

## 💿 Download e Preparação

### 1. Download do Proxmox VE

```bash
# URL de download oficial
# https://www.proxmox.com/en/downloads

# Versão utilizada no projeto
# Proxmox VE 9.0 ISO Installer
# Ficheiro: proxmox-ve_9.0-3.iso
```

| Informação | Detalhes |
|------------|----------|
| **Versão** | 9.0-3 |
| **Tamanho** | ~1.2 GB |
| **Arquitetura** | AMD64 (x86_64) |
| **Tipo** | ISO bootável |

### 2. Verificação de Integridade (Recomendado)

```bash
# Download do checksum
wget https://enterprise.proxmox.com/iso/SHA256SUMS

# Verificar checksum do ISO
sha256sum proxmox-ve_9.0-3.iso

# Comparar com o valor em SHA256SUMS
cat SHA256SUMS | grep proxmox-ve_9.0-3.iso
```

### 3. Criação de USB Bootável

#### No Linux

```bash
# Identificar dispositivo USB
lsblk

# Exemplo de saída:
# sdb      8:16   1  14.9G  0 disk
# └─sdb1   8:17   1  14.9G  0 part

# Criar USB bootável (substituir /dev/sdX pelo seu dispositivo)
sudo dd if=proxmox-ve_9.0-3.iso of=/dev/sdX bs=4M status=progress && sync

# ATENÇÃO: Certificar-se do dispositivo correto para evitar perda de dados!
```

#### No Windows

Utilizar ferramentas como:
- **Rufus** (https://rufus.ie/)
- **balenaEtcher** (https://www.balena.io/etcher/)

**Configurações no Rufus:**
| Opção | Valor |
|-------|-------|
| Partition scheme | MBR |
| Target system | BIOS or UEFI |
| File system | FAT32 |
| Cluster size | Default |

#### No macOS

```bash
# Converter ISO para DMG (se necessário)
hdiutil convert -format UDRW -o proxmox-ve.dmg proxmox-ve_9.0-3.iso

# Identificar dispositivo USB
diskutil list

# Desmontar USB
diskutil unmountDisk /dev/diskN

# Criar USB bootável
sudo dd if=proxmox-ve.dmg of=/dev/rdiskN bs=4m && sync
```

---

## 🚀 Processo de Instalação

### 1. Boot pelo USB

1. Inserir USB no servidor
2. Entrar na BIOS/UEFI (geralmente F2, F12, DEL ou ESC)
3. Configurar boot priority para USB
4. Guardar e reiniciar

### 2. Ecrã de Boot do Proxmox

```
┌──────────────────────────────────────────────────┐
│   Proxmox Virtual Environment                    │
│   (Default)                                      │
│                                                  │
│   Install Proxmox VE (Graphical)           <- ✓ │
│   Install Proxmox VE (Terminal UI)              │
│   Advanced Options                               │
│   Rescue Boot                                    │
│   Test Memory                                    │
└──────────────────────────────────────────────────┘
```

Selecionar: **Install Proxmox VE (Graphical)**

### 3. Acordo de Licença

```
┌──────────────────────────────────────────────────┐
│   Proxmox VE - End User License Agreement       │
│                                                  │
│   [...]                                          │
│   I agree to the terms of the license           │
│                                                  │
│   [ Agree ]  [ Cancel ]                          │
└──────────────────────────────────────────────────┘
```

Clicar em **I agree**

### 4. Seleção de Disco Target

```
Target Harddisk:
┌──────────────────────────────────────────────────┐
│ /dev/sda (931.5 GiB, ATA HDD)               [▼] │
└──────────────────────────────────────────────────┘

Options:
┌──────────────────────────────────────────────────┐
│ Filesystem:  ext4                            [▼] │
│ hdsize:      [_________________________]         │
│              (leave empty to use all)            │
└──────────────────────────────────────────────────┘

[X] Advanced Options
```

#### Opções do Projeto FSociety

| Opção | Valor | Descrição |
|-------|-------|-----------|
| **Target Disk** | /dev/sda (931.5 GB HDD) | Disco principal |
| **Filesystem** | ext4 | Sistema de ficheiros (alternativa: ZFS) |
| **hdsize** | 100 | Reservar 100 GB para o sistema (deixar espaço para LVM) |

> **💡 Nota**: O Proxmox criará automaticamente partições LVM no espaço restante

#### Advanced Options (LVM)

```
┌──────────────────────────────────────────────────┐
│ swapsize (GB):    8                              │
│ maxroot (GB):     96                             │
│ minfree (GB):     16                             │
│ maxvz (GB):       794                            │
└──────────────────────────────────────────────────┘
```

| Opção | Valor | Descrição |
|-------|-------|-----------|
| **swapsize** | 8 GB | Swap (pode ser 0 se usar NVMe) |
| **maxroot** | 96 GB | Tamanho máximo da partição root |
| **minfree** | 16 GB | Espaço livre no volume group |
| **maxvz** | 794 GB | Volume para VMs (local-lvm) |

### 5. Configuração de País e Timezone

```
Country:    Portugal                              [▼]
Timezone:   Europe/Lisbon                         [▼]
Keyboard:   Portuguese                            [▼]
```

### 6. Password de Administração e Email

```
Password:           [________________]
Confirm Password:   [________________]
Email:              admin@fsociety.pt
```

| Campo | Valor |
|-------|-------|
| **Password** | [password forte - guardar em local seguro] |
| **Email** | admin@fsociety.pt (ou email do administrador) |

> **⚠️ Importante**: Email usado para notificações do sistema

### 7. Configuração de Rede

```
Management Interface:  enx2c16dba588ba          [▼]
Hostname (FQDN):      mail.fsociety.pt
IP Address (CIDR):    192.168.31.34/24
Gateway:              192.168.31.1
DNS Server:           8.8.8.8
```

#### Configuração do Projeto

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Interface** | enx2c16dba588ba | USB Ethernet Adapter |
| **Hostname** | mail.fsociety.pt | FQDN do servidor |
| **IP Address** | 192.168.31.34/24 | IP estático na rede WAN |
| **Gateway** | 192.168.31.1 | Gateway da rede |
| **DNS Server** | 8.8.8.8 | Google DNS (ou 1.1.1.1) |

> **💡 Nota**: O hostname não precisa ter relação com função mail, é apenas o nome atribuído

### 8. Revisão e Confirmação

```
┌──────────────────────────────────────────────────┐
│   Summary                                        │
│                                                  │
│   Country:        Portugal                       │
│   Timezone:       Europe/Lisbon                  │
│   Keyboard:       pt                             │
│   Email:          admin@fsociety.pt              │
│   Hostname:       mail.fsociety.pt               │
│   IP Address:     192.168.31.34/24               │
│   Gateway:        192.168.31.1                   │
│   DNS:            8.8.8.8                        │
│   Disk:           /dev/sda                       │
│                                                  │
│   [Install] [Abort]                              │
└──────────────────────────────────────────────────┘
```

Verificar todas as configurações e clicar em **Install**

### 9. Instalação

```
Installing Proxmox VE...

[████████████████████████████████] 100%

Copying files...
Creating LVM volumes...
Installing packages...
Configuring system...

Installation successful!

[Reboot]
```

- Duração: ~5-15 minutos (depende do hardware)
- Remover USB após instalação
- Clicar em **Reboot**

---

## ⚙️ Configuração Inicial

### 1. Primeiro Boot

Após o reboot, o servidor iniciará e mostrará:

```
Welcome to the Proxmox Virtual Environment. Please use your web
browser to configure this server - connect to:

  https://192.168.31.34:8006/

Login credentials:
  Username: root
  Password: <password configurada durante instalação>
```

### 2. Acesso à Interface Web

De um computador na rede:

```
URL: https://192.168.31.34:8006/
Username: root
Password: [password configurada]
```

> **⚠️ Certificado**: O browser mostrará aviso de certificado auto-assinado. 
> Aceitar e continuar (normal em instalações novas)

### 3. Remover Subscrição Popup (Opcional)

Por defeito, Proxmox mostra popup sobre subscrição enterprise.

```bash
# Conectar via SSH
ssh root@192.168.31.34

# Editar ficheiro
nano /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Procurar (Ctrl+W):
# Proxmox.Utils.checked_command

# Substituir função inteira por:
void({ //Proxmox.Utils.checked_command
    checked_command: function(orig_cmd) {
        Proxmox.Utils.API2Request({
            url: '/version',
            method: 'GET',
            success: function(response, opts) {
                orig_cmd();
            }
        });
    }
});

# Guardar: Ctrl+O, Enter
# Sair: Ctrl+X

# Limpar cache do browser
# ou pressionar Ctrl+Shift+R na interface web
```

> **Nota**: Esta alteração é revertida após updates do Proxmox

### 4. Configurar Repositórios

#### Desativar Repositório Enterprise (sem subscrição)

```bash
# Comentar repositório enterprise
nano /etc/apt/sources.list.d/pve-enterprise.list

# Comentar a linha (adicionar #):
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
```

#### Adicionar Repositório No-Subscription

```bash
# Adicionar repositório no-subscription
nano /etc/apt/sources.list

# Adicionar no final:
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
```

#### Atualizar Sistema

```bash
# Atualizar lista de pacotes
apt update

# Atualizar sistema
apt dist-upgrade -y

# Reiniciar se houver update de kernel
reboot
```

### 5. Configurar Segundo Disco (NVMe)

Se tiver segundo disco para storage adicional:

```bash
# Listar discos
lsblk

# Saída esperada:
# nvme0n1     259:0    0 223.6G  0 disk

# Criar partição LVM
fdisk /dev/nvme0n1
# n (nova partição)
# p (primária)
# 1 (número 1)
# [Enter] (primeiro setor padrão)
# [Enter] (último setor padrão)
# t (tipo)
# 8e (Linux LVM)
# w (write)

# Criar Physical Volume
pvcreate /dev/nvme0n1p1

# Criar Volume Group
vgcreate pve-nvme /dev/nvme0n1p1

# Criar Thin Pool
lvcreate -L 200G -T pve-nvme/data

# Adicionar ao Proxmox via Web UI:
# Datacenter → Storage → Add → LVM-Thin
# ID: pve-nvme
# Volume group: pve-nvme
# Thin Pool: data
# Content: Disk image, Container
```

---

## ✅ Verificação da Instalação

### 1. Verificar Status do Sistema

#### Via Web UI

```
Dashboard → mail (node)

Verificar:
- Status: online
- CPU: ~5-10% idle
- Memory: 16 GB total
- Uptime: [tempo desde boot]
- Storage: local, local-lvm visíveis
```

#### Via CLI

```bash
# Status do node
pvesh get /nodes/mail/status

# Versão do Proxmox
pveversion

# Saída esperada:
# pve-manager/9.0.3/...
# kernel: 6.14.8-2-pve

# Status dos serviços
systemctl status pve-cluster
systemctl status pvedaemon
systemctl status pveproxy

# Verificar storage
pvesm status

# Saída esperada:
# local          dir     active
# local-lvm      lvmthin active
```

### 2. Verificar Rede

```bash
# Interfaces de rede
ip addr show

# Verificar conectividade
ping -c 4 8.8.8.8
ping -c 4 google.com

# Verificar DNS
nslookup proxmox.com

# Verificar firewall
pve-firewall status
```

### 3. Verificar Logs

```bash
# Logs do sistema
journalctl -xe

# Logs do Proxmox
tail -f /var/log/pve/tasks/active
```

---

## 🔧 Configuração Pós-Instalação

### 1. Configurar NTP

```bash
# Editar configuração NTP
nano /etc/systemd/timesyncd.conf

# Adicionar:
[Time]
NTP=pt.pool.ntp.org
FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org

# Reiniciar serviço
systemctl restart systemd-timesyncd

# Verificar status
timedatectl status
```

### 2. Configurar Email (opcional)

```bash
# Instalar postfix para notificações
apt install postfix mailutils

# Configurar postfix como satellite system
# Smarthost: [servidor SMTP]

# Testar email
echo "Teste de email do Proxmox" | mail -s "Teste Proxmox" admin@fsociety.pt
```

### 3. Configurar SSH Keys (recomendado)

```bash
# No cliente, gerar chave SSH (se não tiver)
ssh-keygen -t ed25519 -C "admin@fsociety.pt"

# Copiar chave pública para o servidor
ssh-copy-id root@192.168.31.34

# Testar login
ssh root@192.168.31.34

# Opcional: Desativar login por password
nano /etc/ssh/sshd_config
# PasswordAuthentication no

systemctl restart sshd
```

---

## 🐛 Troubleshooting

### Problema: Não consigo aceder à interface web

**Soluções:**

1. Verificar se servidor está ligado e com IP correto
   ```bash
   ip addr show
   ```

2. Verificar se serviço pveproxy está ativo
   ```bash
   systemctl status pveproxy
   systemctl restart pveproxy
   ```

3. Verificar firewall
   ```bash
   iptables -L -n | grep 8006
   ```

4. Limpar cache do browser ou usar modo privado

### Problema: Repositório enterprise não acessível

**Solução:**

```bash
# Comentar repositório enterprise
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Adicionar repositório no-subscription
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list

# Atualizar
apt update
```

### Problema: Erro "TASK ERROR: command 'lvcreate' failed"

**Solução:**

Verificar espaço disponível no volume group:

```bash
vgs
lvs

# Se necessário, redimensionar
lvresize -L +50G /dev/pve/data
```

---

## 📖 Próximos Passos

Após a instalação, prosseguir com:

1. ✅ **Instalação Concluída**
2. ➡️ [Configuração de Rede](02-configuracao-rede.md) - Criar bridges para VMs
3. ➡️ [Configuração de Storage](03-storage.md) - Configurar storage adicional
4. ➡️ [Criação de VMs](04-criacao-vms.md) - Criar primeira VM

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

**[⬅️ Voltar ao Índice](README.md)** | **[Próximo: Configuração de Rede ➡️](02-configuracao-rede.md)**

</div>

---

*Última atualização: Dezembro 2025*
