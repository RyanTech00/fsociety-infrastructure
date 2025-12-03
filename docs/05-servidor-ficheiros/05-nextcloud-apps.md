# 📱 Nextcloud - Apps Instaladas

> **Catálogo completo das 65+ apps instaladas no Nextcloud, organizadas por categoria**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Produtividade](#-produtividade)
3. [Colaboração](#-colaboração)
4. [Ficheiros e Multimédia](#-ficheiros-e-multimédia)
5. [Segurança e Autenticação](#-segurança-e-autenticação)
6. [Integração Externa](#-integração-externa)
7. [Comunicação](#-comunicação)
8. [Gestão e Administração](#-gestão-e-administração)
9. [Personalização](#-personalização)
10. [Comandos de Gestão](#-comandos-de-gestão)
11. [Referências](#-referências)

---

## 📊 Visão Geral

### Estatísticas

| Métrica | Valor |
|---------|-------|
| **Total de Apps** | 65+ |
| **Apps Ativas** | 60+ |
| **Apps Desativadas** | ~5 |
| **Espaço Utilizado** | ~200 MB |

### Listar Apps

```bash
# Listar todas as apps
sudo -u www-data php /var/www/nextcloud/occ app:list

# Apenas apps ativadas
sudo -u www-data php /var/www/nextcloud/occ app:list --enabled

# Apenas apps desativadas
sudo -u www-data php /var/www/nextcloud/occ app:list --disabled
```

---

## 📝 Produtividade

### Calendar
**Versão:** Latest  
**Descrição:** Gestão de calendários com suporte CalDAV  
**Funcionalidades:**
- Múltiplos calendários
- Partilha com utilizadores e grupos
- Eventos recorrentes
- Lembretes e notificações
- Integração com Talk para videochamadas

```bash
# Instalar
sudo -u www-data php /var/www/nextcloud/occ app:install calendar
sudo -u www-data php /var/www/nextcloud/occ app:enable calendar
```

### Contacts
**Descrição:** Gestão de contactos com suporte CardDAV  
**Funcionalidades:**
- Contactos organizados por grupos
- Partilha de contactos
- Sincronização com clientes CardDAV
- Importação/exportação vCard

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install contacts
sudo -u www-data php /var/www/nextcloud/occ app:enable contacts
```

### Deck
**Descrição:** Quadros Kanban para gestão de projetos  
**Funcionalidades:**
- Boards, Lists e Cards
- Tags e labels
- Datas de vencimento
- Anexos e comentários
- Atribuição a utilizadores

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install deck
sudo -u www-data php /var/www/nextcloud/occ app:enable deck
```

### Notes
**Descrição:** Editor de notas com sintaxe Markdown  
**Funcionalidades:**
- Editor markdown
- Categorias
- Favoritos
- Sincronização com apps móveis

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install notes
sudo -u www-data php /var/www/nextcloud/occ app:enable notes
```

### Tasks
**Descrição:** Gestão de tarefas com suporte CalDAV  
**Funcionalidades:**
- Listas de tarefas
- Sub-tarefas
- Prioridades
- Datas de vencimento
- Tags

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install tasks
sudo -u www-data php /var/www/nextcloud/occ app:enable tasks
```

### Forms
**Descrição:** Criador de formulários  
**Funcionalidades:**
- Criação de forms personalizados
- Múltiplos tipos de perguntas
- Respostas anónimas ou identificadas
- Exportação para CSV
- Partilha pública

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install forms
sudo -u www-data php /var/www/nextcloud/occ app:enable forms
```

### Polls
**Descrição:** Criação de inquéritos e votações  
**Funcionalidades:**
- Votações de datas (tipo Doodle)
- Inquéritos de opinião
- Respostas anónimas
- Resultados em tempo real

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install polls
sudo -u www-data php /var/www/nextcloud/occ app:enable polls
```

---

## 👥 Colaboração

### Spreed (Talk)
**Descrição:** Videochamadas, chat e conferências  
**Funcionalidades:**
- Videochamadas 1:1 e em grupo
- Chat de texto
- Partilha de ecrã
- Gravação de chamadas
- Integração com Calendar

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install spreed
sudo -u www-data php /var/www/nextcloud/occ app:enable spreed
```

### Mail
**Descrição:** Cliente de email integrado  
**Funcionalidades:**
- Suporte IMAP/SMTP
- Múltiplas contas
- Filtros e pastas
- Assinaturas
- Integração com Contacts

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install mail
sudo -u www-data php /var/www/nextcloud/occ app:enable mail
```

### Group Folders
**Descrição:** Pastas partilhadas por grupos  
**Funcionalidades:**
- Pastas dedicadas a grupos AD
- Quotas por pasta
- Controlo de acesso granular
- Advanced permissions

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install groupfolders
sudo -u www-data php /var/www/nextcloud/occ app:enable groupfolders
```

### Circles
**Descrição:** Grupos privados de utilizadores  
**Funcionalidades:**
- Criar círculos de colaboração
- Partilhar ficheiros com círculos
- Membros internos e externos
- Níveis de permissões

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install circles
sudo -u www-data php /var/www/nextcloud/occ app:enable circles
```

---

## 📁 Ficheiros e Multimédia

### Files Markdown Editor
**Descrição:** Editor markdown para ficheiros .md  
**Funcionalidades:**
- Sintaxe highlighting
- Preview em tempo real
- Suporte GitHub Flavored Markdown

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install files_markdown
sudo -u www-data php /var/www/nextcloud/occ app:enable files_markdown
```

### Files PDF Viewer
**Descrição:** Visualizador de PDFs integrado  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install files_pdfviewer
sudo -u www-data php /var/www/nextcloud/occ app:enable files_pdfviewer
```

### Photos
**Descrição:** Galeria de fotos com reconhecimento facial  
**Funcionalidades:**
- Timeline de fotos
- Álbuns
- Reconhecimento facial (opcional)
- Metadados EXIF
- Geolocalização

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install photos
sudo -u www-data php /var/www/nextcloud/occ app:enable photos
```

### Bookmarks
**Descrição:** Gestor de favoritos/marcadores  
**Funcionalidades:**
- Organização por pastas
- Tags
- Importação de bookmarks
- Partilha pública

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install bookmarks
sudo -u www-data php /var/www/nextcloud/occ app:enable bookmarks
```

### Music
**Descrição:** Reprodutor de música  
**Funcionalidades:**
- Player integrado
- Playlists
- Biblioteca organizada por artista/álbum
- Subsonic API

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install music
sudo -u www-data php /var/www/nextcloud/occ app:enable music
```

### Files Automated Tagging
**Descrição:** Tagging automático de ficheiros  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install files_automatedtagging
sudo -u www-data php /var/www/nextcloud/occ app:enable files_automatedtagging
```

### Files Access Control
**Descrição:** Controlo de acesso baseado em regras  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install files_accesscontrol
sudo -u www-data php /var/www/nextcloud/occ app:enable files_accesscontrol
```

---

## 🔐 Segurança e Autenticação

### Two-Factor TOTP
**Descrição:** Autenticação de dois fatores via TOTP  
**Funcionalidades:**
- Google Authenticator, Authy, etc.
- QR Code setup
- Códigos de backup

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_totp
sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_totp
```

### Two-Factor Backup Codes
**Descrição:** Códigos de recuperação para 2FA  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_backupcodes
sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_backupcodes
```

### Suspicious Login
**Descrição:** Deteção de logins suspeitos via ML  
**Funcionalidades:**
- Machine learning
- Deteção de anomalias
- Notificações de alerta

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install suspicious_login
sudo -u www-data php /var/www/nextcloud/occ app:enable suspicious_login
```

### Brute-force Settings
**Descrição:** Proteção contra ataques brute-force  
```bash
# Já vem instalado por defeito
sudo -u www-data php /var/www/nextcloud/occ app:enable bruteforcesettings
```

### User LDAP
**Descrição:** Integração com LDAP/Active Directory  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install user_ldap
sudo -u www-data php /var/www/nextcloud/occ app:enable user_ldap
```

---

## 🔌 Integração Externa

### Richdocuments (Collabora Online)
**Descrição:** Editor de documentos Office online  
**Funcionalidades:**
- Word, Excel, PowerPoint online
- Edição colaborativa em tempo real
- Suporte formatos MS Office e ODF

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install richdocuments
sudo -u www-data php /var/www/nextcloud/occ app:enable richdocuments
```

### Integration Overleaf
**Descrição:** Integração com Overleaf (LaTeX)  
**Funcionalidades:**
- Abrir .tex files no Overleaf
- Sincronização bidirecional

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install integration_overleaf
sudo -u www-data php /var/www/nextcloud/occ app:enable integration_overleaf
```

### External Sites
**Descrição:** Adicionar sites externos ao menu  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install external
sudo -u www-data php /var/www/nextcloud/occ app:enable external
```

### External Storage
**Descrição:** Suporte para storage externo  
**Funcionalidades:**
- SMB/CIFS
- FTP/SFTP
- WebDAV
- S3/Swift

```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable files_external
```

---

## 💬 Comunicação

### Appointments
**Descrição:** Marcação de reuniões (tipo Calendly)  
**Funcionalidades:**
- Slots de disponibilidade
- Reservas públicas
- Integração com Calendar
- Notificações email

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install appointments
sudo -u www-data php /var/www/nextcloud/occ app:enable appointments
```

### Announcement Center
**Descrição:** Publicação de anúncios centralizados  
**Funcionalidades:**
- Anúncios para todos os utilizadores
- Grupos específicos
- Notificações
- Comentários

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install announcementcenter
sudo -u www-data php /var/www/nextcloud/occ app:enable announcementcenter
```

---

## ⚙️ Gestão e Administração

### Timemanager
**Descrição:** Gestão de tempo e timetracking  
**Funcionalidades:**
- Tracking de horas
- Projetos e clientes
- Relatórios
- Exportação

```bash
sudo -u www-data php /var/www/nextcloud/occ app:install timemanager
sudo -u www-data php /var/www/nextcloud/occ app:enable timemanager
```

### Activity
**Descrição:** Log de atividades dos utilizadores  
```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable activity
```

### Notifications
**Descrição:** Sistema de notificações  
```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable notifications
```

### Admin Audit
**Descrição:** Auditoria de ações administrativas  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install admin_audit
sudo -u www-data php /var/www/nextcloud/occ app:enable admin_audit
```

### Files Retention
**Descrição:** Políticas de retenção de ficheiros  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install files_retention
sudo -u www-data php /var/www/nextcloud/occ app:enable files_retention
```

### Quota Warning
**Descrição:** Avisos de quota  
```bash
sudo -u www-data php /var/www/nextcloud/occ app:install quota_warning
sudo -u www-data php /var/www/nextcloud/occ app:enable quota_warning
```

---

## 🎨 Personalização

### Theming
**Descrição:** Personalização do tema  
**Funcionalidades:**
- Logo personalizado
- Cores
- Slogan
- Background

```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable theming
```

### Accessibility
**Descrição:** Melhorias de acessibilidade  
```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable accessibility
```

### Dashboard
**Descrição:** Dashboard personalizável  
```bash
# Já vem instalado
sudo -u www-data php /var/www/nextcloud/occ app:enable dashboard
```

---

## 🛠️ Comandos de Gestão

### Instalar App

```bash
# Via repositório oficial
sudo -u www-data php /var/www/nextcloud/occ app:install <app_name>

# Ativar
sudo -u www-data php /var/www/nextcloud/occ app:enable <app_name>
```

### Desinstalar App

```bash
# Desativar
sudo -u www-data php /var/www/nextcloud/occ app:disable <app_name>

# Remover
sudo -u www-data php /var/www/nextcloud/occ app:remove <app_name>
```

### Atualizar Apps

```bash
# Atualizar todas as apps
sudo -u www-data php /var/www/nextcloud/occ app:update --all

# Atualizar app específica
sudo -u www-data php /var/www/nextcloud/occ app:update <app_name>
```

### Listar Apps Disponíveis

```bash
# Apps disponíveis na app store
sudo -u www-data php /var/www/nextcloud/occ app:list --shipped=false
```

---

## 📊 Apps por Categoria - Resumo

### Produtividade (7 apps)
- calendar, contacts, deck, notes, tasks, forms, polls

### Colaboração (4 apps)
- spreed, mail, groupfolders, circles

### Ficheiros (7 apps)
- files_markdown, files_pdfviewer, photos, bookmarks, music, files_automatedtagging, files_accesscontrol

### Segurança (5 apps)
- twofactor_totp, twofactor_backupcodes, suspicious_login, bruteforcesettings, user_ldap

### Integração (4 apps)
- richdocuments, integration_overleaf, external, files_external

### Comunicação (2 apps)
- appointments, announcementcenter

### Gestão (6 apps)
- timemanager, activity, notifications, admin_audit, files_retention, quota_warning

### Personalização (3 apps)
- theming, accessibility, dashboard

---

## 🔄 Script de Instalação Completa

```bash
#!/bin/bash

# Produtividade
sudo -u www-data php /var/www/nextcloud/occ app:install calendar
sudo -u www-data php /var/www/nextcloud/occ app:install contacts
sudo -u www-data php /var/www/nextcloud/occ app:install deck
sudo -u www-data php /var/www/nextcloud/occ app:install notes
sudo -u www-data php /var/www/nextcloud/occ app:install tasks
sudo -u www-data php /var/www/nextcloud/occ app:install forms
sudo -u www-data php /var/www/nextcloud/occ app:install polls

# Colaboração
sudo -u www-data php /var/www/nextcloud/occ app:install spreed
sudo -u www-data php /var/www/nextcloud/occ app:install mail
sudo -u www-data php /var/www/nextcloud/occ app:install groupfolders
sudo -u www-data php /var/www/nextcloud/occ app:install circles

# Ficheiros
sudo -u www-data php /var/www/nextcloud/occ app:install files_markdown
sudo -u www-data php /var/www/nextcloud/occ app:install files_pdfviewer
sudo -u www-data php /var/www/nextcloud/occ app:install photos
sudo -u www-data php /var/www/nextcloud/occ app:install bookmarks
sudo -u www-data php /var/www/nextcloud/occ app:install music

# Segurança
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_totp
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_backupcodes
sudo -u www-data php /var/www/nextcloud/occ app:install suspicious_login
sudo -u www-data php /var/www/nextcloud/occ app:install user_ldap

# Integração
sudo -u www-data php /var/www/nextcloud/occ app:install richdocuments
sudo -u www-data php /var/www/nextcloud/occ app:install integration_overleaf
sudo -u www-data php /var/www/nextcloud/occ app:install external

# Comunicação
sudo -u www-data php /var/www/nextcloud/occ app:install appointments
sudo -u www-data php /var/www/nextcloud/occ app:install announcementcenter

# Gestão
sudo -u www-data php /var/www/nextcloud/occ app:install timemanager
sudo -u www-data php /var/www/nextcloud/occ app:install admin_audit

echo "Apps instaladas com sucesso!"
```

---

## 📖 Referências

- [Nextcloud App Store](https://apps.nextcloud.com/)
- [Nextcloud Apps Documentation](https://docs.nextcloud.com/server/latest/admin_manual/apps_management.html)
- [OCC App Commands](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#apps-commands)

---

<div align="center">

**[⬅️ Voltar: LDAP](04-nextcloud-ldap.md)** | **[Próximo: Zammad ➡️](06-zammad.md)**

</div>

---

*Última atualização: Dezembro 2024*
