# 🔐 Samba AD DC - Active Directory Domain Controller

> **Provisão e configuração do Samba como Active Directory Domain Controller**

---

## 📹 Demonstração

O vídeo abaixo demonstra a estrutura completa do Active Directory, incluindo OUs, utilizadores, grupos de segurança e membros de cada grupo:

https://github.com/user-attachments/assets/b84911b0-c776-4a00-a71c-5603aaac79ac

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Pré-requisitos](#-pré-requisitos)
3. [Provisão do Domínio](#-provisão-do-domínio)
4. [Configuração smb.conf](#-configuração-smbconf)
5. [Configuração TLS/SSL](#-configuração-tlsssl)
6. [Estrutura de OUs](#-estrutura-de-ous)
7. [Grupos de Segurança](#-grupos-de-segurança)
8. [Service Accounts](#-service-accounts)
9. [Verificação e Testes](#-verificação-e-testes)
10. [Referências](#-referências)

---

## 📖 Visão Geral

### O que é o Samba AD DC?

O Samba AD DC (Active Directory Domain Controller) é uma implementação open-source do protocolo Active Directory da Microsoft. Permite criar um ambiente de diretório centralizado compatível com clientes Windows, oferecendo:

- **LDAP** - Serviço de diretório para armazenamento de objetos
- **Kerberos** - Autenticação segura baseada em tickets
- **DNS** - Resolução de nomes integrada com AD
- **GPO** - Group Policy Objects para gestão centralizada

### Informação do Domínio

| Parâmetro | Valor |
|-----------|-------|
| **Realm Kerberos** | FSOCIETY.PT |
| **NetBIOS Domain** | FSOCIETY |
| **Domain Level** | Windows 2008 R2 |
| **Forest Level** | Windows 2008 R2 |
| **DNS Backend** | SAMBA_INTERNAL |

---

## 📋 Pré-requisitos

### Verificar Hostname e DNS

```bash
# Verificar hostname
hostname -f
# Esperado: dc.fsociety.pt

# Verificar resolução
ping -c 1 dc.fsociety.pt
# Esperado: 192.168.1.10
```

### Parar Serviços Existentes

```bash
# Parar e desativar serviços que conflituam
sudo systemctl stop smbd nmbd winbind
sudo systemctl disable smbd nmbd winbind

# Remover configuração anterior (se existir)
sudo rm -f /etc/samba/smb.conf
```

### Limpar Base de Dados Anterior

```bash
# Backup e remoção de databases anteriores
sudo rm -rf /var/lib/samba/*
sudo rm -rf /var/cache/samba/*
sudo rm -rf /run/samba/*
```

---

## 🏗️ Provisão do Domínio

### Comando de Provisão

```bash
sudo samba-tool domain provision \
    --realm=FSOCIETY.PT \
    --domain=FSOCIETY \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass='<SUBSTITUIR_POR_PASSWORD_SEGURA>' \
    --option="interfaces=lo ens18" \
    --option="bind interfaces only=yes"
```

> ⚠️ **SEGURANÇA**: Substitua `<SUBSTITUIR_POR_PASSWORD_SEGURA>` por uma password forte e única. Nunca use passwords de exemplo em ambientes de produção.

### Parâmetros Explicados

| Parâmetro | Descrição |
|-----------|-----------|
| `--realm` | Nome do realm Kerberos (maiúsculas) |
| `--domain` | Nome NetBIOS do domínio (máx. 15 caracteres) |
| `--server-role` | Função: dc (Domain Controller) |
| `--dns-backend` | Backend DNS: SAMBA_INTERNAL |
| `--adminpass` | Password do Administrator |
| `--option` | Opções adicionais para smb.conf |

### Saída Esperada

```
Looking up IPv4 addresses
Looking up IPv6 addresses
Setting up share.ldb
Setting up secrets.ldb
Setting up the registry
Setting up the privileges database
Setting up idmap db
Setting up SAM db
Setting up sam.ldb partitions and settings
Setting up sam.ldb rootDSE
Pre-loading the Samba 4 and AD schema
...
Server Role:           active directory domain controller
Hostname:              dc
NetBIOS Domain:        FSOCIETY
DNS Domain:            fsociety.pt
DOMAIN SID:            S-1-5-21-XXXXXXXXX-XXXXXXXXX-XXXXXXXXX
```

---

## 📄 Configuração smb.conf

### Ficheiro Completo

**Localização:** `/etc/samba/smb.conf`

```ini
# Samba AD DC Configuration
# Domain: FSOCIETY.PT
# Server: dc.fsociety.pt
# Generated: December 2024

[global]
    # Identificação do Domínio
    workgroup = FSOCIETY
    realm = FSOCIETY.PT
    netbios name = DC
    server role = active directory domain controller
    server string = FSociety Domain Controller

    # Interfaces de Rede
    interfaces = lo ens18
    bind interfaces only = yes

    # DNS
    dns forwarder = 192.168.1.1

    # Logging
    log file = /var/log/samba/log.%m
    max log size = 10000
    log level = 1 auth_audit:3

    # Segurança
    server signing = mandatory
    client signing = mandatory
    server schannel = yes
    client schannel = yes
    
    # Kerberos
    kerberos method = secrets and keytab
    kerberos encryption types = strong

    # TLS/SSL
    tls enabled = yes
    tls keyfile = /etc/samba/tls/key.pem
    tls certfile = /etc/samba/tls/cert.pem
    tls cafile = /etc/samba/tls/ca.pem
    tls verify peer = ca_and_name

    # LDAP
    ldap server require strong auth = yes

    # Partilhas de Sistema
    template shell = /bin/bash
    template homedir = /home/%U

    # Idmap para utilizadores locais
    idmap_ldb:use rfc2307 = yes

    # Winbind
    winbind use default domain = yes
    winbind enum users = yes
    winbind enum groups = yes
    winbind nss info = rfc2307

    # Performance
    socket options = TCP_NODELAY IPTOS_LOWDELAY
    use sendfile = yes
    aio read size = 16384
    aio write size = 16384

[sysvol]
    path = /var/lib/samba/sysvol
    read only = No

[netlogon]
    path = /var/lib/samba/sysvol/fsociety.pt/scripts
    read only = No

[shared]
    path = /srv/samba/shared
    read only = no
    browseable = yes
    valid users = @"Domain Users"
    create mask = 0660
    directory mask = 0770
    comment = Partilha Comum

[departamentos]
    path = /srv/samba/departamentos
    read only = no
    browseable = yes
    valid users = @"Domain Admins"
    admin users = @"Domain Admins"
    create mask = 0660
    directory mask = 0770
    comment = Pastas de Departamentos

[homes]
    comment = Home Directories
    path = /home/%U
    read only = no
    browseable = no
    create mask = 0700
    directory mask = 0700
    valid users = %S
```

### Criar Diretórios para Partilhas

```bash
# Criar diretórios
sudo mkdir -p /srv/samba/shared
sudo mkdir -p /srv/samba/departamentos
sudo mkdir -p /home

# Definir permissões
sudo chmod 2770 /srv/samba/shared
sudo chmod 2770 /srv/samba/departamentos

# Definir proprietário (após AD configurado)
sudo chown root:"Domain Users" /srv/samba/shared
sudo chown root:"Domain Admins" /srv/samba/departamentos
```

---

## 🔒 Configuração TLS/SSL

### Gerar Certificados

```bash
# Criar diretório para certificados
sudo mkdir -p /etc/samba/tls

# Gerar chave privada
sudo openssl genrsa -out /etc/samba/tls/key.pem 4096

# Gerar certificado autoassinado (CA)
sudo openssl req -new -x509 \
    -key /etc/samba/tls/key.pem \
    -out /etc/samba/tls/ca.pem \
    -days 3650 \
    -subj "/C=PT/ST=Porto/L=Porto/O=FSociety/OU=IT/CN=fsociety.pt"

# Gerar CSR
sudo openssl req -new \
    -key /etc/samba/tls/key.pem \
    -out /etc/samba/tls/cert.csr \
    -subj "/C=PT/ST=Porto/L=Porto/O=FSociety/OU=IT/CN=dc.fsociety.pt"

# Assinar certificado
sudo openssl x509 -req \
    -in /etc/samba/tls/cert.csr \
    -CA /etc/samba/tls/ca.pem \
    -CAkey /etc/samba/tls/key.pem \
    -CAcreateserial \
    -out /etc/samba/tls/cert.pem \
    -days 3650 \
    -sha256
```

### Definir Permissões

```bash
# Permissões restritivas
sudo chmod 600 /etc/samba/tls/key.pem
sudo chmod 644 /etc/samba/tls/cert.pem
sudo chmod 644 /etc/samba/tls/ca.pem
sudo chown root:root /etc/samba/tls/*
```

### Verificar Certificados

```bash
# Ver detalhes do certificado
openssl x509 -in /etc/samba/tls/cert.pem -text -noout | head -20
```

---

## 🏢 Estrutura de OUs

### Criar Organizational Units

```bash
# OU Principal
sudo samba-tool ou create "OU=FSociety,DC=fsociety,DC=pt"

# OUs de Departamentos
sudo samba-tool ou create "OU=TI,OU=FSociety,DC=fsociety,DC=pt"
sudo samba-tool ou create "OU=RH,OU=FSociety,DC=fsociety,DC=pt"
sudo samba-tool ou create "OU=Comercial,OU=FSociety,DC=fsociety,DC=pt"
sudo samba-tool ou create "OU=Financeiro,OU=FSociety,DC=fsociety,DC=pt"

# OUs Auxiliares
sudo samba-tool ou create "OU=Grupos,OU=FSociety,DC=fsociety,DC=pt"
sudo samba-tool ou create "OU=Computadores,OU=FSociety,DC=fsociety,DC=pt"

# OU para Service Accounts
sudo samba-tool ou create "OU=Service Accounts,DC=fsociety,DC=pt"
```

### Visualizar Estrutura

```bash
# Listar OUs
sudo samba-tool ou list
```

### Estrutura Final

```
DC=fsociety,DC=pt
├── OU=FSociety
│   ├── OU=TI
│   ├── OU=RH
│   ├── OU=Comercial
│   ├── OU=Financeiro
│   ├── OU=Grupos
│   └── OU=Computadores
├── OU=Service Accounts
├── OU=Domain Controllers
│   └── CN=DC (Domain Controller)
├── CN=Users (built-in)
│   └── CN=Administrator
├── CN=Computers (built-in)
└── CN=Builtin
    ├── CN=Domain Admins
    ├── CN=Domain Users
    └── CN=...
```

---

## 👥 Grupos de Segurança

### Criar Grupos

```bash
# Grupos de Departamentos
sudo samba-tool group add GRP_TI \
    --description="Departamento de Tecnologias de Informação" \
    --groupou="OU=Grupos,OU=FSociety"

sudo samba-tool group add GRP_RH \
    --description="Departamento de Recursos Humanos" \
    --groupou="OU=Grupos,OU=FSociety"

sudo samba-tool group add GRP_Comercial \
    --description="Departamento Comercial" \
    --groupou="OU=Grupos,OU=FSociety"

sudo samba-tool group add GRP_Financeiro \
    --description="Departamento Financeiro" \
    --groupou="OU=Grupos,OU=FSociety"

# Grupos Especiais
sudo samba-tool group add GRP_Gestores \
    --description="Gestores e Diretores" \
    --groupou="OU=Grupos,OU=FSociety"

sudo samba-tool group add GRP_VPN_Users \
    --description="Utilizadores com acesso VPN" \
    --groupou="OU=Grupos,OU=FSociety"
```

### Listar Grupos

```bash
# Listar todos os grupos
sudo samba-tool group list

# Ver membros de um grupo
sudo samba-tool group listmembers "GRP_TI"
```

### Tabela de Grupos

| Grupo | OU | Descrição | Acesso VPN Pool |
|-------|----|-----------|-----------------| 
| GRP_TI | OU=Grupos,OU=FSociety | Departamento TI | ti_pool |
| GRP_RH | OU=Grupos,OU=FSociety | Recursos Humanos | vpn_users_pool |
| GRP_Comercial | OU=Grupos,OU=FSociety | Departamento Comercial | comercial_pool |
| GRP_Financeiro | OU=Grupos,OU=FSociety | Departamento Financeiro | financeiro_pool |
| GRP_Gestores | OU=Grupos,OU=FSociety | Gestores | gestores_pool |
| GRP_VPN_Users | OU=Grupos,OU=FSociety | Utilizadores VPN | vpn_users_pool |

---

## 🔧 Service Accounts

### Criar Service Account para LDAP

```bash
# Criar utilizador de serviço para integrações LDAP
# SEGURANÇA: Substituir '<PASSWORD_SEGURA>' por uma password forte
sudo samba-tool user create svc_ldap '<PASSWORD_SEGURA>' \
    --description="Service Account para integrações LDAP" \
    --userou="OU=Service Accounts"

# Configurar password para nunca expirar
sudo samba-tool user setexpiry svc_ldap --noexpiry

# Desativar mudança de password obrigatória
sudo samba-tool user setpassword svc_ldap --newpassword='<PASSWORD_SEGURA>' --must-change-at-next-login=no
```

> ⚠️ **SEGURANÇA**: Use uma password forte e única para o service account. Guarde-a de forma segura.

### Verificar Service Account

```bash
# Ver detalhes do utilizador
sudo samba-tool user show svc_ldap

# Testar autenticação LDAP
ldapwhoami -H ldap://localhost -D "CN=svc_ldap,OU=Service Accounts,DC=fsociety,DC=pt" -W
```

### Service Accounts Disponíveis

| Username | Descrição | Utilização |
|----------|-----------|------------|
| svc_ldap | Service Account LDAP | Nextcloud, Mailcow, FreeRADIUS |
| Administrator | Admin do Domínio | Administração geral |

---

## ✅ Verificação e Testes

### Iniciar Samba AD DC

```bash
# Configurar Kerberos
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Iniciar serviço
sudo systemctl unmask samba-ad-dc
sudo systemctl enable samba-ad-dc
sudo systemctl start samba-ad-dc

# Verificar estado
sudo systemctl status samba-ad-dc
```

### Testes de Funcionalidade

#### Teste DNS

```bash
# Resolver DC
host -t A dc.fsociety.pt localhost

# Resolver registos SRV
host -t SRV _ldap._tcp.fsociety.pt localhost
host -t SRV _kerberos._tcp.fsociety.pt localhost
```

#### Teste Kerberos

```bash
# Obter ticket Kerberos
kinit Administrator@FSOCIETY.PT

# Listar tickets
klist

# Destruir tickets
kdestroy
```

#### Teste LDAP

```bash
# Pesquisa LDAP anónima
ldapsearch -H ldap://localhost -x -b "DC=fsociety,DC=pt" "(objectClass=organizationalUnit)" dn

# Pesquisa autenticada
ldapsearch -H ldap://localhost -x -D "Administrator@fsociety.pt" -W -b "DC=fsociety,DC=pt" "(objectClass=user)" sAMAccountName
```

#### Teste SMB

```bash
# Listar partilhas
smbclient -L localhost -U Administrator

# Aceder a partilha
smbclient //localhost/sysvol -U Administrator
```

### Verificar Níveis do Domínio

```bash
# Ver nível funcional do domínio
sudo samba-tool domain level show
```

**Saída Esperada:**

```
Domain and calculation for domain function level: 4
Forest and calculation for forest function level: 4
Lowest msDS-Behavior-Version for all DCs: 4
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| Samba Wiki - AD DC | https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller |
| Samba Wiki - smb.conf | https://wiki.samba.org/index.php/Smb.conf |
| Samba Wiki - TLS | https://wiki.samba.org/index.php/Configuring_TLS_on_a_Samba_Server |

### RFCs e Padrões

| RFC | Descrição |
|-----|-----------|
| RFC 4120 | The Kerberos Network Authentication Service (V5) |
| RFC 4511 | LDAP: The Protocol |
| RFC 2307 | LDAP Network Information Service Schema |

### Artigos Técnicos

1. **Samba4 Active Directory** - Samba Team Documentation
2. **Setting up AD DC on Ubuntu** - Ubuntu Server Guide
3. **LDAP Security Best Practices** - OWASP

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
| [← Instalação Ubuntu](01-instalacao-ubuntu.md) | [📚 Índice](README.md) | [DNS Integrado →](03-dns-integrado.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-samba-ad-dc---active-directory-domain-controller)**

---

*Última atualização: Dezembro 2025*

</div>
