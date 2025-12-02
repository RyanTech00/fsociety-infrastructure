# 🔐 Integração RADIUS

> Documentação completa da integração RADIUS entre pfSense e Domain Controller para autenticação OpenVPN com Active Directory.

---

## 📋 Arquitetura

### Fluxo de Autenticação

```
┌─────────────────┐
│  Cliente VPN    │  1. Conecta com username@fsociety.pt + password
│  (OpenVPN)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    pfSense      │  2. Recebe credenciais
│  OpenVPN Server │  3. Envia RADIUS Access-Request
│  192.168.1.1    │
└────────┬────────┘
         │ RADIUS (UDP 1812/1813)
         ▼
┌─────────────────┐
│  FreeRADIUS     │  4. Valida contra LDAP/AD
│  Domain         │  5. Identifica grupo AD do utilizador
│  Controller     │  6. Retorna Framed-IP-Address do pool
│  192.168.1.10   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Samba AD DC    │  7. Verifica credenciais LDAP
│  LDAP/Kerberos  │  8. Retorna grupos e atributos
│  dc.fsociety.pt │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│    pfSense      │  9. Atribui IP do pool ao cliente
│  Firewall Rules │  10. Aplica regras baseadas em alias/IP
└─────────────────┘
```

---

## 🔧 Configuração no pfSense

### 1. Adicionar Servidor RADIUS

```
System → User Manager → Authentication Servers → Add
```

| Parâmetro | Valor |
|-----------|-------|
| **Descriptive name** | RADIUS-DC-FSociety |
| **Type** | RADIUS |
| **Protocol** | PAP (Password Authentication Protocol) |
| **Hostname or IP address** | 192.168.1.10 |
| **Shared Secret** | (senha forte configurada no FreeRADIUS) |
| **Services offered** | Authentication and Accounting |
| **Authentication port** | 1812 |
| **Accounting port** | 1813 |
| **Authentication Timeout** | 5 seconds |

#### Shared Secret

**Importante**: O shared secret deve ser o mesmo configurado no FreeRADIUS.

```
Exemplo:
Shared Secret: Str0ng!R4d1u5$ecret#2024

Guardar em local seguro (password manager)
```

### 2. Testar Autenticação RADIUS

```
Diagnostics → Authentication
```

| Campo | Valor |
|-------|-------|
| **Authentication Server** | RADIUS-DC-FSociety |
| **Username** | ryan@fsociety.pt |
| **Password** | (password AD do utilizador) |

Clicar em **Test**

**Resultado esperado**:
```
✅ User authenticated successfully

RADIUS attributes returned:
- Framed-IP-Address: 10.8.0.15
- Reply-Message: Authentication successful
```

### 3. Configurar OpenVPN para usar RADIUS

```
VPN → OpenVPN → Servers → Edit (Server RADIUS)
```

| Parâmetro | Valor |
|-----------|-------|
| **Backend for authentication** | RADIUS-DC-FSociety |
| **Enforce local group** | ❌ (grupos vêm do RADIUS) |

Mais detalhes: [OpenVPN Configuration](06-openvpn.md)

---

## 🖥️ Configuração no Domain Controller

### 1. Instalar FreeRADIUS

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar FreeRADIUS
sudo apt install freeradius freeradius-ldap freeradius-utils -y

# Verificar instalação
freeradius -v
```

### 2. Configurar Cliente RADIUS (pfSense)

```bash
# Editar ficheiro de clientes
sudo nano /etc/freeradius/3.0/clients.conf
```

**Adicionar**:
```
client pfsense {
    ipaddr = 192.168.1.1
    secret = Str0ng!R4d1u5$ecret#2024
    shortname = pfSense
    nastype = other
    
    # Optional: limit to specific NAS ports
    # port = 1812,1813
    
    # Optional: require message authenticator
    require_message_authenticator = no
    
    # Optional: limit connection requests
    limit {
        max_connections = 100
        lifetime = 0
        idle_timeout = 30
    }
}
```

### 3. Configurar Módulo LDAP

```bash
# Criar link simbólico para ativar módulo LDAP
sudo ln -s /etc/freeradius/3.0/mods-available/ldap /etc/freeradius/3.0/mods-enabled/

# Editar configuração LDAP
sudo nano /etc/freeradius/3.0/mods-enabled/ldap
```

**Configuração**:
```
ldap {
    server = 'localhost'
    port = 389
    
    identity = 'cn=Administrator,cn=Users,dc=fsociety,dc=pt'
    password = (password do Administrator AD)
    
    base_dn = 'dc=fsociety,dc=pt'
    
    sasl {
    }
    
    update {
        control:Password-With-Header    += 'userPassword'
        control:NT-Password             := 'sambaNTPassword'
        reply:Reply-Message             := 'radiusReplyMessage'
        reply:Tunnel-Type               := 'radiusTunnelType'
        reply:Tunnel-Medium-Type        := 'radiusTunnelMediumType'
        reply:Tunnel-Private-Group-ID   := 'radiusTunnelPrivategroupId'
    }
    
    # Filtros de pesquisa
    user {
        base_dn = "${..base_dn}"
        filter = "(sAMAccountName=%{%{Stripped-User-Name}:-%{User-Name}})"
        
        # Atributos LDAP necessários
        scope = 'sub'
    }
    
    group {
        base_dn = "${..base_dn}"
        filter = '(objectClass=group)'
        membership_attribute = 'memberOf'
        scope = 'sub'
    }
    
    # Perfil para mapeamento de grupos
    profile {
    }
    
    options {
        chase_referrals = yes
        rebind = yes
    }
    
    # Pool de conexões
    pool {
        start = 5
        min = 4
        max = 32
        spare = 3
        uses = 0
        lifetime = 0
        idle_timeout = 60
    }
}
```

### 4. Configurar IP Pools por Grupo AD

```bash
# Criar ficheiro de unlang para atribuir IPs
sudo nano /etc/freeradius/3.0/policy.d/ip_pools
```

**Conteúdo**:
```
# Política de atribuição de IP pools por grupo AD

# Pool TI (Admin - Level 1)
if (LDAP-Group == "GRP_TI") {
    update reply {
        Framed-IP-Address := "10.8.0.%{randstr:nnnn}"
    }
    # Garantir que está no range correto (10-59)
    if ("%{reply:Framed-IP-Address}" < "10.8.0.10" || "%{reply:Framed-IP-Address}" > "10.8.0.59") {
        update reply {
            Framed-IP-Address := "10.8.0.%{expr:(10 + %{randstr:nn} %% 50)}"
        }
    }
}
# Pool Gestores (Level 2)
elsif (LDAP-Group == "GRP_Gestores") {
    update reply {
        Framed-IP-Address := "10.8.0.%{expr:(60 + %{randstr:nn} %% 50)}"
    }
}
# Pool Financeiro (Level 3)
elsif (LDAP-Group == "GRP_Financeiro") {
    update reply {
        Framed-IP-Address := "10.8.0.%{expr:(110 + %{randstr:nn} %% 50)}"
    }
}
# Pool Comercial (Level 3)
elsif (LDAP-Group == "GRP_Comercial") {
    update reply {
        Framed-IP-Address := "10.8.0.%{expr:(160 + %{randstr:nn} %% 50)}"
    }
}
# Pool VPN_Users (Level 4)
elsif (LDAP-Group == "GRP_VPN_Users") {
    update reply {
        Framed-IP-Address := "10.8.0.%{expr:(210 + %{randstr:nn} %% 45)}"
    }
}
else {
    # Default: negar acesso
    reject
}
```

**Alternativa: IP Pools do FreeRADIUS**:
```bash
sudo nano /etc/freeradius/3.0/mods-config/sql/ippool/postgresql/ippool.conf
```

**IP Pools**:
```
# Pool TI
ippool ti_pool {
    range-start = 10.8.0.10
    range-stop = 10.8.0.59
    netmask = 255.255.255.0
    cache-size = 50
    session-timeout = 3600
    ip-index = "%{NAS-IP-Address} %{NAS-Port}"
    override = no
}

# Pool Gestores
ippool gestores_pool {
    range-start = 10.8.0.60
    range-stop = 10.8.0.109
    netmask = 255.255.255.0
    cache-size = 50
    session-timeout = 3600
}

# Pool Financeiro
ippool financeiro_pool {
    range-start = 10.8.0.110
    range-stop = 10.8.0.159
    netmask = 255.255.255.0
    cache-size = 50
    session-timeout = 3600
}

# Pool Comercial
ippool comercial_pool {
    range-start = 10.8.0.160
    range-stop = 10.8.0.209
    netmask = 255.255.255.0
    cache-size = 50
    session-timeout = 3600
}

# Pool VPN_Users
ippool vpn_users_pool {
    range-start = 10.8.0.210
    range-stop = 10.8.0.254
    netmask = 255.255.255.0
    cache-size = 45
    session-timeout = 3600
}
```

### 5. Configurar Site Default

```bash
sudo nano /etc/freeradius/3.0/sites-enabled/default
```

**Na seção `authorize`**:
```
authorize {
    # Filtrar nome de utilizador
    filter_username
    
    # Autenticação via PAP
    pap
    
    # Consultar LDAP
    -ldap
    
    # Se LDAP sucesso, atribuir pool
    if (ok) {
        # Chamar política de IP pools
        ip_pools
    }
    
    # Expiração de sessão
    expiration
    logintime
}
```

**Na seção `authenticate`**:
```
authenticate {
    Auth-Type PAP {
        pap
    }
    
    Auth-Type LDAP {
        ldap
    }
}
```

**Na seção `post-auth`**:
```
post-auth {
    # Log sucesso
    if (Framed-IP-Address) {
        update reply {
            Reply-Message := "Welcome %{User-Name}, IP: %{reply:Framed-IP-Address}"
        }
    }
    
    # Accounting
    exec
    
    Post-Auth-Type REJECT {
        attr_filter.access_reject
        
        # Log rejects
        linelog
    }
}
```

### 6. Ajustar Permissões

```bash
# Propriedade dos ficheiros
sudo chown -R freerad:freerad /etc/freeradius/3.0/

# Permissões de leitura
sudo chmod 640 /etc/freeradius/3.0/clients.conf
sudo chmod 640 /etc/freeradius/3.0/mods-enabled/ldap
```

### 7. Testar Configuração

```bash
# Verificar sintaxe
sudo freeradius -CX

# Iniciar em modo debug
sudo freeradius -X
```

**Saída esperada**:
```
Listening on auth address * port 1812 bound to server default
Listening on acct address * port 1813 bound to server default
Ready to process requests
```

### 8. Ativar e Iniciar Serviço

```bash
# Parar modo debug (Ctrl+C)

# Ativar serviço
sudo systemctl enable freeradius

# Iniciar serviço
sudo systemctl start freeradius

# Verificar status
sudo systemctl status freeradius
```

---

## 🧪 Testes de Autenticação

### 1. Teste Local (no DC)

```bash
# Testar com radtest
radtest ryan@fsociety.pt password123 localhost 1812 Str0ng!R4d1u5$ecret#2024
```

**Resultado esperado**:
```
Sent Access-Request Id 123 from 0.0.0.0:12345 to 127.0.0.1:1812 length 76
        User-Name = "ryan@fsociety.pt"
        User-Password = "password123"
        NAS-IP-Address = 127.0.0.1
        NAS-Port = 1812
        Message-Authenticator = 0x00
Received Access-Accept Id 123 from 127.0.0.1:1812 to 0.0.0.0:12345 length 48
        Framed-IP-Address = 10.8.0.15
        Reply-Message = "Welcome ryan@fsociety.pt, IP: 10.8.0.15"
```

### 2. Teste Remoto (do pfSense)

```bash
# SSH no pfSense
ssh admin@192.168.1.1

# Testar RADIUS
echo "User-Name = ryan@fsociety.pt, User-Password = password123" | \
radclient -x 192.168.1.10:1812 auth Str0ng!R4d1u5$ecret#2024
```

### 3. Teste via WebUI pfSense

```
Diagnostics → Authentication

Server: RADIUS-DC-FSociety
Username: ryan@fsociety.pt
Password: (password AD)

Test → Deve retornar sucesso
```

### 4. Teste OpenVPN Real

```
1. Conectar cliente OpenVPN
2. Usar credenciais AD
3. Verificar IP atribuído:
   Status → OpenVPN
4. Verificar conectividade baseada no grupo
```

---

## 📊 Mapeamento Grupos → IPs → Acessos

### Tabela Completa

| Grupo AD | Pool IP | Alias pfSense | Nível | Acessos |
|----------|---------|---------------|-------|---------|
| **GRP_TI** | 10.8.0.10-59 | Alias_VPN_TI | L1 - Admin | LAN + DMZ + Internet (Full) |
| **GRP_Gestores** | 10.8.0.60-109 | Alias_VPN_Gestores | L2 - Gestão | LAN + DMZ + Internet |
| **GRP_Financeiro** | 10.8.0.110-159 | Alias_VPN_Financeiro | L3 - Dept | DC (SMB/DNS) + Internet |
| **GRP_Comercial** | 10.8.0.160-209 | Alias_VPN_Comercial | L3 - Dept | DC (SMB/DNS) + Internet |
| **GRP_VPN_Users** | 10.8.0.210-254 | Alias_VPN_VPN_Users | L4 - Users | Mail + Nextcloud + Internet |

### Fluxo Completo

```
1. Utilizador "ryan" (membro de GRP_TI) conecta VPN
   ↓
2. pfSense envia RADIUS request para 192.168.1.10
   ↓
3. FreeRADIUS valida contra AD
   ↓
4. FreeRADIUS identifica: ryan ∈ GRP_TI
   ↓
5. FreeRADIUS atribui IP do ti_pool: 10.8.0.15
   ↓
6. pfSense recebe Framed-IP-Address: 10.8.0.15
   ↓
7. pfSense atribui 10.8.0.15 ao cliente
   ↓
8. pfSense aplica regras:
   Source: 10.8.0.15 (pertence a Alias_VPN_TI)
   Regras: [L1-Admin] - Full Access
   ↓
9. Cliente tem acesso total a LAN, DMZ, Internet
```

---

## 📋 Logs e Monitoring

### Logs FreeRADIUS (DC)

```bash
# Logs principais
sudo tail -f /var/log/freeradius/radius.log

# Logs de autenticação
sudo tail -f /var/log/syslog | grep radiusd

# Modo debug em tempo real
sudo freeradius -X
```

**Exemplo de log sucesso**:
```
(0) Received Access-Request Id 45 from 192.168.1.1:54321 to 192.168.1.10:1812
(0)   User-Name = "ryan@fsociety.pt"
(0)   User-Password = "***"
(0) # Executing section authorize from file /etc/freeradius/3.0/sites-enabled/default
(0)   ldap: EXPAND (sAMAccountName=%{User-Name})
(0)   ldap: Performing search in "dc=fsociety,dc=pt"
(0)   ldap: User found: cn=Ryan Barbosa,ou=TI,ou=FSociety,dc=fsociety,dc=pt
(0)   ldap: Group membership: GRP_TI
(0)   ip_pools: Assigning IP from ti_pool
(0)   update reply {
(0)     Framed-IP-Address := 10.8.0.15
(0)   }
(0) Sent Access-Accept Id 45
(0)   Framed-IP-Address = 10.8.0.15
```

### Logs pfSense

```
Status → System Logs → System

Filtrar: radius

Dec 02 14:30:15 pfsense radiusd[12345]: Received Access-Accept from RADIUS server 192.168.1.10
Dec 02 14:30:15 pfsense radiusd[12345]: User ryan@fsociety.pt authenticated successfully
```

### Logs OpenVPN

```
Status → System Logs → OpenVPN

Dec 02 14:30:16 pfsense openvpn[23456]: ryan@fsociety.pt/203.0.113.100:45678 MULTI: primary virtual IP for ryan@fsociety.pt: 10.8.0.15
```

---

## 🔒 Segurança

### Shared Secret

**Boas Práticas**:
- Mínimo 20 caracteres
- Mistura de maiúsculas, minúsculas, números, símbolos
- Único para cada cliente RADIUS
- Guardar em password manager

```
Exemplo:
Str0ng!R4d1u5$ecret#2024FSociety!@#
```

### Rate Limiting

```bash
# No FreeRADIUS
sudo nano /etc/freeradius/3.0/radiusd.conf
```

```
security {
    max_attributes = 200
    reject_delay = 1
    status_server = yes
}

# Limitar conexões por cliente
client pfsense {
    ...
    limit {
        max_connections = 100
        lifetime = 0
        idle_timeout = 30
    }
}
```

### Fail2Ban para RADIUS

```bash
# Instalar Fail2Ban
sudo apt install fail2ban -y

# Criar jail para FreeRADIUS
sudo nano /etc/fail2ban/jail.d/freeradius.conf
```

```
[freeradius]
enabled = true
port = 1812,1813
protocol = udp
filter = freeradius
logpath = /var/log/freeradius/radius.log
maxretry = 5
findtime = 600
bantime = 3600
action = iptables-allports[name=freeradius, protocol=all]
```

```bash
# Criar filtro
sudo nano /etc/fail2ban/filter.d/freeradius.conf
```

```
[Definition]
failregex = Login incorrect.*\[<HOST>\]
            Invalid user.*from <HOST>
            Failed password.*from <HOST>
ignoreregex =
```

```bash
# Restart Fail2Ban
sudo systemctl restart fail2ban

# Ver status
sudo fail2ban-client status freeradius
```

---

## 🐛 Troubleshooting

### RADIUS não responde

**Sintoma**: pfSense timeout ao autenticar

**Diagnóstico**:
```bash
# No DC - verificar serviço
sudo systemctl status freeradius

# Ver portas abertas
sudo netstat -tulpn | grep 1812

# Testar localmente
radtest test test localhost 1812 testing123
```

**Solução**:
- Verificar firewall DC permite 1812/1813 UDP
- Verificar serviço ativo
- Verificar binding address

### Autenticação LDAP falha

**Sintoma**: Access-Reject com erro LDAP

**Diagnóstico**:
```bash
# Debug FreeRADIUS
sudo freeradius -X

# Ver conexão LDAP
sudo ldapsearch -x -H ldap://localhost \
  -D "cn=Administrator,cn=Users,dc=fsociety,dc=pt" \
  -W -b "dc=fsociety,dc=pt" "(sAMAccountName=ryan)"
```

**Solução**:
- Verificar bind DN e password
- Verificar filtro LDAP
- Verificar base DN

### IP Pool não atribui

**Sintoma**: Cliente recebe IP fora do pool esperado

**Diagnóstico**:
```bash
# Debug com freeradius -X
# Procurar linhas:
# "ip_pools: Assigning IP from [pool_name]"
# "update reply { Framed-IP-Address := X.X.X.X }"

# Verificar grupos do utilizador
ldapsearch -x -LLL -b "dc=fsociety,dc=pt" \
  "(sAMAccountName=ryan)" memberOf
```

**Solução**:
- Verificar utilizador pertence ao grupo correto
- Verificar política ip_pools correta
- Verificar sintaxe unlang

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

- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [FreeRADIUS + LDAP](https://wiki.freeradius.org/config/LDAP-Directory)
- [pfSense RADIUS Authentication](https://docs.netgate.com/pfsense/en/latest/usermanager/radius.html)
- [RADIUS Protocol (RFC 2865)](https://www.rfc-editor.org/rfc/rfc2865)

---

<div align="center">

**[⬅️ Voltar: OpenVPN](06-openvpn.md)** | **[Índice](README.md)** | **[Próximo: Packages e Serviços ➡️](08-packages-servicos.md)**

</div>

---

*Última atualização: Dezembro 2024*
