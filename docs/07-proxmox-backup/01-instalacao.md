# 📦 Instalação do Proxmox Backup Server

> Guia completo de instalação do Proxmox Backup Server 4.0.11 como VM no Proxmox VE, incluindo configuração inicial e certificados SSL.

---

## 📋 Pré-requisitos

### Requisitos de Hardware

| Recurso | Mínimo | Recomendado | Projeto FSociety |
|---------|--------|-------------|------------------|
| **vCPU** | 1 core | 2 cores | 1 core |
| **RAM** | 1 GB | 2-4 GB | 1.5 GB |
| **Disco Sistema** | 8 GB | 16 GB | 50 GB |
| **Disco Backup** | Conforme necessário | 500 GB+ | 50 GB (datastore) |
| **Rede** | 1 Gbps | 1 Gbps+ | 1 Gbps (LAN) |

### Software

| Componente | Versão |
|------------|--------|
| **PBS** | 4.0.11 (package 4.1.0-1) |
| **Proxmox VE** | 8.x ou superior (host) |
| **ISO** | proxmox-backup-server_4.0-X.iso |

---

## 💿 Download do PBS

### 1. Obter ISO

```bash
# URL de download oficial
# https://www.proxmox.com/en/downloads/proxmox-backup-server

# Versão utilizada no projeto
# Proxmox Backup Server 4.0 ISO Installer
```

### 2. Upload para Proxmox VE

#### Via Web UI

1. **Datacenter → Node → local → ISO Images**

2. Clicar em **Upload**

3. Selecionar ficheiro `proxmox-backup-server_4.0-X.iso`

4. Aguardar upload

#### Via CLI

```bash
# SCP do ISO para o Proxmox
scp proxmox-backup-server_4.0-X.iso root@192.168.31.34:/var/lib/vz/template/iso/

# Ou download direto no Proxmox
cd /var/lib/vz/template/iso/
wget https://enterprise.proxmox.com/iso/proxmox-backup-server_4.0-X.iso
```

---

## 🖥️ Criação da VM no Proxmox VE

### Via Web UI

1. **Create VM**

2. **General**

| Campo | Valor |
|-------|-------|
| **Node** | mail |
| **VM ID** | 101 |
| **Name** | Proxmox-Backup |
| **Start at boot** | ✅ Sim |

3. **OS**

| Campo | Valor |
|-------|-------|
| **ISO image** | proxmox-backup-server_4.0-X.iso |
| **Type** | Linux |
| **Version** | 6.x - 2.6 Kernel |

4. **System**

| Campo | Valor |
|-------|-------|
| **SCSI Controller** | VirtIO SCSI |
| **Qemu Agent** | ✅ Ativado |

5. **Disks**

| Campo | Valor |
|-------|-------|
| **Bus/Device** | SCSI 0 |
| **Storage** | local-lvm |
| **Size** | 50 GB |
| **Cache** | Write back |
| **Discard** | ✅ Ativado |

6. **CPU**

| Campo | Valor |
|-------|-------|
| **Sockets** | 1 |
| **Cores** | 1 |
| **Type** | host |

7. **Memory**

| Campo | Valor |
|-------|-------|
| **Memory** | 1536 MB (1.5 GB) |
| **Ballooning** | ✅ Ativado |

8. **Network**

| Campo | Valor |
|-------|-------|
| **Bridge** | vmbr1 (LAN) |
| **Model** | VirtIO |
| **Firewall** | ❌ Desativado |

9. **Confirm** e **Finish**

### Via CLI

```bash
# Criar VM
qm create 101 \
  --name Proxmox-Backup \
  --memory 1536 \
  --cores 1 \
  --sockets 1 \
  --cpu host \
  --ostype l26 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --scsihw virtio-scsi-pci \
  --ide2 local:iso/proxmox-backup-server_4.0-X.iso,media=cdrom \
  --boot order=scsi0 \
  --onboot 1 \
  --agent 1

# Iniciar VM
qm start 101
```

---

## 🚀 Instalação do PBS

### 1. Boot pelo ISO

1. Iniciar VM

2. Aguardar boot screen do PBS

3. Selecionar: **Install Proxmox Backup Server (Graphical)**

### 2. EULA

1. Ler licença AGPL v3

2. Clicar em **I agree**

### 3. Seleção de Disco

```
Target Harddisk: /dev/sda (50 GiB)

Filesystem Options:
┌──────────────────────────────────────┐
│ Filesystem: ext4                 [▼] │
│ hdsize: 50                           │
└──────────────────────────────────────┘
```

| Opção | Valor |
|-------|-------|
| **Filesystem** | ext4 (recomendado) |
| **hdsize** | 50 (usar todo o disco) |

> **Nota**: Para datastores grandes, considerar ZFS

### 4. Localização e Timezone

```
Country:    Portugal
Timezone:   Europe/Lisbon
Keyboard:   Portuguese
```

### 5. Password de Administração

```
Password:           [password forte]
Confirm Password:   [repetir password]
Email:              hugodanielsilvacorreia@gmail.com
```

| Campo | Valor |
|-------|-------|
| **Password** | [guardar em local seguro] |
| **Email** | Email do administrador (notificações) |

### 6. Configuração de Rede

```
Management Interface:  ens18                [▼]
Hostname (FQDN):      pbs.fsociety.pt
IP Address (CIDR):    192.168.1.30/24
Gateway:              192.168.1.1
DNS Server:           192.168.1.1
```

#### Configuração do Projeto

| Campo | Valor |
|-------|-------|
| **Interface** | ens18 (VirtIO) |
| **Hostname** | pbs.fsociety.pt |
| **IP** | 192.168.1.30/24 |
| **Gateway** | 192.168.1.1 (pfSense) |
| **DNS** | 192.168.1.1 |

### 7. Confirmação e Instalação

```
Summary:
  Country:   Portugal
  Timezone:  Europe/Lisbon
  Hostname:  pbs.fsociety.pt
  IP:        192.168.1.30/24
  Gateway:   192.168.1.1

[Install] [Abort]
```

1. Verificar configurações

2. Clicar em **Install**

3. Aguardar instalação (~5 minutos)

4. Clicar em **Reboot** quando concluído

5. **Remover ISO** da VM:
   - VM → Hardware → CD/DVD → Edit → Do not use any media

---

## ⚙️ Configuração Inicial

### 1. Primeiro Acesso

Após reboot, o servidor exibe:

```
Welcome to the Proxmox Backup Server. Please use your web browser to
configure this server - connect to:

  https://192.168.1.30:8007/

Login:
  Username: root
  Password: <password configurada>
```

### 2. Acesso à Interface Web

```
URL: https://192.168.1.30:8007
Username: root
Password: [password configurada]
Realm: Linux PAM standard authentication
```

> **⚠️ Certificado**: Browser mostrará aviso (certificado auto-assinado). Aceitar e continuar.

### 3. Dashboard Inicial

Após login, o dashboard mostra:
- Status do servidor
- Recursos (CPU, memória, disco)
- Datastore configurados (nenhum ainda)
- Tarefas recentes

---

## 🔐 Configuração de Certificados SSL

### Opção 1: Certificado Auto-Assinado (Padrão)

Por defeito, PBS usa certificado auto-assinado.

**Renovar certificado:**

```bash
# SSH para o PBS
ssh root@192.168.1.30

# Gerar novo certificado
proxmox-backup-manager cert generate-self-signed

# Reiniciar serviço
systemctl restart proxmox-backup-proxy
```

### Opção 2: Let's Encrypt (Recomendado para Produção)

Se PBS for acessível via domínio público:

```bash
# Configurar ACME account
proxmox-backup-manager acme account register \
  --contact admin@fsociety.pt \
  default

# Configurar domain
proxmox-backup-manager acme domain add \
  --domain pbs.fsociety.pt

# Obter certificado
proxmox-backup-manager acme cert order

# Certificado será renovado automaticamente
```

### Opção 3: Certificado Personalizado

```bash
# Copiar certificado e chave
scp cert.pem root@192.168.1.30:/etc/proxmox-backup/proxy.pem
scp key.pem root@192.168.1.30:/etc/proxmox-backup/proxy.key

# Definir permissões
chmod 600 /etc/proxmox-backup/proxy.key
chmod 644 /etc/proxmox-backup/proxy.pem

# Reiniciar serviço
systemctl restart proxmox-backup-proxy
```

### Ver Fingerprint do Certificado

Necessário para adicionar PBS ao Proxmox VE:

```bash
# Via CLI
proxmox-backup-manager cert info

# Saída:
# subject: CN=pbs.fsociety.pt
# issuer: CN=Proxmox Backup Server
# notBefore: YYYY-MM-DD HH:MM:SS
# notAfter: YYYY-MM-DD HH:MM:SS
# Fingerprint (sha256): XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX

# Copiar o Fingerprint para usar no Proxmox VE
```

---

## 🛠️ Configurações Pós-Instalação

### 1. Atualizar Sistema

```bash
# SSH para o PBS
ssh root@192.168.1.30

# Atualizar lista de pacotes
apt update

# Atualizar sistema
apt dist-upgrade -y

# Reiniciar se necessário
reboot
```

### 2. Configurar NTP

```bash
# Verificar sincronização de tempo
timedatectl status

# Configurar NTP
nano /etc/systemd/timesyncd.conf

# Adicionar:
[Time]
NTP=pt.pool.ntp.org
FallbackNTP=0.debian.pool.ntp.org

# Reiniciar serviço
systemctl restart systemd-timesyncd

# Verificar
timedatectl show-timesync --all
```

### 3. Configurar Notificações Email

```bash
# Configurar Postfix
dpkg-reconfigure postfix

# Tipo: Satellite system
# Smarthost: [servidor SMTP]

# Testar
echo "Teste PBS" | mail -s "Teste PBS" hugodanielsilvacorreia@gmail.com
```

### 4. Configurar Firewall (Opcional)

Se usar firewall no PBS:

```bash
# Permitir acesso da rede LAN
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 8007 -j ACCEPT

# Salvar regras
iptables-save > /etc/iptables/rules.v4
```

---

## ✅ Verificação da Instalação

### Via Web UI

1. **Dashboard**
   - Servidor online
   - Recursos visíveis

2. **Configuration → Network**
   - Interface ens18: 192.168.1.30/24
   - Gateway: 192.168.1.1

3. **Configuration → DNS**
   - DNS server: 192.168.1.1

### Via CLI

```bash
# Versão do PBS
proxmox-backup-manager version

# Saída esperada:
# proxmox-backup-server 4.0.11 running version: 4.1.0-1

# Status dos serviços
systemctl status proxmox-backup
systemctl status proxmox-backup-proxy
systemctl status proxmox-backup-api

# Verificar rede
ip addr show ens18
ping -c 4 192.168.1.1
ping -c 4 8.8.8.8

# Ver logs
journalctl -u proxmox-backup -f
```

---

## 📖 Próximos Passos

Após instalação:

1. ✅ **PBS Instalado e Configurado**
2. ➡️ [Configurar Datastore](02-datastore.md) - Criar datastore para backups
3. ➡️ [Integrar com PVE](03-integracao-pve.md) - Adicionar PBS ao Proxmox VE

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

**[⬅️ Voltar ao Índice](README.md)** | **[Próximo: Datastore ➡️](02-datastore.md)**

</div>

---

*Última atualização: Dezembro 2025*
