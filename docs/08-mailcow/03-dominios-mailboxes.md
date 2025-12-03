# 📬 Domínios e Mailboxes

> **Guia de configuração de domínios, criação de contas de email, aliases e quotas no Mailcow**

---

## 📋 Índice

1. [Adicionar Domínio](#-adicionar-domínio)
2. [Criar Mailboxes](#-criar-mailboxes)
3. [Lista de Utilizadores FSociety](#-lista-de-utilizadores-fsociety)
4. [Aliases de Email](#-aliases-de-email)
5. [Quotas e Limites](#-quotas-e-limites)
6. [Gestão via Web UI](#-gestão-via-web-ui)
7. [Gestão via CLI](#-gestão-via-cli)

---

## 🌐 Adicionar Domínio

### Via Web Interface

1. **Aceder ao painel de administração:**
   - URL: https://mail.fsociety.pt
   - Login: `admin`

2. **Navegar para Configuration → Mail Setup:**
   - Clicar em **"Domains"**
   - Clicar no botão **"Add domain"**

3. **Preencher informações do domínio:**

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Domain** | fsociety.pt | Nome do domínio |
| **Description** | Domínio principal FSociety | Descrição opcional |
| **Max. mailboxes** | 50 | Número máximo de contas |
| **Max. aliases** | 100 | Número máximo de aliases |
| **Default mailbox quota** | 5120 MB | Quota padrão (5 GB) |
| **Max. quota per mailbox** | 10240 MB | Quota máxima (10 GB) |
| **Domain quota** | 102400 MB | Quota total domínio (100 GB) |

4. **Configurações avançadas:**
   - ✅ **Enable relay for this domain** (se necessário)
   - ✅ **Backupmx** (deixar desativado)
   - ✅ **Relay all recipients** (deixar desativado)

5. **Clicar em "Add domain and restart SOGo"**

### Verificar Domínio Criado

```bash
# Ver domínios configurados
sudo docker compose exec mysql-mailcow \
  mysql -u mailcow -p mailcow -e "SELECT domain FROM domain;"
```

**Saída esperada:**
```
+-------------+
| domain      |
+-------------+
| fsociety.pt |
+-------------+
```

---

## 📮 Criar Mailboxes

### Via Web Interface

1. **Configuration → Mail Setup → Mailboxes**
2. **Clicar em "Add mailbox"**

### Exemplo: Criar conta ryan.barbosa@fsociety.pt

| Campo | Valor |
|-------|-------|
| **Username** | ryan.barbosa |
| **Domain** | fsociety.pt |
| **Full name** | Ryan Barbosa |
| **Password** | `<senha_forte>` |
| **Confirm password** | `<senha_forte>` |
| **Quota** | 5120 MB (5 GB) |
| **Active** | ✅ Sim |
| **Send/Receive** | ✅ Ambos ativos |

3. **Clicar em "Add"**

### Criação em Massa

Para criar múltiplas contas rapidamente, pode-se usar um script:

```bash
# Script de criação (exemplo)
#!/bin/bash

DOMAIN="fsociety.pt"
MAILCOW_API="https://mail.fsociety.pt/api/v1"
API_KEY="<sua_api_key>"

# Array de utilizadores
USERS=(
  "ana.rodrigues:Ana Rodrigues"
  "bruno.ferreira:Bruno Ferreira"
  "carlos.mendes:Carlos Mendes"
)

for USER in "${USERS[@]}"; do
  USERNAME=$(echo $USER | cut -d: -f1)
  FULLNAME=$(echo $USER | cut -d: -f2)
  
  curl -X POST "$MAILCOW_API/add/mailbox" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"local_part\": \"$USERNAME\",
      \"domain\": \"$DOMAIN\",
      \"name\": \"$FULLNAME\",
      \"quota\": 5120,
      \"password\": \"ChangeMe123!\",
      \"active\": 1
    }"
done
```

---

## 👥 Lista de Utilizadores FSociety

Total de **20 mailboxes** configuradas para o domínio fsociety.pt:

### Equipa TI (Administradores)

| Email | Nome Completo | Quota | Função |
|-------|---------------|-------|--------|
| hugo.correia@fsociety.pt | Hugo Correia | 10 GB | Administrador de Sistemas |
| ryan.barbosa@fsociety.pt | Ryan Barbosa | 10 GB | Administrador de Sistemas |
| igor.araujo@fsociety.pt | Igor Araújo | 10 GB | Administrador de Sistemas |

### Conta de Sistema

| Email | Nome Completo | Quota | Função |
|-------|---------------|-------|--------|
| tickets@fsociety.pt | Sistema de Tickets | 20 GB | Integração Zammad |

### Utilizadores Gerais

| Email | Nome Completo | Quota |
|-------|---------------|-------|
| ana.rodrigues@fsociety.pt | Ana Rodrigues | 5 GB |
| bruno.ferreira@fsociety.pt | Bruno Ferreira | 5 GB |
| carlos.mendes@fsociety.pt | Carlos Mendes | 5 GB |
| claudia.sousa@fsociety.pt | Cláudia Sousa | 5 GB |
| daniel.ribeiro@fsociety.pt | Daniel Ribeiro | 5 GB |
| ines.gomes@fsociety.pt | Inês Gomes | 5 GB |
| joao.silva@fsociety.pt | João Silva | 5 GB |
| luis.martins@fsociety.pt | Luís Martins | 5 GB |
| maria.santos@fsociety.pt | Maria Santos | 5 GB |
| miguel.carvalho@fsociety.pt | Miguel Carvalho | 5 GB |
| patricia.lima@fsociety.pt | Patrícia Lima | 5 GB |
| pedro.costa@fsociety.pt | Pedro Costa | 5 GB |
| ricardo.oliveira@fsociety.pt | Ricardo Oliveira | 5 GB |
| sara.pinto@fsociety.pt | Sara Pinto | 5 GB |
| sofia.almeida@fsociety.pt | Sofia Almeida | 5 GB |
| teresa.pereira@fsociety.pt | Teresa Pereira | 5 GB |

### Estatísticas

```
Total de contas: 20
Quota total alocada: 145 GB
  - Administradores: 30 GB (3 x 10 GB)
  - Sistema: 20 GB (1 x 20 GB)
  - Utilizadores: 80 GB (16 x 5 GB)
  - Buffer disponível: ~15 GB
```

---

## 📧 Aliases de Email

Aliases permitem que um email seja recebido por múltiplos endereços.

### Criar Alias via Web UI

1. **Configuration → Mail Setup → Aliases**
2. **Clicar em "Add alias"**

### Exemplos de Aliases Comuns

| Alias | Destino | Função |
|-------|---------|--------|
| admin@fsociety.pt | ryan.barbosa@fsociety.pt | Administração geral |
| suporte@fsociety.pt | tickets@fsociety.pt | Suporte técnico |
| info@fsociety.pt | hugo.correia@fsociety.pt | Informações gerais |
| noreply@fsociety.pt | /dev/null | Emails automáticos |
| ti@fsociety.pt | hugo.correia@fsociety.pt, ryan.barbosa@fsociety.pt, igor.araujo@fsociety.pt | Equipa TI |

### Criar Alias via CLI

```bash
# Via API
curl -X POST "https://mail.fsociety.pt/api/v1/add/alias" \
  -H "X-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "admin@fsociety.pt",
    "goto": "ryan.barbosa@fsociety.pt",
    "active": 1
  }'
```

---

## 💾 Quotas e Limites

### Tipos de Quotas

1. **Quota de Mailbox:** Espaço máximo por conta
2. **Quota de Domínio:** Espaço total para todas as contas do domínio
3. **Message Size Limit:** Tamanho máximo de email individual

### Ver Uso de Quota

**Via Web UI:**
1. Configuration → Mail Setup → Mailboxes
2. Coluna **"Quota"** mostra uso/total

**Via CLI:**
```bash
# Ver uso de disco por mailbox
sudo du -sh /opt/mailcow-dockerized/data/vmail/fsociety.pt/*

# Relatório detalhado
sudo docker compose exec dovecot-mailcow doveadm quota get -A
```

### Alterar Quota de Utilizador

**Via Web UI:**
1. Configuration → Mail Setup → Mailboxes
2. Clicar em **Edit** na conta desejada
3. Ajustar campo **"Quota (MiB)"**
4. Salvar

**Via CLI:**
```bash
# Aumentar quota para 10 GB
curl -X POST "https://mail.fsociety.pt/api/v1/edit/mailbox" \
  -H "X-API-Key: <api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "items": ["ryan.barbosa@fsociety.pt"],
    "attr": {
      "quota": 10240
    }
  }'
```

### Avisos de Quota

Configurar alertas quando quota atingir limite:

1. **System → Configuration → Mailboxes**
2. **Quota Warning:** `90` (aviso aos 90%)
3. **Quota Notification:** Email para admin

---

## 🖥️ Gestão via Web UI

### Dashboard de Mailboxes

**URL:** https://mail.fsociety.pt → Configuration → Mail Setup → Mailboxes

**Funções disponíveis:**

| Ação | Descrição |
|------|-----------|
| ✏️ **Edit** | Alterar nome, senha, quota |
| 🔒 **Suspend** | Desativar temporariamente |
| 🗑️ **Delete** | Remover permanentemente |
| 📊 **Stats** | Ver estatísticas de uso |
| 🔑 **Reset Password** | Alterar senha |
| 📂 **Mailbox ACL** | Partilhar pastas |

### Filtros de Pesquisa

```
Pesquisar por:
- Nome de utilizador
- Domínio
- Nome completo
- Estado (ativo/inativo)
```

---

## 💻 Gestão via CLI

### Listar Mailboxes

```bash
# Via MySQL
sudo docker compose exec mysql-mailcow \
  mysql -u mailcow -p mailcow -e \
  "SELECT username, name, quota, active FROM mailbox WHERE domain='fsociety.pt';"
```

### Ver Detalhes de Conta

```bash
# Informação completa
sudo docker compose exec mysql-mailcow \
  mysql -u mailcow -p mailcow -e \
  "SELECT * FROM mailbox WHERE username='ryan.barbosa@fsociety.pt'\G"
```

### Alterar Password

```bash
# Via doveadm
sudo docker compose exec dovecot-mailcow \
  doveadm pw -s SHA512-CRYPT -p 'NovaSenha123!'

# Atualizar no MySQL com hash gerado
```

### Estatísticas de Email

```bash
# Emails enviados/recebidos
sudo docker compose exec mysql-mailcow \
  mysql -u mailcow -p mailcow -e \
  "SELECT COUNT(*) FROM smtp_log WHERE user='ryan.barbosa@fsociety.pt';"
```

---

## 🔍 Troubleshooting

### Mailbox não recebe emails

```bash
# Verificar se mailbox está ativa
# Verificar quota (se cheia, não recebe)
# Verificar logs
sudo docker compose logs dovecot-mailcow | grep "ryan.barbosa"
```

### Reset de Senha Esquecida

```bash
# Via Web UI: Configuration → Mailboxes → Edit → Reset Password
# Ou via CLI (Docker)
```

### Mailbox Corrompida

```bash
# Reconstruir índices Dovecot
sudo docker compose exec dovecot-mailcow \
  doveadm force-resync -u ryan.barbosa@fsociety.pt INBOX
```

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

<div align="center">

**[⬅️ Anterior: Configuração](02-configuracao.md)** | **[Índice](README.md)** | **[Próximo: Rspamd ➡️](04-rspamd.md)**

</div>

---

*Última atualização: Dezembro 2024*
