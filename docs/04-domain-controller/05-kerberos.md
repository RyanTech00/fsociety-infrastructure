# 🔐 Kerberos - Autenticação Centralizada

> **Configuração do protocolo Kerberos integrado com o Samba AD DC**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Conceitos Fundamentais](#-conceitos-fundamentais)
3. [Configuração krb5.conf](#-configuração-krb5conf)
4. [Keytabs e Principals](#-keytabs-e-principals)
5. [Tickets Kerberos](#-tickets-kerberos)
6. [Troubleshooting](#-troubleshooting)
7. [Verificação e Testes](#-verificação-e-testes)
8. [Referências](#-referências)

---

## 📖 Visão Geral

### O que é o Kerberos?

O Kerberos é um protocolo de autenticação de rede que utiliza criptografia de chave simétrica e tickets para permitir que os nós comuniquem de forma segura numa rede não segura. O nome vem de Cérbero, o cão de três cabeças da mitologia grega.

### Características Principais

| Característica | Descrição |
|----------------|-----------|
| **Single Sign-On (SSO)** | Autenticação única para múltiplos serviços |
| **Tickets temporários** | Credenciais com tempo de vida limitado |
| **Autenticação mútua** | Cliente e servidor autenticam-se mutuamente |
| **Delegação** | Credenciais podem ser delegadas a serviços |

### Informação do Realm

| Parâmetro | Valor |
|-----------|-------|
| **Realm** | FSOCIETY.PT |
| **KDC** | dc.fsociety.pt |
| **Admin Server** | dc.fsociety.pt |
| **Ticket Lifetime** | 24 horas |
| **Renew Lifetime** | 7 dias |

---

## 📚 Conceitos Fundamentais

### Componentes do Kerberos

```
                    ┌─────────────────────────────────────┐
                    │        KDC (Key Distribution Center) │
                    │           dc.fsociety.pt             │
                    ├─────────────────┬───────────────────┤
                    │       AS        │        TGS        │
                    │ Authentication  │   Ticket Granting │
                    │    Service      │      Service      │
                    └────────┬────────┴────────┬──────────┘
                             │                 │
           ┌─────────────────┘                 └─────────────────┐
           │                                                     │
           ▼                                                     ▼
    ┌──────────────┐                                     ┌──────────────┐
    │   Cliente    │◄───────────────────────────────────►│   Serviço    │
    │              │     Service Ticket (ST)             │   (HTTP,     │
    │  Utilizador  │                                     │  SMB, etc.)  │
    └──────────────┘                                     └──────────────┘
```

### Fluxo de Autenticação

1. **AS-REQ** - Cliente solicita TGT ao Authentication Service
2. **AS-REP** - AS retorna TGT cifrado com a chave do utilizador
3. **TGS-REQ** - Cliente apresenta TGT e solicita Service Ticket
4. **TGS-REP** - TGS retorna Service Ticket para o serviço pretendido
5. **AP-REQ** - Cliente apresenta Service Ticket ao serviço
6. **AP-REP** - Serviço verifica ticket e concede acesso

### Tipos de Tickets

| Ticket | Descrição | Validade |
|--------|-----------|----------|
| **TGT** (Ticket Granting Ticket) | Ticket inicial para obter outros tickets | 24h |
| **ST** (Service Ticket) | Ticket para aceder a um serviço específico | 24h |

---

## ⚙️ Configuração krb5.conf

### Ficheiro de Configuração

**Localização:** `/etc/krb5.conf`

```bash
sudo nano /etc/krb5.conf
```

**Conteúdo Completo:**

{% raw %}
```ini
# Kerberos Configuration
# Realm: FSOCIETY.PT
# KDC: dc.fsociety.pt

[libdefaults]
    # Realm padrão
    default_realm = FSOCIETY.PT
    
    # Resolução DNS
    dns_lookup_realm = false
    dns_lookup_kdc = true
    
    # Tipos de encriptação (do mais forte para o mais fraco)
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    
    # Tempos de ticket
    ticket_lifetime = 24h
    renew_lifetime = 7d
    
    # Opções de compatibilidade
    forwardable = true
    proxiable = true
    
    # Cache de credenciais
    default_ccache_name = FILE:/tmp/krb5cc_%{uid}

[realms]
    FSOCIETY.PT = {
        # Key Distribution Center
        kdc = dc.fsociety.pt
        
        # Servidor de administração
        admin_server = dc.fsociety.pt
        
        # Servidor de password
        kpasswd_server = dc.fsociety.pt
        
        # Canonicalização de nomes
        default_domain = fsociety.pt
    }

[domain_realm]
    # Mapeamento de domínio para realm
    .fsociety.pt = FSOCIETY.PT
    fsociety.pt = FSOCIETY.PT

[appdefaults]
    # Configurações por aplicação
    pam = {
        debug = false
        ticket_lifetime = 36000
        renew_lifetime = 36000
        forwardable = true
        krb4_convert = false
    }

[logging]
    # Logging
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/kdc.log
    admin_server = FILE:/var/log/kadmind.log
```
{% endraw %}

### Parâmetros Explicados

| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `default_realm` | FSOCIETY.PT | Realm padrão (sempre maiúsculas) |
| `dns_lookup_kdc` | true | Descobrir KDC via DNS SRV |
| `ticket_lifetime` | 24h | Validade do ticket |
| `renew_lifetime` | 7d | Período de renovação |
| `forwardable` | true | Permite delegação de tickets |

### Copiar do Samba

O Samba gera automaticamente o `krb5.conf` durante a provisão:

```bash
# Copiar configuração gerada pelo Samba
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Verificar conteúdo
cat /etc/krb5.conf
```

---

## 🔑 Keytabs e Principals

### O que é um Keytab?

Um keytab (key table) é um ficheiro que contém pares de principals Kerberos e chaves criptográficas. É utilizado por serviços para autenticação sem necessidade de password interativa.

### Principals do DC

| Principal | Descrição |
|-----------|-----------|
| `HOST/dc.fsociety.pt@FSOCIETY.PT` | Principal do host |
| `HOST/dc@FSOCIETY.PT` | Principal do host (nome curto) |
| `DC$@FSOCIETY.PT` | Conta de computador do DC |
| `cifs/dc.fsociety.pt@FSOCIETY.PT` | Serviço CIFS/SMB |
| `ldap/dc.fsociety.pt@FSOCIETY.PT` | Serviço LDAP |

### Ver Keytab do Sistema

```bash
# Ver principals no keytab do sistema
sudo klist -ek /etc/krb5.keytab

# Ver keytab do Samba
sudo klist -ek /var/lib/samba/private/secrets.keytab
```

### Saída Esperada

```
Keytab name: FILE:/etc/krb5.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   1 HOST/dc.fsociety.pt@FSOCIETY.PT (aes256-cts-hmac-sha1-96)
   1 HOST/dc.fsociety.pt@FSOCIETY.PT (aes128-cts-hmac-sha1-96)
   1 HOST/dc@FSOCIETY.PT (aes256-cts-hmac-sha1-96)
   1 DC$@FSOCIETY.PT (aes256-cts-hmac-sha1-96)
```

### Criar Keytab Personalizado

```bash
# Exportar keytab para um serviço
sudo samba-tool domain exportkeytab /tmp/http.keytab \
    --principal=HTTP/webserver.fsociety.pt@FSOCIETY.PT

# Ver conteúdo do keytab
sudo klist -ek /tmp/http.keytab
```

### Adicionar Principal ao Keytab

```bash
# Criar principal de serviço
sudo samba-tool spn add HTTP/webserver.fsociety.pt DC$

# Exportar para keytab
sudo samba-tool domain exportkeytab /etc/http.keytab \
    --principal=HTTP/webserver.fsociety.pt

# Definir permissões
sudo chmod 600 /etc/http.keytab
sudo chown www-data:www-data /etc/http.keytab
```

---

## 🎫 Tickets Kerberos

### Obter Ticket (kinit)

```bash
# Obter TGT com password
kinit Administrator@FSOCIETY.PT

# Obter TGT com keytab
kinit -k -t /etc/krb5.keytab HOST/dc.fsociety.pt@FSOCIETY.PT

# Obter TGT renovável
kinit -r 7d Administrator@FSOCIETY.PT
```

### Listar Tickets (klist)

```bash
# Listar tickets atuais
klist

# Listar com detalhes de encriptação
klist -e

# Listar todos os caches
klist -l
```

### Saída Esperada

```
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: Administrator@FSOCIETY.PT

Valid starting       Expires              Service principal
02/12/2024 10:00:00  03/12/2024 10:00:00  krbtgt/FSOCIETY.PT@FSOCIETY.PT
        renew until 09/12/2024 10:00:00
```

### Destruir Tickets (kdestroy)

```bash
# Destruir todos os tickets
kdestroy

# Destruir cache específico
kdestroy -c /tmp/krb5cc_1000
```

### Renovar Tickets

```bash
# Renovar TGT
kinit -R

# Verificar renovação
klist
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `Clock skew too great` | Diferença de relógio | Sincronizar NTP |
| `KDC unreachable` | Rede/DNS | Verificar conectividade |
| `Pre-authentication failed` | Password errada | Verificar credenciais |
| `Service not found` | SPN inexistente | Adicionar SPN |

### Verificar Sincronização de Tempo

```bash
# Verificar diferença de tempo
ntpdate -q dc.fsociety.pt

# A diferença máxima permitida é de 5 minutos (300 segundos)
```

### Debug de Kerberos

```bash
# Ativar debug
export KRB5_TRACE=/dev/stdout

# Executar comando
kinit Administrator@FSOCIETY.PT

# Desativar debug
unset KRB5_TRACE
```

### Verificar DNS SRV

```bash
# KDC
host -t SRV _kerberos._tcp.fsociety.pt

# Kpasswd
host -t SRV _kpasswd._tcp.fsociety.pt
```

### Logs

```bash
# Logs do Kerberos (se configurado)
sudo tail -f /var/log/kdc.log

# Logs do Samba (inclui Kerberos)
sudo tail -f /var/log/samba/log.samba
```

---

## ✅ Verificação e Testes

### Teste Completo de Kerberos

```bash
#!/bin/bash
# Script de verificação Kerberos

echo "=== Verificação Kerberos ==="

echo -e "\n--- Configuração ---"
cat /etc/krb5.conf | grep -E "(default_realm|kdc|admin_server)"

echo -e "\n--- DNS SRV Records ---"
host -t SRV _kerberos._tcp.fsociety.pt localhost
host -t SRV _kpasswd._tcp.fsociety.pt localhost

echo -e "\n--- Keytab do Sistema ---"
sudo klist -ek /etc/krb5.keytab 2>/dev/null | head -10

echo -e "\n--- Teste de Autenticação ---"
echo "Introduza a password do Administrator:"
kinit Administrator@FSOCIETY.PT

echo -e "\n--- Tickets Obtidos ---"
klist

echo -e "\n--- Destruir Tickets ---"
kdestroy
echo "Tickets destruídos."
```

### Testes Individuais

```bash
# 1. Testar obtenção de TGT
kinit Administrator@FSOCIETY.PT
klist

# 2. Testar acesso a serviço (LDAP)
ldapsearch -H ldap://dc.fsociety.pt -Y GSSAPI -b "DC=fsociety,DC=pt" "(objectClass=user)" cn

# 3. Testar acesso a partilha (SMB)
smbclient -k //dc.fsociety.pt/sysvol -c "ls"

# 4. Limpar tickets
kdestroy
```

### Verificar Encriptação

```bash
# Ver tipos de encriptação suportados
kinit -e Administrator@FSOCIETY.PT

# Verificar encriptação do ticket
klist -e
```

---

## 📊 Tabela de Referência Rápida

### Comandos Essenciais

| Comando | Descrição |
|---------|-----------|
| `kinit user@REALM` | Obter TGT |
| `kinit -k -t keytab principal` | Autenticar com keytab |
| `klist` | Listar tickets |
| `klist -e` | Listar tickets com encriptação |
| `kdestroy` | Destruir tickets |
| `kpasswd` | Alterar password |

### Ficheiros Importantes

| Ficheiro | Descrição |
|----------|-----------|
| `/etc/krb5.conf` | Configuração do cliente |
| `/etc/krb5.keytab` | Keytab do sistema |
| `/var/lib/samba/private/secrets.keytab` | Keytab do Samba |
| `/tmp/krb5cc_<uid>` | Cache de tickets |

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| MIT Kerberos Documentation | https://web.mit.edu/kerberos/krb5-latest/doc/ |
| Samba Wiki - Kerberos | https://wiki.samba.org/index.php/Kerberos |
| krb5.conf Manual | https://web.mit.edu/kerberos/krb5-latest/doc/admin/conf_files/krb5_conf.html |

### RFCs

| RFC | Descrição |
|-----|-----------|
| RFC 4120 | The Kerberos Network Authentication Service (V5) |
| RFC 4121 | The Kerberos Version 5 GSS-API Mechanism |
| RFC 6649 | Deprecate DES, RC4-HMAC-EXP in Kerberos |

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
| [← DHCP Server](04-dhcp-server.md) | [📚 Índice](README.md) | [FreeRADIUS + LDAP →](06-freeradius-ldap.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-kerberos---autenticação-centralizada)**

---

*Última atualização: Dezembro 2024*

</div>
