# 🎫 Integração com Zammad

> **Configuração da integração entre Mailcow e Zammad para sistema de tickets via email**

---

## 📋 Índice

1. [Sobre a Integração](#-sobre-a-integração)
2. [Conta de Email](#-conta-de-email)
3. [Configuração IMAP no Zammad](#-configuração-imap-no-zammad)
4. [Configuração SMTP no Zammad](#-configuração-smtp-no-zammad)
5. [Filtros e Regras](#-filtros-e-regras)
6. [Testes](#-testes)
7. [Monitorização](#-monitorização)

---

## 🔗 Sobre a Integração

O **Zammad** é o sistema de gestão de tickets da FSociety, integrado com Mailcow para receber e enviar tickets via email.

### Arquitetura

```
┌────────────────────────────────────────────────┐
│         Cliente Externo                        │
│    (envia email para tickets@fsociety.pt)      │
└───────────────┬────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────┐
│            MAILCOW (10.0.0.20)                 │
│                                                │
│  ┌──────────┐         ┌──────────┐            │
│  │ POSTFIX  │ ──────→ │ DOVECOT  │            │
│  │  (SMTP)  │         │  (IMAP)  │            │
│  └──────────┘         └─────┬────┘            │
│                             │                  │
└─────────────────────────────┼──────────────────┘
                              │ IMAP:993
                              │
                ┌─────────────▼─────────────┐
                │  ZAMMAD (192.168.1.40)    │
                │                           │
                │  ┌──────────────────┐     │
                │  │  Email Channel   │     │
                │  │  (IMAP/SMTP)     │     │
                │  └──────────────────┘     │
                │           │               │
                │           ▼               │
                │  ┌──────────────────┐     │
                │  │  Ticket System   │     │
                │  └──────────────────┘     │
                └───────────────────────────┘
                              │
                              ▼
                ┌───────────────────────────┐
                │  Notificação para Agente  │
                └───────────────────────────┘
```

### Fluxo de Funcionamento

1. Cliente envia email para `tickets@fsociety.pt`
2. Mailcow recebe email via Postfix
3. Email armazenado no Dovecot (IMAP)
4. Zammad consulta IMAP periodicamente
5. Novo ticket criado automaticamente no Zammad
6. Agente responde no Zammad
7. Resposta enviada via SMTP do Mailcow

---

## 📧 Conta de Email

### Criar Mailbox no Mailcow

A conta `tickets@fsociety.pt` já está criada com as seguintes especificações:

| Campo | Valor |
|-------|-------|
| **Email** | tickets@fsociety.pt |
| **Password** | `<senha_configurada>` |
| **Quota** | 20 GB |
| **Função** | Receção de tickets Zammad |
| **Domínio** | fsociety.pt |

### Configurações Recomendadas

```
Quota: 20 GB (alto volume de tickets)
Archiving: Ativado (retenção de histórico)
Spam Filter: Reduzido (para não bloquear tickets legítimos)
```

### Verificar Mailbox

```bash
# Via CLI Mailcow
sudo docker compose exec mysql-mailcow \
  mysql -u mailcow -p mailcow -e \
  "SELECT username, name, quota, active FROM mailbox WHERE username='tickets@fsociety.pt';"
```

**Resultado esperado:**
```
+----------------------+-------------------+-------+--------+
| username             | name              | quota | active |
+----------------------+-------------------+-------+--------+
| tickets@fsociety.pt  | Sistema Tickets   | 20480 | 1      |
+----------------------+-------------------+-------+--------+
```

---

## 📥 Configuração IMAP no Zammad

### Aceder às Configurações Zammad

1. **Login no Zammad:**
   - URL: https://zammad.fsociety.pt (via proxy nginx)
   - User: admin

2. **Navegar para Channels:**
   - Admin → Channels → Email

### Adicionar Email Account

**Tipo:** IMAP

### Configurações IMAP

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Inbound** | IMAP | Protocolo de receção |
| **Host** | mail.fsociety.pt | Hostname do Mailcow |
| **Port** | 993 | Porta IMAP SSL |
| **User** | tickets@fsociety.pt | Conta completa |
| **Password** | `<senha_configurada>` | Password da mailbox |
| **SSL/TLS** | SSL | Encriptação |
| **Folder** | INBOX | Pasta a monitorizar |

### Configuração JSON (Referência)

```json
{
  "adapter": "imap",
  "options": {
    "host": "mail.fsociety.pt",
    "port": 993,
    "ssl": true,
    "user": "tickets@fsociety.pt",
    "password": "SENHA_SEGURA",
    "folder": "INBOX",
    "keep_on_server": false,
    "ssl_verify": true
  }
}
```

### Opções Avançadas

```
Keep on Server: false (mover emails processados para pasta Zammad)
Trusted: Yes
Active: Yes
Fetch Interval: 5 minutes
```

### Teste de Conexão IMAP

Antes de configurar no Zammad, testar manualmente:

```bash
# Testar IMAP do servidor Zammad
openssl s_client -connect mail.fsociety.pt:993 -crlf

# Após conexão:
a1 LOGIN tickets@fsociety.pt SENHA_AQUI
a2 LIST "" "*"
a3 SELECT INBOX
a4 LOGOUT
```

---

## 📤 Configuração SMTP no Zammad

### Configurações SMTP

| Campo | Valor | Descrição |
|-------|-------|-----------|
| **Outbound** | SMTP | Protocolo de envio |
| **Host** | mail.fsociety.pt | Hostname do Mailcow |
| **Port** | 587 | Porta SMTP Submission |
| **User** | tickets@fsociety.pt | Conta completa |
| **Password** | `<senha_configurada>` | Password da mailbox |
| **Authentication** | Plain | Método de autenticação |
| **SSL/TLS** | STARTTLS | Encriptação |

### Configuração JSON (Referência)

```json
{
  "adapter": "smtp",
  "options": {
    "host": "mail.fsociety.pt",
    "port": 587,
    "start_tls": true,
    "user": "tickets@fsociety.pt",
    "password": "SENHA_SEGURA",
    "authentication": "plain"
  }
}
```

### Teste de Envio

```bash
# Testar SMTP manualmente
openssl s_client -connect mail.fsociety.pt:587 -starttls smtp

# Após conexão:
EHLO zammad.fsociety.pt
AUTH PLAIN <base64_credentials>
MAIL FROM:<tickets@fsociety.pt>
RCPT TO:<test@example.com>
DATA
Subject: Test

Test message
.
QUIT
```

### Verificar Envio no Zammad

1. **Admin → Channels → Email → Test**
2. Enviar email de teste
3. Verificar se chegou corretamente

---

## 🔧 Filtros e Regras

### Filtro Anti-Spam no Zammad

```ruby
# Ignorar emails com score alto de spam
if email.header['X-Spam-Status'] =~ /Yes/
  reject("Spam detected")
end
```

### Auto-Assignment

Configurar regras no Zammad para distribuir tickets:

```
Se: Email de cliente@empresa.com
Então: Atribuir a → ryan.barbosa@fsociety.pt

Se: Subject contém "urgente"
Então: 
  - Prioridade → Alta
  - Atribuir a → ti@fsociety.pt
```

### Configuração no Mailcow

#### Whitelist para tickets@fsociety.pt

```bash
# Desativar greylisting para tickets
sudo nano /opt/mailcow-dockerized/data/conf/rspamd/local.d/greylist.conf
```

```lua
whitelist_rcpt = [
  "tickets@fsociety.pt"
];
```

#### Reduzir Score Anti-spam

```bash
sudo nano /opt/mailcow-dockerized/data/conf/rspamd/local.d/multimap.conf
```

```lua
WHITELIST_TICKETS {
  type = "rcpt";
  map = "tickets@fsociety.pt";
  score = -5.0;
  description = "Whitelist para sistema de tickets";
}
```

---

## ✅ Testes

### Teste Completo de Integração

**1. Enviar Email de Teste**

```bash
# De outro servidor ou Gmail
echo "Teste de ticket" | mail -s "Ticket de Teste" tickets@fsociety.pt
```

**2. Verificar Receção no Mailcow**

```bash
# Ver logs do Postfix
sudo docker compose logs postfix-mailcow | grep tickets@fsociety.pt

# Verificar que email chegou ao Dovecot
sudo docker compose exec dovecot-mailcow \
  doveadm search -u tickets@fsociety.pt ALL
```

**3. Verificar Criação de Ticket no Zammad**

- Aceder ao Zammad Web UI
- Verificar se novo ticket foi criado
- Ticket ID: #12345
- Status: open

**4. Responder Ticket**

- Adicionar resposta no Zammad
- Verificar se email foi enviado via SMTP

**5. Verificar Logs de Envio**

```bash
# Ver logs SMTP do Mailcow
sudo docker compose logs postfix-mailcow | grep "from=<tickets@fsociety.pt>"
```

### Checklist de Verificação

- [ ] Email recebido no Mailcow
- [ ] Email processado pelo Zammad (ticket criado)
- [ ] Resposta enviada do Zammad via Mailcow
- [ ] Cliente recebeu resposta
- [ ] Thread de conversa mantida (In-Reply-To header)

---

## 📊 Monitorização

### Ver Status da Integração

**No Zammad:**
1. Admin → Channels → Email
2. Ver status da conexão IMAP/SMTP
3. Ver últimos emails processados

### Logs do Zammad

```bash
# No servidor Zammad (192.168.1.40)
tail -f /opt/zammad/log/production.log | grep -i "channel::email"
```

### Logs do Mailcow

```bash
# Logs IMAP (conexões do Zammad)
sudo docker compose logs dovecot-mailcow | grep tickets@fsociety.pt

# Logs SMTP (envios do Zammad)
sudo docker compose logs postfix-mailcow | grep "from=<tickets@fsociety.pt>"
```

### Métricas

```bash
# Emails na mailbox tickets
sudo docker compose exec dovecot-mailcow \
  doveadm mailbox status -u tickets@fsociety.pt messages INBOX

# Quota utilizada
sudo docker compose exec dovecot-mailcow \
  doveadm quota get -u tickets@fsociety.pt
```

### Alertas

Configurar alertas para:
- Mailbox próxima da quota (>80%)
- Falhas de conexão IMAP/SMTP
- Emails não processados (>30 min)

---

## 🔧 Troubleshooting

### Zammad não recebe emails

**Verificar:**
1. Conexão IMAP no Zammad
2. Logs do Zammad
3. Emails chegam ao Mailcow?
4. Firewall bloqueia 192.168.1.40 → 10.0.0.20:993?

```bash
# Testar conectividade do Zammad
# No servidor Zammad:
telnet mail.fsociety.pt 993
```

### Emails enviados vão para spam

**Verificar:**
1. SPF/DKIM/DMARC configurados
2. IP não em blacklist
3. Reverse DNS configurado

### Performance Lenta

**Otimizações:**
1. Aumentar intervalo de fetch (10 min em vez de 5 min)
2. Limpar emails antigos da mailbox
3. Aumentar quota se necessário

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

<div align="center">

**[⬅️ Anterior: Backup](08-backup.md)** | **[Índice](README.md)** | **[Próximo: Manutenção ➡️](10-manutencao.md)**

</div>

---

*Última atualização: Dezembro 2025*
