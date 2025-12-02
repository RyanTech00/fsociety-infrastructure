# 📁 Partilhas SMB e Permissões

> **Configuração das partilhas de ficheiros e controlo de acesso no Samba AD**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Partilhas de Sistema (AD)](#-partilhas-de-sistema-ad)
3. [Partilha Shared](#-partilha-shared)
4. [Partilha Departamentos](#-partilha-departamentos)
5. [Pastas Pessoais (Homes)](#-pastas-pessoais-homes)
6. [Permissões ACL](#-permissões-acl)
7. [Verificação e Testes](#-verificação-e-testes)
8. [Referências](#-referências)

---

## 📖 Visão Geral

### Partilhas Configuradas

| Partilha | Caminho | Acesso | Descrição |
|----------|---------|--------|-----------|
| [sysvol] | /var/lib/samba/sysvol | AD Internal | Scripts de login e GPOs |
| [netlogon] | /var/lib/samba/sysvol/fsociety.pt/scripts | AD Internal | Scripts de netlogon |
| [shared] | /srv/samba/shared | Domain Users | Partilha comum |
| [departamentos] | /srv/samba/departamentos | Domain Admins | Pastas departamentais |
| [homes] | /home/%U | Utilizador | Pasta pessoal |

### Arquitetura de Partilhas

```
                      ┌─────────────────────────────┐
                      │     dc.fsociety.pt          │
                      │      Samba AD DC            │
                      └─────────────┬───────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
    ┌───────▼───────┐       ┌───────▼───────┐       ┌───────▼───────┐
    │   SYSVOL      │       │    SHARED     │       │    HOMES      │
    │   NETLOGON    │       │ DEPARTAMENTOS │       │               │
    ├───────────────┤       ├───────────────┤       ├───────────────┤
    │ • GPOs        │       │ • Documentos  │       │ • /home/user1 │
    │ • Scripts     │       │ • TI/         │       │ • /home/user2 │
    │ • Templates   │       │ • RH/         │       │ • ...         │
    │               │       │ • Comercial/  │       │               │
    │ Acesso: AD    │       │ • Financeiro/ │       │ Acesso: User  │
    └───────────────┘       └───────────────┘       └───────────────┘
```

---

## 🔧 Partilhas de Sistema (AD)

### SYSVOL

A partilha SYSVOL é criada automaticamente durante a provisão do AD e contém:

- **Group Policy Objects (GPOs)**
- **Scripts de startup/shutdown**
- **Templates administrativos**

**Configuração em smb.conf:**

```ini
[sysvol]
    path = /var/lib/samba/sysvol
    read only = No
```

**Estrutura:**

```
/var/lib/samba/sysvol/
└── fsociety.pt/
    ├── Policies/
    │   ├── {GUID}/         # GPOs
    │   └── ...
    └── scripts/            # Scripts de login
```

### NETLOGON

A partilha NETLOGON contém scripts executados durante o login dos utilizadores.

**Configuração em smb.conf:**

```ini
[netlogon]
    path = /var/lib/samba/sysvol/fsociety.pt/scripts
    read only = No
```

**Exemplo de Script de Login:**

```batch
@echo off
REM login.bat - Script de login FSociety

REM Mapear drives de rede
net use H: \\dc.fsociety.pt\homes /persistent:yes
net use S: \\dc.fsociety.pt\shared /persistent:yes

REM Sincronizar hora
net time \\dc.fsociety.pt /set /yes

echo Login concluído com sucesso!
```

### Verificar Partilhas de Sistema

```bash
# Listar partilhas
smbclient -L localhost -U Administrator

# Aceder a sysvol
smbclient //localhost/sysvol -U Administrator -c "ls"

# Aceder a netlogon
smbclient //localhost/netlogon -U Administrator -c "ls"
```

---

## 📂 Partilha Shared

### Descrição

Partilha comum acessível a todos os utilizadores do domínio para troca de ficheiros.

### Configuração em smb.conf

```ini
[shared]
    # Descrição
    comment = Partilha Comum FSociety
    
    # Caminho no sistema
    path = /srv/samba/shared
    
    # Permissões básicas
    read only = no
    browseable = yes
    
    # Controlo de acesso
    valid users = @"Domain Users"
    
    # Máscara de criação
    create mask = 0660
    directory mask = 0770
    force create mode = 0660
    force directory mode = 0770
    
    # Herança de permissões
    inherit permissions = yes
    inherit acls = yes
    
    # VFS modules para ACLs
    vfs objects = acl_xattr
```

### Criar Estrutura

```bash
# Criar diretório
sudo mkdir -p /srv/samba/shared

# Criar subpastas
sudo mkdir -p /srv/samba/shared/{Documentos,Imagens,Templates}

# Definir permissões
sudo chmod 2770 /srv/samba/shared
sudo chmod 2770 /srv/samba/shared/*

# Definir grupo
sudo chgrp -R "Domain Users" /srv/samba/shared

# Aplicar ACLs
sudo setfacl -R -m g:"Domain Users":rwx /srv/samba/shared
sudo setfacl -R -d -m g:"Domain Users":rwx /srv/samba/shared
```

### Verificar

```bash
# Ver permissões
ls -la /srv/samba/shared

# Ver ACLs
getfacl /srv/samba/shared

# Testar acesso
smbclient //localhost/shared -U testuser -c "ls"
```

---

## 🏢 Partilha Departamentos

### Descrição

Partilha organizada por departamentos com controlo de acesso granular.

### Configuração em smb.conf

```ini
[departamentos]
    # Descrição
    comment = Pastas de Departamentos
    
    # Caminho no sistema
    path = /srv/samba/departamentos
    
    # Permissões básicas
    read only = no
    browseable = yes
    
    # Controlo de acesso (administradores têm acesso total)
    valid users = @"Domain Admins" @"GRP_TI" @"GRP_RH" @"GRP_Comercial" @"GRP_Financeiro"
    admin users = @"Domain Admins"
    
    # Máscara de criação
    create mask = 0660
    directory mask = 0770
    
    # Herança
    inherit permissions = yes
    inherit acls = yes
    
    # VFS
    vfs objects = acl_xattr
```

### Criar Estrutura de Departamentos

```bash
# Criar estrutura
sudo mkdir -p /srv/samba/departamentos/{TI,RH,Comercial,Financeiro,Gestao}

# Definir permissões base
sudo chmod 2770 /srv/samba/departamentos
sudo chgrp "Domain Admins" /srv/samba/departamentos

# Permissões por departamento
sudo chgrp "GRP_TI" /srv/samba/departamentos/TI
sudo chgrp "GRP_RH" /srv/samba/departamentos/RH
sudo chgrp "GRP_Comercial" /srv/samba/departamentos/Comercial
sudo chgrp "GRP_Financeiro" /srv/samba/departamentos/Financeiro
sudo chgrp "GRP_Gestores" /srv/samba/departamentos/Gestao

# Chmod para cada pasta
sudo chmod 2770 /srv/samba/departamentos/*
```

### Aplicar ACLs por Departamento

```bash
# TI - Acesso total para GRP_TI
sudo setfacl -R -m g:"GRP_TI":rwx /srv/samba/departamentos/TI
sudo setfacl -R -d -m g:"GRP_TI":rwx /srv/samba/departamentos/TI

# RH - Acesso total para GRP_RH
sudo setfacl -R -m g:"GRP_RH":rwx /srv/samba/departamentos/RH
sudo setfacl -R -d -m g:"GRP_RH":rwx /srv/samba/departamentos/RH

# Comercial - Acesso total para GRP_Comercial
sudo setfacl -R -m g:"GRP_Comercial":rwx /srv/samba/departamentos/Comercial
sudo setfacl -R -d -m g:"GRP_Comercial":rwx /srv/samba/departamentos/Comercial

# Financeiro - Acesso total para GRP_Financeiro
sudo setfacl -R -m g:"GRP_Financeiro":rwx /srv/samba/departamentos/Financeiro
sudo setfacl -R -d -m g:"GRP_Financeiro":rwx /srv/samba/departamentos/Financeiro

# Gestão - Acesso total para GRP_Gestores
sudo setfacl -R -m g:"GRP_Gestores":rwx /srv/samba/departamentos/Gestao
sudo setfacl -R -d -m g:"GRP_Gestores":rwx /srv/samba/departamentos/Gestao

# Domain Admins - Acesso total a tudo
sudo setfacl -R -m g:"Domain Admins":rwx /srv/samba/departamentos
sudo setfacl -R -d -m g:"Domain Admins":rwx /srv/samba/departamentos
```

### Tabela de Permissões

| Pasta | Grupo | Permissões |
|-------|-------|------------|
| /TI | GRP_TI | rwx |
| /TI | Domain Admins | rwx |
| /RH | GRP_RH | rwx |
| /RH | Domain Admins | rwx |
| /Comercial | GRP_Comercial | rwx |
| /Comercial | Domain Admins | rwx |
| /Financeiro | GRP_Financeiro | rwx |
| /Financeiro | Domain Admins | rwx |
| /Gestao | GRP_Gestores | rwx |
| /Gestao | Domain Admins | rwx |

---

## 🏠 Pastas Pessoais (Homes)

### Descrição

Cada utilizador do domínio tem uma pasta pessoal privada em `/home/<username>`.

### Configuração em smb.conf

```ini
[homes]
    # Descrição
    comment = Home Directories
    
    # Caminho dinâmico
    path = /home/%U
    
    # Permissões
    read only = no
    browseable = no
    
    # Apenas o próprio utilizador
    valid users = %S
    
    # Máscara restritiva
    create mask = 0700
    directory mask = 0700
    force create mode = 0700
    force directory mode = 0700
    
    # VFS
    vfs objects = acl_xattr
```

### Criar Pasta Home Automaticamente

**Script:** `/etc/samba/scripts/create-home.sh`

```bash
#!/bin/bash
# Criar pasta home para novo utilizador

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Uso: $0 <username>"
    exit 1
fi

# Criar pasta
mkdir -p /home/$USERNAME

# Definir proprietário
chown $USERNAME:"Domain Users" /home/$USERNAME

# Definir permissões
chmod 700 /home/$USERNAME

echo "Pasta home criada para $USERNAME"
```

### Configurar PAM para Criação Automática

```bash
# Editar PAM
sudo nano /etc/pam.d/common-session
```

**Adicionar:**

```
session required pam_mkhomedir.so skel=/etc/skel umask=0077
```

### Verificar Homes

```bash
# Listar homes existentes
ls -la /home/

# Testar acesso
smbclient //localhost/homes -U testuser -c "ls"

# Verificar permissões
getfacl /home/testuser
```

---

## 🔐 Permissões ACL

### Windows ACLs vs POSIX ACLs

O Samba suporta ambos os sistemas de ACLs:

| Tipo | Descrição | Utilização |
|------|-----------|------------|
| **POSIX ACLs** | ACLs nativas do Linux | `setfacl`, `getfacl` |
| **Windows ACLs** | ACLs estilo NTFS | Armazenadas em xattr |

### Configurar ACLs Windows (Recomendado)

**Adicionar ao smb.conf:**

```ini
[global]
    # Suporte a ACLs Windows
    vfs objects = acl_xattr
    map acl inherit = yes
    store dos attributes = yes
    
    # Herança de ACLs
    inherit acls = yes
    inherit permissions = yes
```

### Gerir ACLs com samba-tool

```bash
# Ver ACLs de uma partilha
samba-tool ntacl get /srv/samba/shared

# Definir ACLs
samba-tool ntacl set "O:DAG:DAD:P(A;OICI;FA;;;DA)(A;OICI;0x1200a9;;;DU)" /srv/samba/shared
```

### Gerir ACLs do Windows

1. **Ligar unidade de rede** no Windows
2. **Propriedades** → **Segurança** → **Avançadas**
3. Adicionar/modificar permissões conforme necessário

### Permissões NTFS Comuns

| Permissão | Descrição | Valor |
|-----------|-----------|-------|
| Full Control | Controlo total | FA |
| Modify | Modificar | 0x1301bf |
| Read & Execute | Ler e executar | 0x1200a9 |
| Read | Apenas leitura | 0x120089 |
| Write | Escrita | 0x120116 |

---

## ✅ Verificação e Testes

### Testar Acesso às Partilhas

```bash
#!/bin/bash
# Script de teste de partilhas
# NOTA: Substituir <PASSWORD> pela password real do Administrator

echo "=== Teste de Partilhas SMB ==="

# Solicitar password
read -sp "Password do Administrator: " ADMIN_PASS
echo

# Listar partilhas
echo -e "\n--- Partilhas Disponíveis ---"
smbclient -L localhost -U Administrator%"$ADMIN_PASS"

# Testar sysvol
echo -e "\n--- SYSVOL ---"
smbclient //localhost/sysvol -U Administrator%"$ADMIN_PASS" -c "ls" 2>/dev/null && echo "OK" || echo "ERRO"

# Testar netlogon
echo -e "\n--- NETLOGON ---"
smbclient //localhost/netlogon -U Administrator%"$ADMIN_PASS" -c "ls" 2>/dev/null && echo "OK" || echo "ERRO"

# Testar shared
echo -e "\n--- SHARED ---"
smbclient //localhost/shared -U Administrator%"$ADMIN_PASS" -c "ls" 2>/dev/null && echo "OK" || echo "ERRO"

# Testar departamentos
echo -e "\n--- DEPARTAMENTOS ---"
smbclient //localhost/departamentos -U Administrator%"$ADMIN_PASS" -c "ls" 2>/dev/null && echo "OK" || echo "ERRO"

# Limpar variável de password
unset ADMIN_PASS
```

### Verificar Permissões

```bash
# Ver estrutura de permissões
echo "=== Permissões /srv/samba ==="
ls -laR /srv/samba/

echo -e "\n=== ACLs /srv/samba/shared ==="
getfacl /srv/samba/shared

echo -e "\n=== ACLs /srv/samba/departamentos ==="
getfacl /srv/samba/departamentos
getfacl /srv/samba/departamentos/*
```

### Testar Criação de Ficheiros

```bash
# Como utilizador do domínio
smbclient //localhost/shared -U testuser -c "put /etc/hostname test.txt"
smbclient //localhost/shared -U testuser -c "ls"
smbclient //localhost/shared -U testuser -c "rm test.txt"
```

### Verificar Quotas (Opcional)

```bash
# Se quotas estiverem configuradas
repquota -a
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Access Denied | Permissões incorretas | Verificar ACLs e grupos |
| Partilha não aparece | browseable = no | Normal para [homes] |
| Não consegue criar ficheiros | create mask errado | Verificar umask |
| Herança não funciona | inherit acls = no | Ativar no smb.conf |

### Verificar Grupos do Utilizador

```bash
# Ver grupos de um utilizador
samba-tool user getgroups testuser

# Ou via LDAP
ldapsearch -H ldap://localhost -x -D "Administrator@fsociety.pt" -W \
    -b "DC=fsociety,DC=pt" "(sAMAccountName=testuser)" memberOf
```

### Logs de Acesso

```bash
# Ativar audit log no smb.conf
# [global]
# log level = 1 auth_audit:3

# Ver logs
sudo tail -f /var/log/samba/log.smbd
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| Samba File Sharing | https://wiki.samba.org/index.php/Setting_up_a_Share_Using_Windows_ACLs |
| Samba VFS Modules | https://wiki.samba.org/index.php/Virtual_File_System_Modules |
| Samba ACLs | https://wiki.samba.org/index.php/Setting_up_a_Share_Using_POSIX_ACLs |

### Artigos Técnicos

1. **Samba File Shares Best Practices** - Samba Wiki
2. **POSIX ACLs on Linux** - Linux Documentation Project
3. **Windows ACLs with Samba** - Red Hat Documentation

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
| [← CrowdSec](07-crowdsec.md) | [📚 Índice](README.md) | [Manutenção →](09-manutencao.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-partilhas-smb-e-permissões)**

---

*Última atualização: Dezembro 2024*

</div>
