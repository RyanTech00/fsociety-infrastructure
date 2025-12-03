# 🌐 Registos DNS

> **Configuração completa dos registos DNS necessários para funcionamento do email**

---

## 📋 Índice

1. [Registos Essenciais](#-registos-essenciais)
2. [Registo A](#-registo-a)
3. [Registo MX](#-registo-mx)
4. [Registo PTR (Reverse DNS)](#-registo-ptr-reverse-dns)
5. [SPF](#-spf-sender-policy-framework)
6. [DKIM](#-dkim-domainkeys-identified-mail)
7. [DMARC](#-dmarc-domain-based-message-authentication)
8. [Autodiscover e Autoconfig](#-autodiscover-e-autoconfig)
9. [Verificação](#-verificação)

---

## ✅ Registos Essenciais

Todos os registos DNS do domínio `fsociety.pt` estão configurados no **Cloudflare**.

### Resumo dos Registos Necessários

| Tipo | Nome | Valor | TTL | Prioridade |
|------|------|-------|-----|------------|
| **A** | mail | 188.81.65.191 | Auto | - |
| **MX** | @ | mail.fsociety.pt | Auto | 10 |
| **TXT** | @ | SPF record | Auto | - |
| **TXT** | dkim._domainkey | DKIM key | Auto | - |
| **TXT** | _dmarc | DMARC policy | Auto | - |
| **CNAME** | autodiscover | mail.fsociety.pt | Auto | - |
| **CNAME** | autoconfig | mail.fsociety.pt | Auto | - |

---

## 🎯 Registo A

O registo A mapeia o hostname do servidor de email para o IP público.

### Configuração no Cloudflare

```
Type: A
Name: mail
IPv4 address: 188.81.65.191
Proxy status: DNS only (cinzento, não orange)
TTL: Auto
```

⚠️ **IMPORTANTE:** Cloudflare proxy (cloud laranja) deve estar **DESATIVADO** para o registo `mail`. Email não funciona através do proxy Cloudflare.

### Verificar

```bash
# Deve retornar 188.81.65.191
nslookup mail.fsociety.pt

# Ou
dig mail.fsociety.pt A +short
```

**Resultado esperado:**
```
188.81.65.191
```

---

## 📬 Registo MX

O registo MX indica qual servidor recebe emails para o domínio.

### Configuração no Cloudflare

```
Type: MX
Name: @ (ou fsociety.pt)
Mail server: mail.fsociety.pt
Priority: 10
TTL: Auto
```

### Múltiplos Servidores MX (Opcional)

Para redundância, pode adicionar servidor backup:

```
Priority 10: mail.fsociety.pt (principal)
Priority 20: mail2.fsociety.pt (backup)
```

### Verificar

```bash
# Deve retornar mail.fsociety.pt com prioridade 10
nslookup -type=MX fsociety.pt

# Ou
dig fsociety.pt MX +short
```

**Resultado esperado:**
```
10 mail.fsociety.pt.
```

---

## 🔄 Registo PTR (Reverse DNS)

O PTR mapeia o IP público de volta para o hostname (reverse lookup).

### Importância

- **Essencial** para entrega de email
- Muitos servidores rejeitam emails sem PTR válido
- Previne classificação como spam

### Configuração

⚠️ **PTR é configurado pelo ISP/Provider**, não pelo cliente.

**Para FSociety (Proxmox/OVH/etc):**

Contactar o provider e solicitar:
```
188.81.65.191 → mail.fsociety.pt
```

### Verificar

```bash
# Deve retornar mail.fsociety.pt
nslookup 188.81.65.191

# Ou
dig -x 188.81.65.191 +short

# Ou
host 188.81.65.191
```

**Resultado esperado:**
```
191.65.81.188.in-addr.arpa name = mail.fsociety.pt.
```

---

## 🛡️ SPF (Sender Policy Framework)

SPF define quais servidores podem enviar emails pelo domínio.

### Configuração no Cloudflare

```
Type: TXT
Name: @ (ou fsociety.pt)
Content: v=spf1 mx ~all
TTL: Auto
```

### Explicação da Sintaxe

```
v=spf1          → Versão SPF 1
mx              → Servidores listados no MX podem enviar
~all            → Soft fail para outros (marca como suspeito, não rejeita)
```

### Variações Comuns

```
v=spf1 mx ~all                    → Apenas MX (recomendado)
v=spf1 mx a ~all                  → MX + registo A
v=spf1 mx ip4:188.81.65.191 ~all  → MX + IP específico
v=spf1 mx -all                    → Hard fail (rejeita tudo que não seja MX)
```

### Verificar

```bash
# Ver registo SPF
nslookup -type=TXT fsociety.pt

# Ou
dig fsociety.pt TXT +short | grep spf
```

**Resultado esperado:**
```
"v=spf1 mx ~all"
```

### Testar SPF

**Online:** https://mxtoolbox.com/spf.aspx

---

## 🔑 DKIM (DomainKeys Identified Mail)

DKIM assina emails criptograficamente, provando autenticidade.

### Obter Chave DKIM do Mailcow

```bash
# Ver chave pública DKIM
sudo cat /opt/mailcow-dockerized/data/dkim/fsociety.pt.dkim
```

**Saída exemplo:**
```
dkim._domainkey.fsociety.pt. IN TXT "v=DKIM1;k=rsa;t=s;s=email;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqwertyuiopasdfghjklzxcvbnm..."
```

### Configuração no Cloudflare

```
Type: TXT
Name: dkim._domainkey
Content: v=DKIM1;k=rsa;t=s;s=email;p=MIIBIjANBgkqhki...
TTL: Auto
```

⚠️ **NOTA:** Copiar apenas a parte depois de `"p="` (a chave pública). Se o valor for muito grande, pode ser necessário dividir em múltiplos TXT records ou usar formato alternativo.

### Formato Alternativo (Se Muito Grande)

Cloudflare suporta TXT records até 255 caracteres por string. Para chaves maiores:

```
Type: TXT
Name: dkim._domainkey
Content: "v=DKIM1;k=rsa;t=s;s=email;""p=MIIBIjANBgkq...primeira_parte" "...segunda_parte...resto_da_chave"
```

### Verificar

```bash
# Ver DKIM public key
nslookup -type=TXT dkim._domainkey.fsociety.pt

# Ou
dig dkim._domainkey.fsociety.pt TXT +short
```

### Testar DKIM

1. Enviar email de `ryan.barbosa@fsociety.pt` para `check-auth@verifier.port25.com`
2. Receberá resposta com análise completa de SPF/DKIM/DMARC

---

## 📊 DMARC (Domain-based Message Authentication)

DMARC define política de tratamento de emails que falham SPF/DKIM.

### Configuração no Cloudflare

```
Type: TXT
Name: _dmarc
Content: v=DMARC1; p=quarantine; rua=mailto:postmaster@fsociety.pt; ruf=mailto:postmaster@fsociety.pt; fo=1; adkim=r; aspf=r; pct=100; ri=86400
TTL: Auto
```

### Explicação da Sintaxe

```
v=DMARC1                                 → Versão DMARC
p=quarantine                             → Política: quarentena (none/quarantine/reject)
rua=mailto:postmaster@fsociety.pt        → Relatórios agregados (daily)
ruf=mailto:postmaster@fsociety.pt        → Relatórios forenses (por falha)
fo=1                                     → Gerar relatório se SPF ou DKIM falhar
adkim=r                                  → DKIM alignment relaxed
aspf=r                                   → SPF alignment relaxed
pct=100                                  → Aplicar a 100% dos emails
ri=86400                                 → Intervalo de relatórios (24h)
```

### Políticas DMARC

| Política | Ação | Recomendação |
|----------|------|--------------|
| **none** | Monitorizar, não rejeitar | Fase inicial/teste |
| **quarantine** | Marcar como spam | Produção (recomendado) |
| **reject** | Rejeitar totalmente | Máxima segurança |

### Evolução Recomendada

```
Semana 1-2:  v=DMARC1; p=none; rua=mailto:postmaster@fsociety.pt
Semana 3-4:  v=DMARC1; p=quarantine; pct=10; rua=mailto:postmaster@fsociety.pt
Mês 2+:      v=DMARC1; p=quarantine; pct=100; rua=mailto:postmaster@fsociety.pt
Produção:    v=DMARC1; p=reject; rua=mailto:postmaster@fsociety.pt
```

### Verificar

```bash
# Ver registo DMARC
nslookup -type=TXT _dmarc.fsociety.pt

# Ou
dig _dmarc.fsociety.pt TXT +short
```

**Resultado esperado:**
```
"v=DMARC1; p=quarantine; rua=mailto:postmaster@fsociety.pt; ..."
```

---

## 🔧 Autodiscover e Autoconfig

Permitem configuração automática de clientes de email.

### Autodiscover (Outlook/Exchange)

```
Type: CNAME
Name: autodiscover
Target: mail.fsociety.pt
TTL: Auto
```

### Autoconfig (Thunderbird/Mozilla)

```
Type: CNAME
Name: autoconfig
Target: mail.fsociety.pt
TTL: Auto
```

### Verificar

```bash
# Teste autodiscover
curl https://autodiscover.fsociety.pt/autodiscover/autodiscover.xml

# Teste autoconfig
curl https://autoconfig.fsociety.pt/.well-known/autoconfig/mail/config-v1.1.xml
```

---

## ✅ Verificação

### Checklist Completa

```bash
# 1. Registo A
dig mail.fsociety.pt A +short
# Esperado: 188.81.65.191

# 2. Registo MX
dig fsociety.pt MX +short
# Esperado: 10 mail.fsociety.pt.

# 3. Registo PTR
dig -x 188.81.65.191 +short
# Esperado: mail.fsociety.pt.

# 4. SPF
dig fsociety.pt TXT +short | grep spf
# Esperado: "v=spf1 mx ~all"

# 5. DKIM
dig dkim._domainkey.fsociety.pt TXT +short
# Esperado: "v=DKIM1;k=rsa;..."

# 6. DMARC
dig _dmarc.fsociety.pt TXT +short
# Esperado: "v=DMARC1; p=quarantine; ..."
```

### Ferramentas Online

| Ferramenta | URL | Função |
|------------|-----|--------|
| **MXToolbox** | https://mxtoolbox.com | Teste completo de DNS/Email |
| **DKIM Validator** | https://dkimvalidator.com | Verificar DKIM signature |
| **Mail-tester** | https://mail-tester.com | Score de deliverability |
| **Google Admin Toolbox** | https://toolbox.googleapps.com/apps/checkmx/ | Check MX records |
| **DMARC Analyzer** | https://dmarcian.com/dmarc-inspector/ | Verificar DMARC |

### Teste Completo

1. **Enviar email de teste:**
   ```
   De: ryan.barbosa@fsociety.pt
   Para: check-auth@verifier.port25.com
   ```

2. **Receber análise completa:**
   - SPF: pass/fail
   - DKIM: pass/fail
   - DMARC: pass/fail
   - SpamAssassin score

3. **Enviar para mail-tester.com:**
   - Obter score /10
   - Ver recomendações

---

## 📊 Estado Atual FSociety

| Registo | Status | Valor |
|---------|--------|-------|
| **A (mail)** | ✅ Configurado | 188.81.65.191 |
| **MX** | ✅ Configurado | mail.fsociety.pt (10) |
| **PTR** | ⚠️ A verificar | (solicitar ao ISP) |
| **SPF** | ✅ Configurado | v=spf1 mx ~all |
| **DKIM** | ✅ Configurado | dkim._domainkey |
| **DMARC** | ✅ Configurado | p=quarantine |
| **Autodiscover** | ✅ Configurado | CNAME → mail |
| **Autoconfig** | ✅ Configurado | CNAME → mail |

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

**[⬅️ Anterior: Webmail](06-webmail.md)** | **[Índice](README.md)** | **[Próximo: Backup ➡️](08-backup.md)**

</div>

---

*Última atualização: Dezembro 2024*
