# 🌐 DHCP Server - ISC DHCP

> **Configuração do servidor DHCP para atribuição dinâmica de IPs na rede LAN**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Instalação](#-instalação)
3. [Configuração Principal](#-configuração-principal)
4. [Reservas de IP](#-reservas-de-ip)
5. [Integração com DNS](#-integração-com-dns)
6. [Logs e Monitorização](#-logs-e-monitorização)
7. [Verificação e Testes](#-verificação-e-testes)
8. [Referências](#-referências)

---

## 📖 Visão Geral

### O que é o ISC DHCP Server?

O ISC DHCP (Internet Systems Consortium DHCP) é a implementação de referência do protocolo DHCP (Dynamic Host Configuration Protocol). Permite:

- **Atribuição automática de IPs** a dispositivos na rede
- **Configuração centralizada** de parâmetros de rede
- **Reservas estáticas** para servidores e dispositivos críticos
- **Integração com DNS** para atualizações dinâmicas

### Informação da Rede

| Parâmetro | Valor |
|-----------|-------|
| **Subnet** | 192.168.1.0/24 |
| **Range DHCP** | 192.168.1.100 - 192.168.1.200 |
| **Gateway** | 192.168.1.1 |
| **DNS Primário** | 192.168.1.10 (DC) |
| **DNS Secundário** | 192.168.1.1 (pfSense) |
| **Domínio** | fsociety.pt |

---

## 📦 Instalação

### Instalar ISC DHCP Server

```bash
# Instalar pacote
sudo apt install -y isc-dhcp-server

# Verificar versão
dhcpd --version
```

### Configurar Interface

**Ficheiro:** `/etc/default/isc-dhcp-server`

```bash
# Configurar interface de escuta
sudo nano /etc/default/isc-dhcp-server
```

**Conteúdo:**

```bash
# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

# Path to dhcpd's config file (default: /etc/dhcp/dhcpd.conf).
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf

# Path to dhcpd's PID file (default: /var/run/dhcpd.pid).
DHCPDv4_PID=/var/run/dhcpd.pid

# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
# Separate multiple interfaces with spaces, e.g. "eth0 eth1".
INTERFACESv4="ens18"
INTERFACESv6=""
```

---

## ⚙️ Configuração Principal

### Ficheiro dhcpd.conf

**Localização:** `/etc/dhcp/dhcpd.conf`

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

**Conteúdo Completo:**

```bash
# ISC DHCP Server Configuration
# Domain: fsociety.pt
# Server: dc.fsociety.pt
# Network: LAN (192.168.1.0/24)

#------------------------------------------------------------
# Configurações Globais
#------------------------------------------------------------

# Domínio e servidores DNS
option domain-name "fsociety.pt";
option domain-name-servers 192.168.1.10, 192.168.1.1;

# Tempos de lease
default-lease-time 86400;      # 24 horas
max-lease-time 604800;         # 7 dias
min-lease-time 3600;           # 1 hora (mínimo)

# Autoritative para esta subnet
authoritative;

# Logging
log-facility local7;

# Opções de segurança
deny declines;
deny bootp;

#------------------------------------------------------------
# Subnet LAN - 192.168.1.0/24
#------------------------------------------------------------

subnet 192.168.1.0 netmask 255.255.255.0 {
    # Range de IPs dinâmicos
    range 192.168.1.100 192.168.1.200;
    
    # Gateway padrão
    option routers 192.168.1.1;
    
    # Servidores DNS
    option domain-name-servers 192.168.1.10, 192.168.1.1;
    
    # Domínio de pesquisa
    option domain-name "fsociety.pt";
    option domain-search "fsociety.pt";
    
    # Broadcast
    option broadcast-address 192.168.1.255;
    
    # Máscara de rede
    option subnet-mask 255.255.255.0;
    
    # Servidor NTP
    option ntp-servers 192.168.1.10;
    
    # Servidor WINS/NetBIOS (Samba)
    option netbios-name-servers 192.168.1.10;
    option netbios-node-type 8;  # Hybrid node
    
    # Lease times
    default-lease-time 86400;
    max-lease-time 604800;
}

#------------------------------------------------------------
# Reservas de IP (Hosts Fixos)
#------------------------------------------------------------

# Grupo: Servidores
group {
    # Domain Controller
    host dc {
        hardware ethernet AA:BB:CC:DD:EE:01;
        fixed-address 192.168.1.10;
        option host-name "dc";
    }
    
    # Nextcloud / Files Server
    host files {
        hardware ethernet AA:BB:CC:DD:EE:02;
        fixed-address 192.168.1.40;
        option host-name "files";
    }
    
    # Backup Server
    host backup {
        hardware ethernet AA:BB:CC:DD:EE:03;
        fixed-address 192.168.1.50;
        option host-name "backup";
    }
}

# Grupo: Workstations (Exemplo)
group {
    # Estação de trabalho TI
    host ws-ti-001 {
        hardware ethernet AA:BB:CC:DD:EE:10;
        fixed-address 192.168.1.30;
        option host-name "ws-ti-001";
    }
}
```

### Parâmetros Explicados

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `default-lease-time` | 86400 | Tempo padrão de lease (24h) |
| `max-lease-time` | 604800 | Tempo máximo de lease (7 dias) |
| `authoritative` | - | Servidor DHCP autoritativo para a rede |
| `deny declines` | - | Rejeitar pedidos de decline |
| `deny bootp` | - | Não responder a pedidos BOOTP |

---

## 📌 Reservas de IP

### Plano de Endereçamento

| Range | Utilização |
|-------|------------|
| 192.168.1.1 - 192.168.1.9 | Infraestrutura de rede |
| 192.168.1.10 - 192.168.1.29 | Servidores |
| 192.168.1.30 - 192.168.1.49 | Estações de trabalho fixas |
| 192.168.1.50 - 192.168.1.99 | Reservado |
| 192.168.1.100 - 192.168.1.200 | DHCP Pool |
| 192.168.1.201 - 192.168.1.254 | Reservado |

### Reservas Atuais

| Hostname | IP | MAC | Descrição |
|----------|----|----|-----------|
| pfSense | 192.168.1.1 | - | Gateway/Firewall |
| dc | 192.168.1.10 | AA:BB:CC:DD:EE:01 | Domain Controller |
| files | 192.168.1.40 | AA:BB:CC:DD:EE:02 | Nextcloud |
| backup | 192.168.1.50 | AA:BB:CC:DD:EE:03 | Proxmox Backup |

### Adicionar Nova Reserva

```bash
# Editar configuração
sudo nano /etc/dhcp/dhcpd.conf

# Adicionar dentro do grupo apropriado:
host novo-servidor {
    hardware ethernet XX:XX:XX:XX:XX:XX;
    fixed-address 192.168.1.XX;
    option host-name "novo-servidor";
}

# Reiniciar serviço
sudo systemctl restart isc-dhcp-server
```

---

## 🔗 Integração com DNS

### Dynamic DNS Updates (DDNS)

Para integração com o DNS do Samba AD, adicionar ao `dhcpd.conf`:

```bash
#------------------------------------------------------------
# Dynamic DNS Updates
#------------------------------------------------------------

# Método de atualização
ddns-updates on;
ddns-update-style interim;
update-static-leases on;

# Chave TSIG para atualizações (gerar com dnssec-keygen)
key "DHCP_UPDATER" {
    algorithm hmac-md5;
    secret "CHAVE_SECRETA_BASE64";
};

# Zona forward
zone fsociety.pt. {
    primary 192.168.1.10;
    key DHCP_UPDATER;
}

# Zona reverse
zone 1.168.192.in-addr.arpa. {
    primary 192.168.1.10;
    key DHCP_UPDATER;
}
```

### Gerar Chave TSIG

```bash
# Gerar chave
dnssec-keygen -a HMAC-MD5 -b 128 -n HOST DHCP_UPDATER

# Ver chave gerada
cat Kdhcp_updater.+157+xxxxx.key
```

> **Nota:** A integração DDNS com Samba AD pode requerer configuração adicional do lado do Samba.

---

## 📊 Logs e Monitorização

### Configurar Logging

```bash
# Editar rsyslog para DHCP
sudo nano /etc/rsyslog.d/50-isc-dhcp-server.conf
```

**Conteúdo:**

```bash
# Log do DHCP Server
local7.* /var/log/dhcpd.log
```

```bash
# Reiniciar rsyslog
sudo systemctl restart rsyslog
```

### Ver Logs

```bash
# Logs em tempo real
sudo tail -f /var/log/dhcpd.log

# Ou via journalctl
sudo journalctl -u isc-dhcp-server -f
```

### Ver Leases Ativos

```bash
# Ficheiro de leases
sudo cat /var/lib/dhcp/dhcpd.leases

# Filtrar leases ativos
sudo dhcp-lease-list --lease /var/lib/dhcp/dhcpd.leases
```

### Formato do Lease

```
lease 192.168.1.105 {
  starts 1 2024/12/02 10:30:00;
  ends 2 2024/12/03 10:30:00;
  cltt 1 2024/12/02 10:30:00;
  binding state active;
  next binding state free;
  hardware ethernet aa:bb:cc:dd:ee:ff;
  client-hostname "workstation1";
}
```

---

## ✅ Verificação e Testes

### Verificar Sintaxe

```bash
# Verificar configuração
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

### Iniciar Serviço

```bash
# Iniciar DHCP
sudo systemctl start isc-dhcp-server

# Ativar no boot
sudo systemctl enable isc-dhcp-server

# Verificar estado
sudo systemctl status isc-dhcp-server
```

### Testar DHCP

```bash
# Numa máquina cliente:
# 1. Libertar IP atual
sudo dhclient -r ens18

# 2. Solicitar novo IP
sudo dhclient ens18

# 3. Verificar IP obtido
ip addr show ens18
```

### Verificar Portas

```bash
# DHCP escuta nas portas 67 (servidor) e 68 (cliente)
sudo ss -ulnp | grep dhcpd

# Esperado:
# udp  UNCONN  0  0  *:67  *:*  users:(("dhcpd",pid=xxxx,fd=x))
```

### Script de Diagnóstico

```bash
#!/bin/bash
# Diagnóstico DHCP

echo "=== ISC DHCP Server Status ==="
systemctl status isc-dhcp-server --no-pager

echo -e "\n=== Listening Ports ==="
ss -ulnp | grep dhcp

echo -e "\n=== Active Leases ==="
cat /var/lib/dhcp/dhcpd.leases | grep -A 5 "binding state active"

echo -e "\n=== Recent Logs ==="
journalctl -u isc-dhcp-server --since "1 hour ago" --no-pager | tail -20
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Serviço não inicia | Erro de sintaxe | `dhcpd -t -cf /etc/dhcp/dhcpd.conf` |
| Clientes não recebem IP | Interface incorreta | Verificar `/etc/default/isc-dhcp-server` |
| IP duplicado | Lease stale | Limpar `/var/lib/dhcp/dhcpd.leases` |
| DNS errado | Configuração | Verificar `option domain-name-servers` |

### Limpar Leases

```bash
# Parar serviço
sudo systemctl stop isc-dhcp-server

# Limpar ficheiro de leases
sudo rm /var/lib/dhcp/dhcpd.leases
sudo touch /var/lib/dhcp/dhcpd.leases

# Iniciar serviço
sudo systemctl start isc-dhcp-server
```

### Debug Mode

```bash
# Executar em modo debug
sudo dhcpd -d -f -cf /etc/dhcp/dhcpd.conf ens18
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| ISC DHCP Documentation | https://kb.isc.org/docs/aa-00333 |
| dhcpd.conf Manual | https://linux.die.net/man/5/dhcpd.conf |
| Ubuntu DHCP Server | https://ubuntu.com/server/docs/network-dhcp |

### RFCs

| RFC | Descrição |
|-----|-----------|
| RFC 2131 | Dynamic Host Configuration Protocol |
| RFC 2132 | DHCP Options and BOOTP Vendor Extensions |
| RFC 4702 | DNS Dynamic Updates |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 🔗 Navegação

| Anterior | Índice | Próximo |
|----------|--------|---------|
| [← DNS Integrado](03-dns-integrado.md) | [📚 Índice](README.md) | [Kerberos →](05-kerberos.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-dhcp-server---isc-dhcp)**

---

*Última atualização: Dezembro 2025*

</div>
