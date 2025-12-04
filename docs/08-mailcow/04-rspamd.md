# 🛡️ Rspamd - Anti-spam

> **Configuração e gestão do Rspamd, sistema avançado de filtragem anti-spam e anti-phishing**

---

## 📋 Índice

1. [Sobre o Rspamd](#-sobre-o-rspamd)
2. [Acesso ao Dashboard](#-acesso-ao-dashboard)
3. [Configuração Inicial](#-configuração-inicial)
4. [Estatísticas e Métricas](#-estatísticas-e-métricas)
5. [Regras e Scores](#-regras-e-scores)
6. [Bayesian Learning](#-bayesian-learning)
7. [Whitelists e Blacklists](#-whitelists-e-blacklists)
8. [Greylisting](#-greylisting)
9. [DKIM, SPF, DMARC](#-dkim-spf-dmarc)

---

## 📊 Sobre o Rspamd

O **Rspamd** é um sistema de filtragem de email rápido e modular que substitui soluções como SpamAssassin.

### Características Principais

| Característica | Descrição |
|----------------|-----------|
| **Versão** | 3.13.2 |
| **Performance** | Processa milhares de emails/segundo |
| **Bayesian Filter** | Aprendizagem automática HAM/SPAM |
| **DKIM Signing** | Assina emails automaticamente |
| **SPF/DMARC Check** | Valida autenticidade dos remetentes |
| **Greylisting** | Atraso temporário para combater bots |
| **Neural Networks** | Machine learning avançado |
| **Web UI** | Interface gráfica para gestão |

### Arquitetura no Mailcow

```
┌──────────────────────────────────────────────────┐
│              POSTFIX (SMTP)                      │
│          Recebe email externo                    │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│              RSPAMD                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │Bayesian  │  │ SPF/DKIM │  │ RBL/URIBL│       │
│  │ Filter   │  │  Check   │  │  Lookup  │       │
│  └──────────┘  └──────────┘  └──────────┘       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │Greylisti │  │ Phishing │  │  Neural  │       │
│  │   ng     │  │ Detection│  │ Network  │       │
│  └──────────┘  └──────────┘  └──────────┘       │
│                                                  │
│  Score: -5 (HAM) ... 0 ... +15 (SPAM)           │
└────────────────┬─────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
┌──────────┐          ┌──────────┐
│ ACCEPT   │          │ REJECT   │
│ (Inbox)  │          │ (Bounce) │
└──────────┘          └──────────┘
```

---

## 🌐 Acesso ao Dashboard

### URL de Acesso

```
https://mail.fsociety.pt/rspamd
```

### Configurar Password (Primeira Vez)

1. **Gerar hash da password:**

```bash
cd /opt/mailcow-dockerized

# Gerar hash
sudo docker compose exec rspamd-mailcow \
  rspamadm pw --encrypt -p 'SuaPasswordSegura123!'
```

**Saída exemplo:**
```
$2$xu7zj3ykd1cg5qy1emkhgrgw4j3c7r8g$...
```

2. **Adicionar ao override:**

```bash
sudo nano data/conf/rspamd/override.d/worker-controller.inc
```

**Conteúdo:**
```
password = "$2$xu7zj3ykd1cg5qy1emkhgrgw4j3c7r8g$...";
enable_password = "$2$xu7zj3ykd1cg5qy1emkhgrgw4j3c7r8g$...";
```

3. **Reiniciar Rspamd:**

```bash
sudo docker compose restart rspamd-mailcow
```

4. **Fazer login:**
   - URL: https://mail.fsociety.pt/rspamd
   - Password: `SuaPasswordSegura123!`

---

## ⚙️ Configuração Inicial

### Estrutura de Configuração

```
/opt/mailcow-dockerized/data/conf/rspamd/
├── local.d/          # Configurações locais (preferencial)
├── override.d/       # Overrides totais
├── custom/           # Módulos customizados
└── rspamd.conf.local # Configuração principal
```

### Configuração Recomendada

```bash
# Criar configurações locais
sudo nano data/conf/rspamd/local.d/options.inc
```

**Conteúdo:**
```
# DNS servers
dns {
  nameserver = ["192.168.1.10:53", "1.1.1.1:53"];
  timeout = 2s;
  retransmits = 3;
}

# Local networks (não analisar)
local_addrs = "192.168.1.0/24, 10.0.0.0/24";
```

### Ajustar Thresholds

```bash
sudo nano data/conf/rspamd/local.d/actions.conf
```

**Valores FSociety:**
```
actions {
  # Score abaixo de -5: definitivamente não é spam
  greylist = 4;
  
  # Score 4-6: greylisting (atraso temporário)
  add_header = 6;
  
  # Score 6-15: adiciona header X-Spam: Yes
  rewrite_subject = 8;
  
  # Score 8-15: reescreve subject com [SPAM]
  reject = 15;
  
  # Score acima de 15: rejeita email
}
```

**Aplicar:**
```bash
sudo docker compose restart rspamd-mailcow
```

---

## 📈 Estatísticas e Métricas

### Dashboard Web

Aceder a https://mail.fsociety.pt/rspamd → **History**

### Métricas Atuais FSociety

| Métrica | Valor | Percentagem |
|---------|-------|-------------|
| **Uptime** | 1hr+ | - |
| **Emails Scanned** | 19 | 100% |
| **Clean (No Action)** | 12 | 63% |
| **Greylist** | 7 | 37% |
| **Soft Reject** | 0 | 0% |
| **Rejected** | 0 | 0% |
| **Bayesian HAM** | 2 | - |
| **Bayesian SPAM** | 0 | - |

### Ver Estatísticas via CLI

```bash
# Stats gerais
sudo docker compose exec rspamd-mailcow \
  rspamadm stats

# Stats de um período
sudo docker compose exec rspamd-mailcow \
  rspamadm stats --reset
```

### Logs em Tempo Real

```bash
# Ver logs do Rspamd
sudo docker compose logs -f rspamd-mailcow

# Filtrar por email específico
sudo docker compose logs rspamd-mailcow | grep "ryan.barbosa@fsociety.pt"
```

---

## 🎯 Regras e Scores

### Como Funciona o Scoring

Cada email recebe um **score** baseado em múltiplas regras:

- **Score negativo** (-5 a 0): Email legítimo (HAM)
- **Score baixo** (0 a 4): Provavelmente legítimo
- **Score médio** (4 a 6): Suspeito (greylisting)
- **Score alto** (6 a 15): Provável spam (marcar)
- **Score muito alto** (15+): Definitivamente spam (rejeitar)

### Ver Símbolos/Regras Ativas

```bash
# Listar todos os símbolos
sudo docker compose exec rspamd-mailcow \
  rspamadm configdump -m symbols | less

# Ver configuração de módulo específico
sudo docker compose exec rspamd-mailcow \
  rspamadm configdump dkim
```

### Ajustar Score de Regra Específica

```bash
# Exemplo: aumentar peso de DKIM_ALLOW
sudo nano data/conf/rspamd/local.d/groups.conf
```

```
symbols {
  "DKIM_ALLOW" {
    weight = -2.0;  # Default é -0.2
    description = "Email com DKIM válido";
  }
  
  "SPF_FAIL" {
    weight = 5.0;   # Aumentar penalização
  }
}
```

### Principais Regras/Símbolos

| Símbolo | Score | Descrição |
|---------|-------|-----------|
| DKIM_ALLOW | -0.2 | DKIM signature válida |
| SPF_ALLOW | -0.2 | SPF pass |
| DMARC_POLICY_ALLOW | -0.5 | DMARC pass |
| BAYES_HAM | -3.0 | Bayesian classificou como HAM |
| BAYES_SPAM | +5.0 | Bayesian classificou como SPAM |
| RBL_SPAMHAUS | +2.0 | IP em RBL Spamhaus |
| PHISHING | +8.0 | Deteção de phishing |
| FORGED_RECIPIENTS | +5.0 | Recipientes falsificados |

---

## 🧠 Bayesian Learning

O filtro Bayesiano aprende com os emails classificados como HAM ou SPAM.

### Estado Atual

```
HAM learned: 2 emails
SPAM learned: 0 emails
```

### Treinar Manualmente

**Via Web UI:**
1. Aceder a https://mail.fsociety.pt/rspamd
2. **Learning** → **Learn spam** ou **Learn ham**
3. Colar conteúdo do email
4. Submeter

**Via CLI:**

```bash
# Aprender HAM (email legítimo)
sudo docker compose exec rspamd-mailcow \
  rspamc learn_ham /path/to/email.eml

# Aprender SPAM
sudo docker compose exec rspamd-mailcow \
  rspamc learn_spam /path/to/spam.eml

# Aprender de mailbox inteira
sudo docker compose exec rspamd-mailcow \
  rspamc learn_ham /var/vmail/fsociety.pt/ryan.barbosa/Maildir/cur/*
```

### Auto-learning

Rspamd aprende automaticamente com emails de alta/baixa confiança:

```bash
sudo nano data/conf/rspamd/local.d/classifier-bayes.conf
```

```
autolearn {
  # Aprender como SPAM se score > 10
  spam_threshold = 10.0;
  
  # Aprender como HAM se score < -5
  ham_threshold = -5.0;
}
```

### Ver Estatísticas Bayesian

```bash
sudo docker compose exec rspamd-mailcow \
  rspamadm statfile
```

---

## 📝 Whitelists e Blacklists

### Whitelist de Domínios

```bash
sudo nano data/conf/rspamd/local.d/whitelist.conf
```

```
rules {
  WHITELIST_DOMAIN {
    valid_spf = true;
    domains = [
      "google.com",
      "microsoft.com",
      "estg.ipp.pt"
    ];
    score = -10.0;
  }
}
```

### Whitelist de IPs

```bash
sudo nano data/conf/rspamd/local.d/ip_score.conf
```

```
servers = "127.0.0.1:6379";  # Redis

# Whitelist manual
whitelist {
  "192.168.1.0/24" {
    score = -10.0;
  }
}
```

### Blacklist de Remetentes

```bash
sudo nano data/conf/rspamd/local.d/multimap.conf
```

```
BLACKLIST_FROM {
  type = "from";
  map = "/etc/rspamd/custom/blacklist_from.map";
  score = 15.0;
  description = "Blacklist de remetentes";
}
```

```bash
# Criar ficheiro
sudo nano data/conf/rspamd/custom/blacklist_from.map
```

```
spam@example.com
/.*@spammer\.com$/
```

---

## ⏳ Greylisting

Greylisting adiciona um atraso temporário para combater spambots.

### Estado Atual

```
Greylisted: 7 emails (37%)
```

### Configurar Greylisting

```bash
sudo nano data/conf/rspamd/local.d/greylist.conf
```

```
# Tempo de greylisting
timeout = 300s;  # 5 minutos

# Tempo de expiração
expire = 1d;     # 1 dia

# Whitelist após N passagens bem-sucedidas
whitelist_after = 3;

# Não aplicar greylisting a IPs conhecidos
whitelist_ip = [
  "192.168.1.0/24",
  "10.0.0.0/24"
];

# Não aplicar a domínios confiáveis
whitelist_domains = [
  "google.com",
  "microsoft.com"
];
```

### Ver Greylisted IPs

```bash
# Redis armazena greylisting
sudo docker compose exec redis-mailcow redis-cli

# Listar chaves greylisting
keys greylist:*
```

---

## 🔐 DKIM, SPF, DMARC

### DKIM Signing

Rspamd assina automaticamente emails enviados:

```bash
# Ver chaves DKIM do domínio
sudo ls -la data/dkim/

# Ver chave pública
sudo cat data/dkim/fsociety.pt.dkim
```

### Verificar DKIM em Email Enviado

```bash
# Headers devem conter:
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; 
  d=fsociety.pt; s=dkim; ...
```

### SPF Check

```bash
# Rspamd verifica SPF automaticamente
# Ver resultado no header:
Received-SPF: pass
```

### DMARC Reporting

```bash
sudo nano data/conf/rspamd/local.d/dmarc.conf
```

```
# Enviar relatórios DMARC
reporting {
  enabled = true;
  email = "postmaster@fsociety.pt";
  from_name = "FSociety DMARC";
}
```

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

**[⬅️ Anterior: Domínios e Mailboxes](03-dominios-mailboxes.md)** | **[Índice](README.md)** | **[Próximo: Antivírus ➡️](05-antivirus.md)**

</div>

---

*Última atualização: Dezembro 2025*
