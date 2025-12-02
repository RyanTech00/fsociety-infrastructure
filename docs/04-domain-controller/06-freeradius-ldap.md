# 📡 FreeRADIUS com Integração LDAP

> **Configuração do FreeRADIUS 3.2.5 integrado com Samba AD para autenticação VPN**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Instalação](#-instalação)
3. [Configuração do Módulo LDAP](#-configuração-do-módulo-ldap)
4. [Mapeamento de Grupos AD](#-mapeamento-de-grupos-ad)
5. [IP Pools por Departamento](#-ip-pools-por-departamento)
6. [Configuração de Sites](#-configuração-de-sites)
7. [Clientes RADIUS](#-clientes-radius)
8. [Verificação e Testes](#-verificação-e-testes)
9. [Referências](#-referências)

---

## 📖 Visão Geral

### O que é o FreeRADIUS?

O FreeRADIUS é a implementação RADIUS (Remote Authentication Dial-In User Service) mais utilizada no mundo. Suporta múltiplos backends de autenticação, incluindo LDAP, e é ideal para:

- **Autenticação VPN** - OpenVPN, WireGuard, IPsec
- **Autenticação WiFi** - WPA2/WPA3 Enterprise
- **Contabilidade** - Registo de sessões e utilização
- **Autorização** - Controlo de acesso baseado em grupos

### Informação do Serviço

| Parâmetro | Valor |
|-----------|-------|
| **Versão** | FreeRADIUS 3.2.5 |
| **Porta Auth** | 1812/UDP |
| **Porta Acct** | 1813/UDP |
| **Backend** | LDAP (Samba AD) |
| **LDAP Server** | 192.168.1.10:389 |

### Arquitetura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    pfSense      │     │   FreeRADIUS    │     │    Samba AD     │
│   (OpenVPN)     │────►│   192.168.1.10  │────►│   192.168.1.10  │
│   192.168.1.1   │     │   :1812/:1813   │     │   :389 LDAP     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
  VPN Clients          Auth + Accounting           User DB
  (10.8.0.x)           Group Mapping              Groups
```

---

## 📦 Instalação

### Instalar FreeRADIUS

```bash
# Instalar FreeRADIUS e módulo LDAP
sudo apt install -y freeradius freeradius-ldap freeradius-utils

# Verificar versão
freeradius -v
```

### Verificar Instalação

```bash
# Listar módulos disponíveis
ls /etc/freeradius/3.0/mods-available/

# Verificar módulo LDAP
ls -la /etc/freeradius/3.0/mods-available/ldap
```

---

## ⚙️ Configuração do Módulo LDAP

### Ativar Módulo LDAP

```bash
# Criar link simbólico
cd /etc/freeradius/3.0/mods-enabled/
sudo ln -s ../mods-available/ldap ldap
```

### Configurar Módulo LDAP

**Ficheiro:** `/etc/freeradius/3.0/mods-available/ldap`

```bash
sudo nano /etc/freeradius/3.0/mods-available/ldap
```

**Conteúdo:**

```apache
# FreeRADIUS LDAP Module Configuration
# Backend: Samba AD DC (fsociety.pt)

ldap {
    # Servidor LDAP
    server = "192.168.1.10"
    port = 389
    
    # Identidade para bind
    identity = "CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt"
    password = "SvcLdap@2024!"
    
    # Base DN para pesquisas
    base_dn = "DC=fsociety,DC=pt"
    
    # Configurações de conexão
    sasl {
    }
    
    # Mapeamento de atributos LDAP -> RADIUS
    update {
        control:Password-With-Header    += 'userPassword'
        control:NT-Password             := 'unicodePwd'
        reply:Reply-Message             := 'description'
        control:                        += 'radiusControlAttribute'
        request:                        += 'radiusRequestAttribute'
        reply:                          += 'radiusReplyAttribute'
    }
    
    # Secção de utilizadores
    user {
        base_dn = "${..base_dn}"
        filter = "(sAMAccountName=%{%{Stripped-User-Name}:-%{User-Name}})"
        
        sasl {
        }
        
        # Atributos do utilizador
        scope = 'sub'
    }
    
    # Secção de grupos
    group {
        base_dn = "${..base_dn}"
        filter = "(objectClass=group)"
        scope = 'sub'
        name_attribute = cn
        membership_filter = "(|(member=%{control:Ldap-UserDn})(memberUid=%{%{Stripped-User-Name}:-%{User-Name}}))"
        membership_attribute = 'memberOf'
    }
    
    # Perfis LDAP
    profile {
    }
    
    # Cliente LDAP
    client {
        base_dn = "${..base_dn}"
        filter = '(objectClass=radiusClient)'
    }
    
    # Accounting LDAP (opcional)
    accounting {
        reference = "%{tolower:type.%{Acct-Status-Type}}"
    }
    
    # Opções de conexão
    options {
        chase_referrals = yes
        rebind = yes
        res_timeout = 10
        srv_timelimit = 3
        net_timeout = 1
        idle = 60
        probes = 3
        interval = 3
        ldap_debug = 0x0028
    }
    
    # Pool de conexões
    pool {
        start = ${thread[pool].start_servers}
        min = ${thread[pool].min_spare_servers}
        max = ${thread[pool].max_servers}
        spare = ${thread[pool].max_spare_servers}
        uses = 0
        retry_delay = 30
        lifetime = 0
        idle_timeout = 60
    }
}
```

---

## 👥 Mapeamento de Grupos AD

### Estrutura de Grupos no AD

| Grupo AD | Descrição | Pool VPN |
|----------|-----------|----------|
| GRP_TI | Departamento TI | ti_pool |
| GRP_Gestores | Gestores | gestores_pool |
| GRP_Financeiro | Departamento Financeiro | financeiro_pool |
| GRP_Comercial | Departamento Comercial | comercial_pool |
| GRP_RH | Recursos Humanos | vpn_users_pool |
| GRP_VPN_Users | Utilizadores VPN gerais | vpn_users_pool |

### Configurar Mapeamento

**Ficheiro:** `/etc/freeradius/3.0/policy.d/group-mapping`

```bash
sudo nano /etc/freeradius/3.0/policy.d/group-mapping
```

**Conteúdo:**

```apache
# Group to IP Pool Mapping Policy
# Maps AD security groups to VPN IP pools

policy group_ip_pool_mapping {
    # GRP_TI -> ti_pool (10.8.0.10-59)
    if (LDAP-Group == "CN=GRP_TI,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "ti_pool"
        }
        update control {
            Simultaneous-Use := 2
        }
    }
    
    # GRP_Gestores -> gestores_pool (10.8.0.60-109)
    elsif (LDAP-Group == "CN=GRP_Gestores,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "gestores_pool"
        }
        update control {
            Simultaneous-Use := 2
        }
    }
    
    # GRP_Financeiro -> financeiro_pool (10.8.0.110-159)
    elsif (LDAP-Group == "CN=GRP_Financeiro,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "financeiro_pool"
        }
        update control {
            Simultaneous-Use := 1
        }
    }
    
    # GRP_Comercial -> comercial_pool (10.8.0.160-209)
    elsif (LDAP-Group == "CN=GRP_Comercial,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "comercial_pool"
        }
        update control {
            Simultaneous-Use := 1
        }
    }
    
    # GRP_RH ou GRP_VPN_Users -> vpn_users_pool (10.8.0.210-254)
    elsif (LDAP-Group == "CN=GRP_RH,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "vpn_users_pool"
        }
        update control {
            Simultaneous-Use := 1
        }
    }
    elsif (LDAP-Group == "CN=GRP_VPN_Users,OU=Grupos,OU=FSociety,DC=fsociety,DC=pt") {
        update reply {
            Framed-Pool := "vpn_users_pool"
        }
        update control {
            Simultaneous-Use := 1
        }
    }
    
    # Default - Rejeitar utilizadores sem grupo válido
    else {
        reject
    }
}
```

---

## 🌐 IP Pools por Departamento

### Tabela de IP Pools

| Pool Name | Range | Quantidade | Departamento |
|-----------|-------|------------|--------------|
| ti_pool | 10.8.0.10 - 10.8.0.59 | 50 IPs | TI |
| gestores_pool | 10.8.0.60 - 10.8.0.109 | 50 IPs | Gestores |
| financeiro_pool | 10.8.0.110 - 10.8.0.159 | 50 IPs | Financeiro |
| comercial_pool | 10.8.0.160 - 10.8.0.209 | 50 IPs | Comercial |
| vpn_users_pool | 10.8.0.210 - 10.8.0.254 | 45 IPs | RH / VPN Users |

### Diagrama de Pools

```
VPN Network: 10.8.0.0/24
│
├── 10.8.0.1      = VPN Gateway (pfSense)
├── 10.8.0.2-9    = Reservado
│
├── ti_pool (10.8.0.10-59)
│   └── 50 IPs para GRP_TI
│
├── gestores_pool (10.8.0.60-109)
│   └── 50 IPs para GRP_Gestores
│
├── financeiro_pool (10.8.0.110-159)
│   └── 50 IPs para GRP_Financeiro
│
├── comercial_pool (10.8.0.160-209)
│   └── 50 IPs para GRP_Comercial
│
└── vpn_users_pool (10.8.0.210-254)
    └── 45 IPs para GRP_RH + GRP_VPN_Users
```

### Configurar IP Pools (pfSense)

> **Nota:** Os IP pools são configurados no pfSense (servidor OpenVPN) e o FreeRADIUS apenas retorna o nome do pool no atributo `Framed-Pool`.

---

## 🌐 Configuração de Sites

### Site Default

**Ficheiro:** `/etc/freeradius/3.0/sites-available/default`

```bash
sudo nano /etc/freeradius/3.0/sites-available/default
```

**Secções relevantes a modificar:**

```apache
server default {
    listen {
        type = auth
        ipaddr = *
        port = 0
        limit {
            max_connections = 16
            lifetime = 0
            idle_timeout = 30
        }
    }
    
    listen {
        ipaddr = *
        port = 0
        type = acct
        limit {
        }
    }
    
    authorize {
        # Filtrar utilizadores
        filter_username
        
        # Verificar preprocess
        preprocess
        
        # CHAP
        chap
        
        # MS-CHAP
        mschap
        
        # Sufixo/Realm
        suffix
        
        # Verificar EAP
        eap {
            ok = return
        }
        
        # Ficheiros locais (users)
        files
        
        # LDAP - Autenticação AD
        -ldap
        
        # Expiração
        expiration
        logintime
        
        # PAP se necessário
        pap
    }
    
    authenticate {
        # Métodos de autenticação
        Auth-Type PAP {
            pap
        }
        
        Auth-Type CHAP {
            chap
        }
        
        Auth-Type MS-CHAP {
            mschap
        }
        
        # LDAP Auth
        Auth-Type LDAP {
            ldap
        }
        
        # EAP
        eap
    }
    
    preacct {
        preprocess
        acct_unique
        suffix
    }
    
    accounting {
        detail
        unix
        -sql
        exec
        attr_filter.accounting_response
    }
    
    session {
    }
    
    post-auth {
        # Mapeamento de grupos para pools
        group_ip_pool_mapping
        
        # Log
        -sql
        exec
        
        # Resposta EAP
        Post-Auth-Type REJECT {
            -sql
            attr_filter.access_reject
            eap
            remove_reply_message_if_eap
        }
    }
    
    pre-proxy {
    }
    
    post-proxy {
        eap
    }
}
```

### Ativar Site Inner-Tunnel (EAP)

**Ficheiro:** `/etc/freeradius/3.0/sites-available/inner-tunnel`

Modificar secção `authorize`:

```apache
authorize {
    filter_username
    chap
    mschap
    suffix
    update control {
        &Proxy-To-Realm := LOCAL
    }
    eap {
        ok = return
    }
    files
    -ldap
    expiration
    logintime
    pap
}
```

---

## 🔌 Clientes RADIUS

### Configurar Cliente pfSense

**Ficheiro:** `/etc/freeradius/3.0/clients.conf`

```bash
sudo nano /etc/freeradius/3.0/clients.conf
```

**Adicionar no final:**

```apache
# pfSense - OpenVPN Server
client pfsense {
    ipaddr = 192.168.1.1
    secret = RadiusSecret2024!
    shortname = pfsense
    nastype = other
    
    # Limites
    limit {
        max_connections = 16
        lifetime = 0
        idle_timeout = 30
    }
}

# Localhost para testes
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    shortname = localhost
}
```

### Tabela de Clientes

| Cliente | IP | Secret | Descrição |
|---------|----|---------| ----------|
| pfsense | 192.168.1.1 | RadiusSecret2024! | OpenVPN Server |
| localhost | 127.0.0.1 | testing123 | Testes locais |

---

## ✅ Verificação e Testes

### Verificar Sintaxe

```bash
# Verificar configuração
sudo freeradius -CX
```

### Iniciar em Modo Debug

```bash
# Parar serviço
sudo systemctl stop freeradius

# Iniciar em modo debug
sudo freeradius -X
```

### Testar Autenticação LDAP

```bash
# Testar bind LDAP
ldapwhoami -H ldap://192.168.1.10 \
    -D "CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt" \
    -W

# Pesquisar utilizador
ldapsearch -H ldap://192.168.1.10 \
    -D "CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt" \
    -W \
    -b "DC=fsociety,DC=pt" \
    "(sAMAccountName=testuser)" \
    memberOf
```

### Testar Autenticação RADIUS

```bash
# Teste com radtest
radtest testuser 'Password123!' localhost 0 testing123

# Teste com utilizador real do AD
radtest ryan.barbosa 'Password123!' localhost 0 testing123
```

### Saída Esperada (Sucesso)

```
Sent Access-Request Id 123 from 0.0.0.0:xxxxx to 127.0.0.1:1812 length 77
    User-Name = "testuser"
    User-Password = "Password123!"
    NAS-IP-Address = 127.0.0.1
    NAS-Port = 0
    Message-Authenticator = 0x00
Received Access-Accept Id 123 from 127.0.0.1:1812 to 0.0.0.0:0 length 45
    Framed-Pool = "ti_pool"
    Reply-Message = "Welcome to FSociety VPN"
```

### Iniciar Serviço

```bash
# Iniciar FreeRADIUS
sudo systemctl start freeradius

# Ativar no boot
sudo systemctl enable freeradius

# Verificar estado
sudo systemctl status freeradius
```

### Verificar Portas

```bash
# Verificar portas RADIUS
sudo ss -ulnp | grep radius

# Esperado:
# udp  UNCONN  0  0  *:1812  *:*  users:(("freeradius",...))
# udp  UNCONN  0  0  *:1813  *:*  users:(("freeradius",...))
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| LDAP bind failed | Credenciais erradas | Verificar svc_ldap password |
| User not found | Filtro LDAP errado | Verificar base_dn e filter |
| Group mapping falha | DN do grupo errado | Verificar DN completo |
| Timeout | Conectividade | Verificar firewall |

### Logs

```bash
# Logs do FreeRADIUS
sudo tail -f /var/log/freeradius/radius.log

# Logs de debug (se ativado)
sudo tail -f /var/log/freeradius/debug.log
```

### Debug de Módulo LDAP

```bash
# No ficheiro ldap, aumentar debug
ldap_debug = 0x0028

# Reiniciar em modo debug
sudo freeradius -X
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| FreeRADIUS Documentation | https://freeradius.org/documentation/ |
| FreeRADIUS LDAP Module | https://wiki.freeradius.org/modules/rlm_ldap |
| FreeRADIUS Configuration | https://freeradius.org/radiusd/man/radiusd.conf.txt |

### RFCs

| RFC | Descrição |
|-----|-----------|
| RFC 2865 | RADIUS |
| RFC 2866 | RADIUS Accounting |
| RFC 5176 | Dynamic Authorization Extensions to RADIUS |

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
| [← Kerberos](05-kerberos.md) | [📚 Índice](README.md) | [CrowdSec →](07-crowdsec.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-freeradius-com-integração-ldap)**

---

*Última atualização: Dezembro 2024*

</div>
