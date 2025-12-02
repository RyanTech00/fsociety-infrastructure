# 📦 Instalação do pfSense

> Guia completo de instalação do pfSense 2.8.1 no Proxmox VE, incluindo criação da VM e configuração inicial.

---

## 📋 Pré-requisitos

| Item | Especificação |
|------|---------------|
| **Hypervisor** | Proxmox VE 8.x |
| **ISO pfSense** | pfSense-CE-2.8.1-RELEASE-amd64.iso |
| **RAM Mínima** | 2 GB (recomendado: 2-4 GB) |
| **Disco Mínimo** | 20 GB (recomendado: 40+ GB) |
| **NICs Necessárias** | 3 (WAN, LAN, DMZ) |

---

## 🖥️ Criação da VM no Proxmox

### 1. Configuração Geral

```bash
# Na interface web do Proxmox VE
# Botão: Create VM
```

| Parâmetro | Valor |
|-----------|-------|
| **Node** | Seu node Proxmox |
| **VM ID** | 100 (ou disponível) |
| **Name** | pfSense |
| **Resource Pool** | (opcional) |

### 2. Sistema Operativo

| Parâmetro | Valor |
|-----------|-------|
| **ISO Image** | pfSense-CE-2.8.1-RELEASE-amd64.iso |
| **Type** | Other |
| **Guest OS** | Other |

### 3. Sistema

| Parâmetro | Valor |
|-----------|-------|
| **Graphic card** | Default |
| **Machine** | Default (i440fx) |
| **SCSI Controller** | VirtIO SCSI |
| **BIOS** | Default (SeaBIOS) |
| **Add TPM** | ❌ Não |
| **Qemu Agent** | ✅ Sim |

### 4. Discos

| Parâmetro | Valor |
|-----------|-------|
| **Bus/Device** | VirtIO Block / 0 |
| **Storage** | local-lvm (ou seu storage) |
| **Disk size** | 42 GB |
| **Cache** | Write back |
| **Discard** | ✅ Ativado |
| **SSD emulation** | ✅ Ativado (se aplicável) |

### 5. CPU

| Parâmetro | Valor |
|-----------|-------|
| **Sockets** | 1 |
| **Cores** | 2 |
| **Type** | host (ou kvm64) |

### 6. Memória

| Parâmetro | Valor |
|-----------|-------|
| **Memory (MiB)** | 2048 |
| **Minimum memory** | 512 |
| **Ballooning** | ✅ Ativado |

### 7. Rede - **IMPORTANTE: 3 Interfaces**

#### Interface 1 - WAN (vtnet0)

| Parâmetro | Valor |
|-----------|-------|
| **Bridge** | vmbr0 (bridge com acesso à Internet) |
| **Model** | VirtIO (paravirtualized) |
| **Firewall** | ❌ Desativado |
| **MAC address** | (auto) |

#### Interface 2 - LAN (vtnet1)

| Parâmetro | Valor |
|-----------|-------|
| **Bridge** | vmbr1 (bridge LAN isolada) |
| **Model** | VirtIO (paravirtualized) |
| **Firewall** | ❌ Desativado |
| **MAC address** | (auto) |

#### Interface 3 - DMZ (vtnet2)

| Parâmetro | Valor |
|-----------|-------|
| **Bridge** | vmbr2 (bridge DMZ isolada) |
| **Model** | VirtIO (paravirtualized) |
| **Firewall** | ❌ Desativado |
| **MAC address** | (auto) |

> **💡 Nota**: As bridges devem ser criadas previamente no Proxmox em **Datacenter → Node → Network**

### 8. Confirmar Criação

Revisar todas as configurações e clicar em **Finish**.

---

## 🚀 Instalação do pfSense

### 1. Iniciar a VM

```bash
# Via CLI do Proxmox
qm start 100

# Ou via Web UI
# VM → Start
```

### 2. Boot e Instalação

1. **Boot Screen**
   - Aguardar o boot automático ou pressionar `Enter`

2. **Accept License**
   - Ler e aceitar a licença Apache 2.0
   - Pressionar `Accept`

3. **Install pfSense**
   - Selecionar: `Install pfSense`
   - Pressionar `Enter`

4. **Keymap Selection**
   - Selecionar keymap apropriado (ex: `US` ou `Portuguese`)
   - Pressionar `Enter` para continuar

5. **Partitioning**
   - Selecionar: `Auto (ZFS)` - **Recomendado**
   - Pressionar `Enter`

6. **ZFS Configuration**
   
   | Opção | Valor |
   |-------|-------|
   | **ZFS Pool Type** | stripe (para single disk) |
   | **Disk** | vtbd0 (42GB) |
   
   - Confirmar com `Yes` para destruir dados existentes

7. **Instalação**
   - Aguardar a cópia dos ficheiros (2-5 minutos)

8. **Manual Configuration**
   - Selecionar: `No` (faremos via web)
   - Pressionar `Enter`

9. **Reboot**
   - Selecionar: `Reboot`
   - **Importante**: Desconectar o ISO do CD-ROM no Proxmox

---

## ⚙️ Configuração Inicial (Console)

Após o reboot, o pfSense iniciará e mostrará o menu de console:

```
*** Welcome to pfSense 2.8.1-RELEASE (amd64) on pfSense ***

 WAN (wan)       -> vtnet0     -> DHCP
 LAN (lan)       -> vtnet1     -> 192.168.1.1

 0) Logout (SSH only)                  9) pfTop
 1) Assign Interfaces                 10) Filter Logs
 2) Set interface(s) IP address       11) Restart webConfigurator
 3) Reset webConfigurator password    12) PHP shell + pfSense tools
 4) Reset to factory defaults         13) Update from console
 5) Reboot system                     14) Disable Secure Shell (sshd)
 6) Halt system                       15) Restore recent configuration
 7) Ping host                         16) Restart PHP-FPM
 8) Shell

Enter an option:
```

### 1. Atribuir Interfaces

Escolher opção **1** (Assign Interfaces)

```
Should VLANs be set up now? [y|n]: n

Enter the WAN interface name: vtnet0
Enter the LAN interface name: vtnet1
Enter the Optional 1 interface name: vtnet2

Do you want to proceed? [y|n]: y
```

### 2. Configurar IP da WAN

Escolher opção **2** (Set interface(s) IP address)

```
Available interfaces:
1 - WAN (vtnet0)
2 - LAN (vtnet1)
3 - OPT1 (vtnet2)

Enter the number of the interface: 1

Configure IPv4 address WAN interface via DHCP? [y|n]: n

Enter the new WAN IPv4 address: 192.168.31.100
Enter the new WAN IPv4 subnet bit count: 24
Enter the new WAN IPv4 upstream gateway address: 192.168.31.1

Configure IPv6 address WAN interface via DHCP6? [y|n]: n

Do you want to revert to HTTP as the webConfigurator protocol? [y|n]: n
```

### 3. Configurar IP da LAN

Escolher opção **2** novamente

```
Available interfaces:
1 - WAN (vtnet0)
2 - LAN (vtnet1)
3 - OPT1 (vtnet2)

Enter the number of the interface: 2

Enter the new LAN IPv4 address: 192.168.1.1
Enter the new LAN IPv4 subnet bit count: 24

For a WAN, enter the new LAN IPv4 upstream gateway address: [Enter]

Configure IPv6 address LAN interface via DHCP6? [y|n]: n

Do you want to enable the DHCP server on LAN? [y|n]: y
Enter the start address of the DHCP range: 192.168.1.100
Enter the end address of the DHCP range: 192.168.1.200

Do you want to revert to HTTP as the webConfigurator protocol? [y|n]: n
```

### 4. Configurar IP da DMZ (OPT1)

Escolher opção **2** novamente

```
Available interfaces:
1 - WAN (vtnet0)
2 - LAN (vtnet1)
3 - OPT1 (vtnet2)

Enter the number of the interface: 3

Enter the new OPT1 IPv4 address: 10.0.0.1
Enter the new OPT1 IPv4 subnet bit count: 24

For a WAN, enter the new OPT1 IPv4 upstream gateway address: [Enter]

Configure IPv6 address OPT1 interface via DHCP6? [y|n]: n

Do you want to enable the DHCP server on OPT1? [y|n]: n

Do you want to revert to HTTP as the webConfigurator protocol? [y|n]: n
```

---

## 🌐 Acesso à Interface Web

### 1. Conectar à Interface Web

De uma máquina na rede LAN (192.168.1.0/24):

```
URL: https://192.168.1.1
Username: admin
Password: pfsense
```

> **⚠️ Aviso de Certificado**: O browser mostrará um aviso de certificado auto-assinado. Aceitar e continuar.

### 2. Setup Wizard

#### Passo 1: Netgate Global Support

- Pode fechar ou clicar em `Next`

#### Passo 2: General Information

| Campo | Valor |
|-------|-------|
| **Hostname** | pfSense |
| **Domain** | fsociety.pt |
| **Primary DNS Server** | 1.1.1.1 (Cloudflare) |
| **Secondary DNS Server** | 1.0.0.1 |
| **DNS Server Override** | ❌ Desativado |

#### Passo 3: Time Server Information

| Campo | Valor |
|-------|-------|
| **Time server hostname** | pool.ntp.org |
| **Timezone** | Europe/Lisbon |

#### Passo 4: Configure WAN Interface

| Campo | Valor |
|-------|-------|
| **SelectedType** | Static |
| **IP Address** | 192.168.31.100 |
| **Subnet Mask** | 24 |
| **Upstream Gateway** | 192.168.31.1 |
| **Block RFC1918 Private Networks** | ❌ Desativado |
| **Block bogon networks** | ✅ Ativado |

#### Passo 5: Configure LAN Interface

| Campo | Valor |
|-------|-------|
| **LAN IP Address** | 192.168.1.1 |
| **Subnet Mask** | 24 |

#### Passo 6: Set Admin Password

- Definir password forte para o utilizador `admin`
- **Importante**: Guardar em local seguro

#### Passo 7: Reload

- Clicar em `Reload`
- Aguardar reload das configurações

#### Passo 8: Wizard Completed

- Clicar em `Finish`

---

## 🔧 Configuração Pós-Instalação

### 1. Renomear Interface OPT1 para DMZ

```
System → Assignments → Interface Assignments

OPT1:
- Description: DMZ
- Clicar em "Save"
```

### 2. Ativar Interface DMZ

```
Interfaces → DMZ

General Configuration:
- Enable: ✅ Enable interface
- Description: DMZ
- IPv4 Configuration Type: Static IPv4
- IPv4 Address: 10.0.0.1 / 24

Clicar em "Save" e depois "Apply Changes"
```

### 3. Configurar Hostname Completo

```
System → General Setup

System:
- Hostname: pfSense
- Domain: fsociety.pt
```

### 4. Ativar SSH (Opcional mas Recomendado)

```
System → Advanced → Admin Access

Secure Shell:
- Enable Secure Shell: ✅ Ativado
- SSH port: 22
- Authentication Method: Public Key and Password
- Login Protection: ✅ Ativado

Clicar em "Save"
```

### 5. Desativar Regras de Bloqueio Padrão (Se Necessário)

Para permitir comunicação inicial entre redes durante configuração:

```
Interfaces → WAN → Edit

Reserved Networks:
- Block private networks and loopback addresses: ❌ Desativado

Clicar em "Save" e "Apply Changes"
```

---

## ✅ Verificação da Instalação

### 1. Verificar Interfaces

```
Status → Interfaces

Verificar:
- WAN: UP - 192.168.31.100/24
- LAN: UP - 192.168.1.1/24
- DMZ: UP - 10.0.0.1/24
```

### 2. Verificar Conectividade

```
Diagnostics → Ping

Testar:
- 192.168.31.1 (Gateway WAN) ✅
- 1.1.1.1 (DNS Cloudflare) ✅
- 8.8.8.8 (DNS Google) ✅
```

### 3. Verificar Serviços

```
Status → Services

Verificar serviços ativos:
- dhcpd (DHCP Server)
- dpinger (Gateway Monitoring)
- ntpd (NTP Server)
- sshd (SSH Daemon)
- syslogd (System Logger)
- unbound (DNS Resolver)
```

### 4. Testar Acesso à Internet

De uma máquina cliente na LAN:

```bash
# Testar DNS
nslookup google.com

# Testar conectividade
ping 8.8.8.8
ping google.com
```

---

## 🔐 Hardening Inicial

### 1. Alterar Porta de Acesso Web (Opcional)

```
System → Advanced → Admin Access

Protocol: HTTPS
TCP port: 8009  # Porta personalizada
```

### 2. Ativar Auto-Update Check

```
System → Update Settings

Dashboard check: ✅ Enable
Check Interval: 1 day
```

### 3. Configurar Firewall Logging

```
Status → System Logs → Settings

General Logging Options:
- Firewall Log Entries: 100000
- Show log entries in reverse order: ✅
```

---

## 📸 Screenshots da Instalação

### Dashboard Após Instalação

```
Status: pfSense 2.8.1-RELEASE (amd64) - FreeBSD 15.0-CURRENT

Interfaces:
✅ WAN  - 192.168.31.100/24
✅ LAN  - 192.168.1.1/24
✅ DMZ  - 10.0.0.1/24

System Information:
- Uptime: 1 hour
- CPU usage: 5%
- Memory usage: 12% (245 MiB)
- Disk usage: 2% (900 MiB)
```

---

## 🐛 Troubleshooting

### Problema: Não consigo aceder à interface web

**Solução**:
1. Verificar que está ligado à rede LAN (192.168.1.0/24)
2. Verificar IP do cliente: `ipconfig` ou `ip addr`
3. Fazer ping ao gateway: `ping 192.168.1.1`
4. Limpar cache do browser ou usar modo privado

### Problema: Interface não aparece

**Solução**:
```bash
# No console do pfSense
1) Assign Interfaces
# Reatribuir interfaces corretamente
```

### Problema: Sem conectividade à Internet

**Solução**:
1. Verificar gateway WAN: `ping 192.168.31.1`
2. Verificar DNS: `Diagnostics → DNS Lookup`
3. Verificar regras WAN: `Firewall → Rules → WAN`

---

## 📖 Próximos Passos

Após a instalação, prosseguir com:

1. ✅ **Instalação Concluída**
2. ➡️ [Configuração de Interfaces](02-interfaces.md)
3. ➡️ [Criação de Aliases](03-aliases.md)
4. ➡️ [Regras de Firewall](04-regras-firewall.md)

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

## 📖 Referências

- [pfSense Installation Guide](https://docs.netgate.com/pfsense/en/latest/install/install-walkthrough.html)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [pfSense Hardware Requirements](https://docs.netgate.com/pfsense/en/latest/hardware/size.html)

---

<div align="center">

**[⬅️ Voltar ao Índice](README.md)** | **[Próximo: Interfaces ➡️](02-interfaces.md)**

</div>

---

*Última atualização: Dezembro 2024*
