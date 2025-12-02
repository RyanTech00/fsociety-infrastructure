# 🔌 Configuração de Interfaces

> Documentação detalhada da configuração das interfaces de rede do pfSense, incluindo WAN, LAN, DMZ e interfaces OpenVPN.

---

## 📋 Visão Geral das Interfaces

| Interface | Device | Tipo | Endereço IP | Gateway | Função |
|-----------|--------|------|-------------|---------|--------|
| **WAN** | vtnet0 | Physical | 192.168.31.100/24 | 192.168.31.1 | Internet |
| **LAN** | vtnet1 | Physical | 192.168.1.1/24 | - | Rede Interna |
| **DMZ** | vtnet2 | Physical | 10.0.0.1/24 | - | Servidores Públicos |
| **OpenVPN Local** | ovpns1 | Virtual | 10.9.0.1/24 | - | VPN Backup |
| **OpenVPN RADIUS** | ovpns2 | Virtual | 10.8.0.1/24 | - | VPN Principal |

---

## 🌐 Interface WAN (vtnet0)

### Configuração Geral

```
Interfaces → WAN
```

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **Enable** | ✅ | Interface ativada |
| **Description** | WAN | Nome da interface |
| **IPv4 Configuration Type** | Static IPv4 | IP estático |
| **IPv6 Configuration Type** | None | IPv6 desativado |
| **MAC Address** | (auto) | MAC gerado pelo Proxmox |
| **MTU** | 1500 | MTU padrão |
| **MSS** | (blank) | Auto |

### Static IPv4 Configuration

| Parâmetro | Valor |
|-----------|-------|
| **IPv4 Address** | 192.168.31.100 / 24 |
| **IPv4 Upstream gateway** | WAN_DHCP (192.168.31.1) |

### Reserved Networks

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **Block private networks** | ❌ Desativado | Permite gestão interna |
| **Block bogon networks** | ✅ Ativado | Bloqueia IPs inválidos |

### Gateway Configuration

```
System → Routing → Gateways
```

| Parâmetro | Valor |
|-----------|-------|
| **Name** | WAN_DHCP |
| **Interface** | WAN |
| **Address Family** | IPv4 |
| **Gateway** | 192.168.31.1 |
| **Monitor IP** | 1.1.1.1 (Cloudflare DNS) |
| **Disable Gateway Monitoring** | ❌ Não |
| **Mark Gateway as Down** | ❌ Não |
| **Weight** | 1 |
| **Priority** | 255 |

### Verificação

```bash
# Via console ou SSH
# Verificar IP
ifconfig vtnet0

# Verificar gateway
ping -c 4 192.168.31.1

# Verificar conectividade internet
ping -c 4 1.1.1.1
```

**Saída esperada**:
```
vtnet0: flags=8863<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
        inet 192.168.31.100 netmask 0xffffff00 broadcast 192.168.31.255
```

---

## 🏠 Interface LAN (vtnet1)

### Configuração Geral

```
Interfaces → LAN
```

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **Enable** | ✅ | Interface ativada |
| **Description** | LAN | Nome da interface |
| **IPv4 Configuration Type** | Static IPv4 | IP estático |
| **IPv6 Configuration Type** | None | IPv6 desativado |
| **MAC Address** | (auto) | MAC gerado pelo Proxmox |
| **MTU** | 1500 | MTU padrão |
| **MSS** | (blank) | Auto |

### Static IPv4 Configuration

| Parâmetro | Valor |
|-----------|-------|
| **IPv4 Address** | 192.168.1.1 / 24 |
| **IPv4 Upstream gateway** | None | LAN é rede interna |

### Servidores na LAN

| Servidor | IP | Função |
|----------|----|----|
| **Domain Controller** | 192.168.1.10 | AD, DNS, DHCP, RADIUS |
| **Proxmox Backup Server** | 192.168.1.30 | Backup |
| **Nextcloud** | 192.168.1.40 | Ficheiros e colaboração |
| **Wazuh Manager** | 192.168.1.50 | SIEM e monitorização |

### DHCP Server

```
Services → DHCP Server → LAN
```

| Parâmetro | Valor |
|-----------|-------|
| **Enable** | ✅ Ativado |
| **Range** | 192.168.1.100 - 192.168.1.200 |
| **Subnet** | 192.168.1.0 |
| **Subnet Mask** | 255.255.255.0 |
| **Available Range** | 192.168.1.1 - 192.168.1.254 |

#### Servers

| Parâmetro | Valor |
|-----------|-------|
| **Domain name** | fsociety.pt |
| **DNS servers** | 192.168.1.10 (DC) |
| **Gateway** | 192.168.1.1 (pfSense) |
| **NTP Server** | 192.168.1.1 |

#### Other Options

| Parâmetro | Valor |
|-----------|-------|
| **Default lease time** | 7200 seconds (2h) |
| **Maximum lease time** | 86400 seconds (24h) |

### DHCP Static Mappings (Reservas)

```
Services → DHCP Server → LAN → DHCP Static Mappings
```

| Hostname | MAC Address | IP Address | Descrição |
|----------|-------------|------------|-----------|
| dc | (MAC do DC) | 192.168.1.10 | Domain Controller |
| pbs | (MAC do PBS) | 192.168.1.30 | Proxmox Backup Server |
| files | (MAC do Files) | 192.168.1.40 | Nextcloud Server |
| wazuh | (MAC do Wazuh) | 192.168.1.50 | Wazuh Manager |

### Verificação

```bash
# Via console
ifconfig vtnet1

# Testar DHCP (de um cliente)
ipconfig /renew  # Windows
dhclient vtnet1  # Linux
```

---

## 🔒 Interface DMZ (vtnet2)

### Configuração Geral

```
Interfaces → DMZ
```

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **Enable** | ✅ | Interface ativada |
| **Description** | DMZ | Nome da interface |
| **IPv4 Configuration Type** | Static IPv4 | IP estático |
| **IPv6 Configuration Type** | None | IPv6 desativado |
| **MAC Address** | (auto) | MAC gerado pelo Proxmox |
| **MTU** | 1500 | MTU padrão |
| **MSS** | (blank) | Auto |

### Static IPv4 Configuration

| Parâmetro | Valor |
|-----------|-------|
| **IPv4 Address** | 10.0.0.1 / 24 |
| **IPv4 Upstream gateway** | None | DMZ é rede isolada |

### Servidores na DMZ

| Servidor | IP | Função | Portas Públicas |
|----------|----|----|----------------|
| **Mailcow** | 10.0.0.20 | Mail Server | 25, 110, 143, 465, 587, 993, 995, 4190 |
| **Webserver** | 10.0.0.30 | Nginx | 80, 443 |

### DHCP Server

❌ **DHCP Desativado na DMZ**

Motivo: Servidores DMZ têm IPs estáticos configurados manualmente para maior segurança e controlo.

### Verificação

```bash
# Via console
ifconfig vtnet2

# Testar conectividade aos servidores DMZ
ping 10.0.0.20  # Mailcow
ping 10.0.0.30  # Webserver
```

---

## 🔐 Interface OpenVPN Local (ovpns1)

### Características

| Parâmetro | Valor |
|-----------|-------|
| **Interface** | ovpns1 (virtual) |
| **Tipo** | OpenVPN Server |
| **Protocol** | UDP |
| **Port** | 1194 |
| **Tunnel Network** | 10.9.0.0/24 |
| **Gateway** | 10.9.0.1 |
| **Autenticação** | Local Database |
| **Função** | VPN de emergência/backup |

### Configuração

A interface é criada automaticamente quando o servidor OpenVPN é configurado:

```
VPN → OpenVPN → Servers → Edit Server
```

### Clientes

```
Status → OpenVPN

Servidor: pfSense OpenVPN Local (UDP:1194)
- Remote Address: 10.9.0.0/24
- Virtual Address: 10.9.0.2 - 10.9.0.254
- Connected Clients: (lista dinâmica)
```

### Verificação

```bash
# Ver interface criada
ifconfig ovpns1

# Ver serviço OpenVPN
sockstat -l | grep 1194

# Ver logs
clog /var/log/openvpn.log | tail -50
```

**Saída esperada**:
```
ovpns1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> metric 0 mtu 1500
        inet 10.9.0.1 --> 10.9.0.2 netmask 0xffffffff
```

---

## 🌍 Interface OpenVPN RADIUS (ovpns2)

### Características

| Parâmetro | Valor |
|-----------|-------|
| **Interface** | ovpns2 (virtual) |
| **Tipo** | OpenVPN Server |
| **Protocol** | UDP |
| **Port** | 1195 |
| **Tunnel Network** | 10.8.0.0/24 |
| **Gateway** | 10.8.0.1 |
| **Autenticação** | RADIUS (DC: 192.168.1.10) |
| **Função** | VPN principal com auth AD |

### Configuração

A interface é criada automaticamente quando o servidor OpenVPN é configurado:

```
VPN → OpenVPN → Servers → Edit Server
```

### Address Pools por Grupo

| Grupo AD | Pool IP | Alias |
|----------|---------|-------|
| GRP_TI | 10.8.0.10 - 59 | Alias_VPN_TI |
| GRP_Gestores | 10.8.0.60 - 109 | Alias_VPN_Gestores |
| GRP_Financeiro | 10.8.0.110 - 159 | Alias_VPN_Financeiro |
| GRP_Comercial | 10.8.0.160 - 209 | Alias_VPN_Comercial |
| GRP_VPN_Users | 10.8.0.210 - 254 | Alias_VPN_VPN_Users |

### Clientes Conectados

```
Status → OpenVPN

Servidor: pfSense OpenVPN Radius (UDP:1195)
- Remote Address: 10.8.0.0/24
- Virtual Address: 10.8.0.10 - 10.8.0.254
- Connected Clients: (lista com grupos AD)
```

### Verificação

```bash
# Ver interface criada
ifconfig ovpns2

# Ver serviço OpenVPN
sockstat -l | grep 1195

# Ver autenticações RADIUS
cat /var/log/system.log | grep radius

# Ver clientes conectados
pfctl -ss | grep 10.8.0
```

**Saída esperada**:
```
ovpns2: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> metric 0 mtu 1500
        inet 10.8.0.1 --> 10.8.0.2 netmask 0xffffffff
```

---

## 📊 Tabela de Roteamento

### Visualizar Rotas

```
Diagnostics → Routes
```

| Destination | Gateway | Interface | Description |
|-------------|---------|-----------|-------------|
| default | 192.168.31.1 | WAN | Internet |
| 192.168.31.0/24 | link#1 | WAN | WAN Network |
| 192.168.1.0/24 | link#2 | LAN | LAN Network |
| 10.0.0.0/24 | link#3 | DMZ | DMZ Network |
| 10.9.0.0/24 | 10.9.0.2 | ovpns1 | OpenVPN Local |
| 10.8.0.0/24 | 10.8.0.2 | ovpns2 | OpenVPN RADIUS |

### Comandos de Verificação

```bash
# Ver todas as rotas
netstat -rn

# Ver rotas IPv4
netstat -rn -f inet

# Adicionar rota estática (se necessário)
route add -net 172.16.0.0/24 192.168.1.254
```

---

## 🔍 Diagnósticos e Monitorização

### Status das Interfaces

```
Status → Interfaces
```

**Verificar para cada interface**:
- ✅ Status: up
- ✅ IPv4 Address: correto
- ✅ Gateway: configurado (WAN)
- ✅ Media: full-duplex
- ✅ Packets In/Out: incrementando

### Traffic Graph

```
Status → Traffic Graph
```

Selecionar cada interface para ver tráfego em tempo real:
- WAN (vtnet0)
- LAN (vtnet1)
- DMZ (vtnet2)
- OpenVPN Local (ovpns1)
- OpenVPN RADIUS (ovpns2)

### Packet Capture

```
Diagnostics → Packet Capture
```

**Exemplo de captura na WAN**:
```
Interface: WAN
Address Family: IPv4 Only
Protocol: TCP
Host Address: 10.0.0.20
Port: 25
Packet Count: 100
```

---

## 🧪 Testes de Conectividade

### Teste 1: Internet (WAN)

```
Diagnostics → Ping

Host: 1.1.1.1
Source Address: WAN address
Count: 4
```

**Resultado esperado**: 0% packet loss

### Teste 2: LAN → Internet

```
Diagnostics → Ping

Host: 8.8.8.8
Source Address: LAN address
Count: 4
```

**Resultado esperado**: 0% packet loss

### Teste 3: DMZ → Internet

```
Diagnostics → Ping

Host: 1.1.1.1
Source Address: DMZ address
Count: 4
```

**Resultado esperado**: 0% packet loss (se regras permitirem)

### Teste 4: LAN → DMZ

```bash
# De um cliente LAN
ping 10.0.0.20  # Mailcow
ping 10.0.0.30  # Webserver
```

### Teste 5: VPN Connectivity

```bash
# De um cliente VPN conectado
ping 192.168.1.1   # pfSense LAN
ping 192.168.1.10  # DC (se permitido)
ping 10.0.0.20     # Mailcow (se permitido)
```

---

## ⚠️ Troubleshooting

### Interface não aparece

**Sintoma**: Interface missing após reboot

**Solução**:
```bash
# Console: Opção 1 (Assign Interfaces)
# Reatribuir interfaces na ordem correta
```

### Interface UP mas sem tráfego

**Sintoma**: Status UP mas sem ping

**Solução**:
1. Verificar bridge no Proxmox
2. Verificar regras de firewall
3. Verificar gateway (se WAN)

```bash
# Verificar stats da interface
netstat -i

# Verificar erros
ifconfig vtnet0 | grep error
```

### DHCP não funciona

**Sintoma**: Clientes não recebem IP

**Solução**:
1. Verificar serviço DHCP:
```
Status → Services → dhcpd (should be running)
```

2. Verificar configuração:
```
Services → DHCP Server → LAN
- Enable: ✅
- Range: Configurado
```

3. Ver logs:
```
Status → System Logs → DHCP
```

### Gateway não responde

**Sintoma**: No route to host

**Solução**:
```bash
# Verificar gateway
netstat -rn | grep default

# Testar gateway
ping -c 4 192.168.31.1

# Verificar monitor
System → Routing → Gateways
# Status deve ser "Online"
```

---

## 📈 Monitorização com ntopng

### Ativar ntopng

```
Services → ntopng

Settings:
- Enable: ✅
- Interfaces: WAN, LAN, DMZ
- Local Networks: 192.168.1.0/24, 10.0.0.0/24, 10.8.0.0/24, 10.9.0.0/24
- Listen Port: 3000
```

### Aceder ao ntopng

```
URL: http://192.168.1.1:3000
Username: admin
Password: (configurado no setup)
```

### Métricas Monitorizadas

- **Bandwidth Usage** por interface
- **Top Talkers** (hosts mais ativos)
- **Protocol Distribution** (HTTP, HTTPS, DNS, etc.)
- **Flows** em tempo real
- **Alerts** de segurança

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

- [pfSense Interface Configuration](https://docs.netgate.com/pfsense/en/latest/interfaces/configure.html)
- [FreeBSD Network Configuration](https://docs.freebsd.org/en/books/handbook/config-network/)
- [OpenVPN Interface Documentation](https://docs.netgate.com/pfsense/en/latest/vpn/openvpn/index.html)

---

<div align="center">

**[⬅️ Voltar: Instalação](01-instalacao.md)** | **[Índice](README.md)** | **[Próximo: Aliases ➡️](03-aliases.md)**

</div>

---

*Última atualização: Dezembro 2024*
