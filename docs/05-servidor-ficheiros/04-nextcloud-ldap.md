# 👥 Nextcloud - Integração LDAP

> **Configuração da integração do Nextcloud com Samba Active Directory para autenticação centralizada**

---

## 📋 Índice

1. [Pré-requisitos](#-pré-requisitos)
2. [Instalação da App LDAP](#-instalação-da-app-ldap)
3. [Configuração do Servidor LDAP](#-configuração-do-servidor-ldap)
4. [Filtros de Utilizadores](#-filtros-de-utilizadores)
5. [Filtros de Grupos](#-filtros-de-grupos)
6. [Atributos LDAP](#-atributos-ldap)
7. [Configurações Avançadas](#-configurações-avançadas)
8. [Teste e Verificação](#-teste-e-verificação)
9. [Troubleshooting](#-troubleshooting)
10. [Referências](#-referências)

---

## 📦 Pré-requisitos

### Conta de Serviço no AD

Criar conta de serviço no Domain Controller:

```bash
# No servidor DC (192.168.1.10)
sudo samba-tool user create nextcloud-ldap 'StrongP@ssw0rd!' \
  --description="Nextcloud LDAP Service Account" \
  --mail-address=nextcloud-ldap@fsociety.pt

# Definir password para não expirar
sudo samba-tool user setexpiry nextcloud-ldap --noexpiry

# Verificar
sudo samba-tool user show nextcloud-ldap
```

### Testar Conectividade LDAP

No servidor Nextcloud:

```bash
# Instalar ferramentas LDAP
sudo apt install -y ldap-utils

# Testar conexão ao DC
ldapsearch -x -H ldap://192.168.1.10 -D "CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt" -W -b "DC=fsociety,DC=pt" "(objectClass=user)"

# Deve retornar lista de utilizadores
```

---

## 📥 Instalação da App LDAP

### Via Interface Web

1. Login como administrador: `https://nextcloud.fsociety.pt`
2. **Apps** → **Integration** → **LDAP user and group backend**
3. Clicar em **Download and enable**

### Via Linha de Comandos

```bash
# Instalar app user_ldap
sudo -u www-data php /var/www/nextcloud/occ app:install user_ldap

# Ativar app
sudo -u www-data php /var/www/nextcloud/occ app:enable user_ldap

# Verificar
sudo -u www-data php /var/www/nextcloud/occ app:list | grep ldap
```

---

## 🔧 Configuração do Servidor LDAP

### Settings → LDAP/AD Integration

#### Tab 1: Server

```yaml
Host: ldap://192.168.1.10:389
Port: 389
User DN: CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt
Password: [password da conta de serviço]
Base DN: DC=fsociety,DC=pt
```

**Configuração via OCC:**

```bash
# Criar configuração LDAP (s01)
sudo -u www-data php /var/www/nextcloud/occ ldap:create-empty-config

# Configurar servidor
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapHost "ldap://192.168.1.10"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapPort "389"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapAgentName "CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapAgentPassword "StrongP@ssw0rd!"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBase "DC=fsociety,DC=pt"
```

#### Testar Conexão

```bash
# Testar configuração LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:test-config s01

# Deve retornar: "The configuration is valid and the connection could be established!"
```

---

## 👤 Filtros de Utilizadores

### User Filter

**Objetivo:** Sincronizar apenas utilizadores ativos do AD

```ldap
(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

**Explicação:**
- `objectClass=user` - Objeto é utilizador
- `objectCategory=person` - Categoria é pessoa
- `!(userAccountControl:1.2.840.113556.1.4.803:=2)` - Conta NÃO está desativada

**Configurar via OCC:**

```bash
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUserFilter "(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
```

### Login Filter

```ldap
samaccountname=%uid
```

**Configurar via OCC:**

```bash
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapLoginFilter "samaccountname=%uid"
```

### User Display Name Field

```bash
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUserDisplayName "displayName"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUserDisplayName2 "cn"
```

---

## 👥 Filtros de Grupos

### Group Filter

```ldap
objectClass=group
```

**Configurar via OCC:**

```bash
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupFilter "objectClass=group"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupDisplayName "cn"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupMemberAssocAttr "member"
```

### Base DN para Grupos

```bash
# OU onde estão os grupos
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBaseGroups "OU=Grupos,OU=FSociety,DC=fsociety,DC=pt"
```

---

## 📝 Atributos LDAP

### Mapeamento de Atributos

```bash
# Email
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapEmailAttribute "mail"

# Quota (não usado por defeito)
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapQuotaAttribute ""

# User UUID Attribute
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUuidUserAttribute "objectGUID"

# Group UUID Attribute
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUuidGroupAttribute "objectGUID"

# Username (usado internamente)
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapExpertUsernameAttr "samaccountname"
```

---

## ⚙️ Configurações Avançadas

### Nested Groups

```bash
# Ativar grupos aninhados
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapNestedGroups "1"
```

### Paging

```bash
# Ativar paging para grandes diretórios
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapPagingSize "500"
```

### Turn on SSL/TLS (Opcional)

Se usar LDAPS (porta 636):

```bash
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapHost "ldaps://192.168.1.10"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapPort "636"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapTLS "0"  # Não usar STARTTLS
```

### Cache

```bash
# Configurar cache
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapCacheTTL "600"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapConfigurationActive "1"
```

### Base Users

```bash
# OU onde estão os utilizadores
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBaseUsers "OU=FSociety,DC=fsociety,DC=pt"
```

---

## ✅ Teste e Verificação

### Verificar Configuração

```bash
# Ver toda a configuração LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:show-config s01

# Testar conexão
sudo -u www-data php /var/www/nextcloud/occ ldap:test-config s01
```

### Sincronizar Utilizadores

```bash
# Procurar utilizadores LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:check-user

# Contar utilizadores
sudo -u www-data php /var/www/nextcloud/occ ldap:search "(objectClass=user)"

# Forçar sincronização
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy"
```

### Listar Utilizadores Sincronizados

```bash
# Listar todos os utilizadores
sudo -u www-data php /var/www/nextcloud/occ user:list

# Deve mostrar 19 utilizadores do AD
```

### Verificar Grupos

```bash
# Listar grupos
sudo -u www-data php /var/www/nextcloud/occ group:list

# Ver membros de um grupo
sudo -u www-data php /var/www/nextcloud/occ group:list GRP_TI
```

### Testar Login

1. Abrir `https://nextcloud.fsociety.pt`
2. Login com utilizador AD (ex: `rbarbosa`)
3. Password do AD
4. Deve fazer login com sucesso

---

## 🔍 Troubleshooting

### Debug Mode

```bash
# Ativar debug LDAP
sudo -u www-data php /var/www/nextcloud/occ config:system:set loglevel --value=0

# Ver logs
sudo tail -f /var/www/nextcloud/data/nextcloud.log | grep -i ldap

# Desativar debug (depois)
sudo -u www-data php /var/www/nextcloud/occ config:system:set loglevel --value=2
```

### Limpar Cache LDAP

```bash
# Limpar cache LDAP
sudo -u www-data php /var/www/nextcloud/occ ldap:invalidate-cache
```

### Verificar Conectividade LDAP

```bash
# Teste manual
ldapsearch -x -H ldap://192.168.1.10 \
  -D "CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt" \
  -W \
  -b "DC=fsociety,DC=pt" \
  "(&(objectClass=user)(objectCategory=person))" \
  samaccountname displayName mail
```

### Problemas Comuns

#### Utilizadores não aparecem

```bash
# Verificar filtro de utilizadores
sudo -u www-data php /var/www/nextcloud/occ ldap:show-config s01 | grep ldapUserFilter

# Re-sincronizar
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy" --missing-account-action=enable
```

#### Login não funciona

```bash
# Verificar login filter
sudo -u www-data php /var/www/nextcloud/occ ldap:show-config s01 | grep ldapLoginFilter

# Testar credenciais manualmente
ldapwhoami -x -H ldap://192.168.1.10 -D "CN=rbarbosa,OU=TI,OU=FSociety,DC=fsociety,DC=pt" -W
```

#### Grupos não sincronizam

```bash
# Verificar filtro de grupos
sudo -u www-data php /var/www/nextcloud/occ ldap:show-config s01 | grep ldapGroupFilter

# Forçar sincronização de grupos
sudo -u www-data php /var/www/nextcloud/occ group:list
```

---

## 📊 Estatísticas de Sincronização

### Utilizadores Sincronizados

```bash
# Contar utilizadores LDAP
sudo -u www-data php /var/www/nextcloud/occ user:list | grep -c "ldap"
```

**Esperado:** 19 utilizadores

### Grupos Sincronizados

| Grupo AD | Membros | Descrição |
|----------|---------|-----------|
| GRP_TI | 3 | Departamento TI |
| GRP_Gestores | 2 | Gestores |
| GRP_Financeiro | 4 | Financeiro |
| GRP_Comercial | 5 | Comercial |
| GRP_RH | 3 | Recursos Humanos |
| GRP_VPN_Users | 15 | Utilizadores VPN |

---

## 📖 Configuração Completa via OCC

Script completo para configurar LDAP:

```bash
#!/bin/bash

# Criar configuração
sudo -u www-data php /var/www/nextcloud/occ ldap:create-empty-config

# Servidor
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapHost "ldap://192.168.1.10"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapPort "389"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapAgentName "CN=nextcloud-ldap,CN=Users,DC=fsociety,DC=pt"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapAgentPassword "password_here"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBase "DC=fsociety,DC=pt"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBaseUsers "OU=FSociety,DC=fsociety,DC=pt"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapBaseGroups "OU=Grupos,OU=FSociety,DC=fsociety,DC=pt"

# Filtros
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUserFilter "(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapLoginFilter "samaccountname=%uid"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupFilter "objectClass=group"

# Atributos
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUserDisplayName "displayName"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapEmailAttribute "mail"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupDisplayName "cn"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapGroupMemberAssocAttr "member"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUuidUserAttribute "objectGUID"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapUuidGroupAttribute "objectGUID"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapExpertUsernameAttr "samaccountname"

# Avançado
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapNestedGroups "1"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapPagingSize "500"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapCacheTTL "600"
sudo -u www-data php /var/www/nextcloud/occ ldap:set-config s01 ldapConfigurationActive "1"

# Testar
sudo -u www-data php /var/www/nextcloud/occ ldap:test-config s01

# Sincronizar
sudo -u www-data php /var/www/nextcloud/occ user:sync "OCA\User_LDAP\User_Proxy"
```

---

## 📝 Checklist

- [x] Conta de serviço LDAP criada no AD
- [x] Conectividade LDAP testada
- [x] App user_ldap instalada e ativada
- [x] Servidor LDAP configurado
- [x] Filtros de utilizadores definidos
- [x] Filtros de grupos definidos
- [x] Atributos mapeados
- [x] Configurações avançadas aplicadas
- [x] Teste de conexão bem-sucedido
- [x] 19 utilizadores sincronizados
- [x] 6 grupos sincronizados
- [x] Login testado com sucesso

---

## 📖 Referências

- [Nextcloud LDAP Integration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_user/user_auth_ldap.html)
- [Active Directory LDAP Syntax](https://social.technet.microsoft.com/wiki/contents/articles/5392.active-directory-ldap-syntax-filters.aspx)
- [Samba AD DC](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)

---

<div align="center">

**[⬅️ Voltar: Configuração Nextcloud](03-nextcloud-config.md)** | **[Próximo: Nextcloud Apps ➡️](05-nextcloud-apps.md)**

</div>

---

*Última atualização: Dezembro 2024*
