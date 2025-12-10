# 📱 Webmail SOGo

> **Interface webmail completa com calendário, contactos e ActiveSync para dispositivos móveis**

---

## 📋 Índice

1. [Sobre o SOGo](#-sobre-o-sogo)
2. [Acesso ao Webmail](#-acesso-ao-webmail)
3. [Interface e Funcionalidades](#-interface-e-funcionalidades)
4. [Calendário](#-calendário)
5. [Contactos](#-contactos)
6. [ActiveSync](#-activesync)
7. [Configuração de Clientes](#-configuração-de-clientes)
8. [Auto-configuração](#-auto-configuração)

---

## 🌐 Sobre o SOGo

**SOGo** (Scalable OpenGroupware.org) é um groupware open-source com webmail, calendário e contactos partilhados.

### Características

| Característica | Descrição |
|----------------|-----------|
| **Versão** | 1.136 (ghcr.io/mailcow/sogo) |
| **Webmail** | Interface moderna e responsiva |
| **Calendário** | CalDAV, iCal, múltiplos calendários |
| **Contactos** | CardDAV, vCard, grupos |
| **ActiveSync** | iOS, Android, Outlook |
| **Filtros** | Sieve filters (lado servidor) |
| **Partilha** | Calendários e contactos partilháveis |
| **Multi-idioma** | Português incluído |

### Protocolos Suportados

```
┌─────────────────────────────────────────────────┐
│                  SOGo WebUI                     │
│         https://mail.fsociety.pt/SOGo           │
└────────────────┬────────────────────────────────┘
                 │
       ┌─────────┼─────────┐
       │         │         │
       ▼         ▼         ▼
┌──────────┐ ┌──────┐ ┌──────────┐
│  Email   │ │ Cal  │ │Contactos │
│IMAP/SMTP │ │CalDAV│ │ CardDAV  │
└──────────┘ └──────┘ └──────────┘
       │         │         │
       └─────────┼─────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│           DOVECOT / POSTFIX                     │
└─────────────────────────────────────────────────┘
```

---

## 🔐 Acesso ao Webmail

### URL de Acesso

```
https://mail.fsociety.pt/SOGo
```

ou

```
https://mail.fsociety.pt (redireciona para /SOGo)
```

### Login

**Credenciais:**
- **Utilizador:** `ryan.barbosa@fsociety.pt` (endereço completo)
- **Password:** `<password_da_mailbox>`

### Interface Web

**Layout principal:**
```
┌────────────────────────────────────────────────────┐
│  SOGo - ryan.barbosa@fsociety.pt     [Sair] [⚙️]   │
├──────────┬─────────────────────────────────────────┤
│  📧 Mail  │   Inbox (12)                           │
│  📅 Cal   │   ┌─────────────────────────────────┐  │
│  👥 Cont  │   │ ✉️  De: Hugo Correia            │  │
│           │   │    Assunto: Reunião Projeto     │  │
│  Pastas:  │   │    Há 2 horas                   │  │
│  • Inbox  │   ├─────────────────────────────────┤  │
│  • Sent   │   │ ✉️  De: Igor Araújo             │  │
│  • Drafts │   │    Assunto: Update Mailcow      │  │
│  • Spam   │   │    Ontem às 15:30              │  │
│  • Trash  │   └─────────────────────────────────┘  │
└──────────┴─────────────────────────────────────────┘
```

---

## ✉️ Interface e Funcionalidades

### Email

#### Ler Emails

- **Inbox:** Caixa de entrada
- **Sent:** Emails enviados
- **Drafts:** Rascunhos
- **Spam/Junk:** Spam detetado
- **Trash:** Lixeira

#### Compor Email

1. Clicar em **"New Message"**
2. Preencher:
   - **To:** destinatário
   - **Cc:** cópia
   - **Bcc:** cópia oculta
   - **Subject:** assunto
   - **Body:** mensagem
3. **Anexar ficheiros** (arrasta ou clica)
4. **Enviar** ou **Guardar como rascunho**

#### Filtros de Email (Sieve)

1. **Preferences → Filters**
2. **Criar regra:**

```
Se: Subject contém "spam"
Então: Mover para pasta "Spam"
```

**Exemplo de regra Sieve:**
```sieve
require ["fileinto"];
if header :contains "Subject" "[SPAM]" {
  fileinto "Spam";
  stop;
}
```

#### Pesquisa Avançada

```
Pesquisar por:
- Remetente (From)
- Destinatário (To)
- Assunto (Subject)
- Corpo (Body)
- Data
- Anexos
```

---

## 📅 Calendário

### Criar Calendário

1. Clicar em **Calendar**
2. **➕ New Calendar**
3. Preencher:
   - **Name:** "Trabalho"
   - **Color:** Azul
   - **Type:** Events

### Criar Evento

1. **New Event**
2. Preencher:
   - **Title:** Reunião de Projeto
   - **Location:** Sala 2
   - **Start:** 2025-12-10 14:00
   - **End:** 2025-12-10 16:00
   - **Repeat:** Não
   - **Reminder:** 15 minutos antes

### Partilhar Calendário

1. **Botão direito no calendário** → **Sharing**
2. **Add users:**
   - hugo.correia@fsociety.pt (Read/Write)
   - igor.araujo@fsociety.pt (Read only)

### Subscrever Calendário (CalDAV)

**URL CalDAV:**
```
https://mail.fsociety.pt/SOGo/dav/ryan.barbosa@fsociety.pt/Calendar/personal/
```

**Configurar em cliente (Apple Calendar, Thunderbird):**
- Server: `mail.fsociety.pt`
- Port: `443`
- Path: `/SOGo/dav/ryan.barbosa@fsociety.pt/Calendar/personal/`
- User: `ryan.barbosa@fsociety.pt`
- Pass: `<password>`

---

## 👥 Contactos

### Criar Contacto

1. **Contacts** → **New Contact**
2. Preencher:
   - **First Name:** Hugo
   - **Last Name:** Correia
   - **Email:** hugo.correia@fsociety.pt
   - **Phone:** +351 912 345 678
   - **Company:** FSociety

### Criar Lista de Contactos

1. **New List**
2. **Name:** Equipa TI
3. **Adicionar membros:**
   - hugo.correia@fsociety.pt
   - ryan.barbosa@fsociety.pt
   - igor.araujo@fsociety.pt

### Subscrever Contactos (CardDAV)

**URL CardDAV:**
```
https://mail.fsociety.pt/SOGo/dav/ryan.barbosa@fsociety.pt/Contacts/personal/
```

---

## 📱 ActiveSync

ActiveSync permite sincronização nativa com dispositivos móveis (iOS, Android).

### Configurar no iPhone/iPad

1. **Settings → Mail → Accounts → Add Account**
2. **Exchange** (não "Other")
3. Preencher:

| Campo | Valor |
|-------|-------|
| **Email** | ryan.barbosa@fsociety.pt |
| **Server** | mail.fsociety.pt |
| **Domain** | (deixar vazio) |
| **Username** | ryan.barbosa@fsociety.pt |
| **Password** | `<password>` |

4. **Ativar:**
   - ✅ Mail
   - ✅ Contacts
   - ✅ Calendars
   - ✅ Reminders
   - ✅ Notes

### Configurar no Android

1. **Settings → Accounts → Add Account**
2. **Exchange / Corporate**
3. **Email:** ryan.barbosa@fsociety.pt
4. **Password:** `<password>`
5. **Server:** mail.fsociety.pt
6. **Domain:** (vazio)
7. **Username:** ryan.barbosa@fsociety.pt

### Verificar ActiveSync

```bash
# Ver conexões ActiveSync ativas
sudo docker compose exec sogo-mailcow \
  sogo-tool dump-defaults -f /etc/sogo/sogo.conf

# Logs ActiveSync
sudo docker compose logs sogo-mailcow | grep -i activesync
```

---

## 💻 Configuração de Clientes

### Thunderbird (Desktop)

#### Email (IMAP)

1. **Menu → Account Settings → Account Actions → Add Mail Account**
2. Preencher:
   - **Your name:** Ryan Barbosa
   - **Email:** ryan.barbosa@fsociety.pt
   - **Password:** `<password>`
3. **Manual config:**

| Tipo | Servidor | Porta | SSL | Autenticação |
|------|----------|-------|-----|--------------|
| IMAP | mail.fsociety.pt | 993 | SSL/TLS | Normal password |
| SMTP | mail.fsociety.pt | 587 | STARTTLS | Normal password |

#### Calendário (Lightning/Thunderbird)

1. **Calendar → New Calendar → On the Network**
2. **Format:** CalDAV
3. **Location:** `https://mail.fsociety.pt/SOGo/dav/ryan.barbosa@fsociety.pt/Calendar/personal/`
4. **Username:** ryan.barbosa@fsociety.pt

### Apple Mail (macOS)

#### Adicionar Conta

1. **Mail → Settings → Accounts → Add Account**
2. **Add Other Mail Account**
3. Preencher dados, Mail deteta automaticamente IMAP/SMTP

#### Configuração Manual

```
Incoming (IMAP):
  Server: mail.fsociety.pt
  Port: 993
  TLS: Yes
  Username: ryan.barbosa@fsociety.pt

Outgoing (SMTP):
  Server: mail.fsociety.pt
  Port: 587
  TLS: Yes (STARTTLS)
  Username: ryan.barbosa@fsociety.pt
```

### Outlook (Desktop)

1. **File → Add Account**
2. **Advanced options** → Let me set up my account manually
3. **IMAP**
4. Preencher configurações (igual Thunderbird)

---

## 🔧 Auto-configuração

O Mailcow fornece auto-configuração para clientes de email.

### Autodiscover (Outlook)

**URL:** `https://mail.fsociety.pt/autodiscover/autodiscover.xml`

**DNS necessário:**
```
autodiscover.fsociety.pt.  A  188.81.65.191
```

### Autoconfig (Thunderbird/Mozilla)

**URL:** `https://mail.fsociety.pt/.well-known/autoconfig/mail/config-v1.1.xml`

**DNS necessário:**
```
autoconfig.fsociety.pt.  A  188.81.65.191
```

### Testar Auto-configuração

---
        
## 📹 Demonstração

O vídeo abaixo demonstra a configuração automática de clientes de email 
via Autodiscover, incluindo a validação do reverse proxy e resposta do 
servidor:

https://github.com/user-attachments/assets/cffd3332-ec0d-40e0-b99f-9b78c31445ed

---

**Thunderbird:**
1. Adicionar conta apenas com email e password
2. Thunderbird deteta automaticamente via autoconfig

**Outlook:**
1. Adicionar conta Exchange
2. Email: ryan.barbosa@fsociety.pt
3. Outlook consulta autodiscover

### Verificar Configuração

```bash
# Testar autodiscover
curl https://mail.fsociety.pt/autodiscover/autodiscover.xml

# Testar autoconfig
curl https://mail.fsociety.pt/.well-known/autoconfig/mail/config-v1.1.xml
```

---

## ⚙️ Configurações Avançadas

### Assinatura de Email

1. **Preferences → Mail → Signatures**
2. **Add signature:**

```
---
Ryan Barbosa
Administrador de Sistemas
FSociety.pt
Email: ryan.barbosa@fsociety.pt
Tel: +351 912 345 678
```

### Resposta Automática (Férias)

1. **Preferences → Mail → Vacation**
2. **Enable vacation auto-reply**
3. **Subject:** Ausente do escritório
4. **Message:**
```
Olá,

Estou ausente até 15/12/2024.
Emails urgentes: ti@fsociety.pt

Cumprimentos,
Ryan Barbosa
```

### Quotas

Ver uso de quota:
- **Preferences → General**
- Barra de progresso mostra uso atual

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

**[⬅️ Anterior: Antivírus](05-antivirus.md)** | **[Índice](README.md)** | **[Próximo: Registos DNS ➡️](07-dns-records.md)**

</div>

---

*Última atualização: Dezembro 2025*
