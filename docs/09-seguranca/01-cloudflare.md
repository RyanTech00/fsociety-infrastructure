# ☁️ Cloudflare - Proteção Externa

> **Guia completo de configuração do Cloudflare**

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Configuração de Domínio](#-configuração-de-domínio)
- [SSL/TLS](#-ssltls)
- [Funcionalidades de Segurança](#-funcionalidades-de-segurança)
- [Registos DNS](#-registos-dns)
- [Estatísticas e Métricas](#-estatísticas-e-métricas)
- [Troubleshooting](#-troubleshooting)

## 🌐 Visão Geral

O Cloudflare atua como a primeira camada de defesa da infraestrutura FSociety, posicionado entre os utilizadores e os servidores. Fornece proteção contra ataques DDoS, filtragem de tráfego malicioso através do WAF, cache de conteúdo via CDN e gestão de certificados SSL/TLS.

**Benefícios principais**:
- Proteção contra ataques DDoS de camada 3, 4 e 7
- WAF gerenciado com regras constantemente atualizadas
- Cache global reduzindo latência e carga nos servidores
- Certificados SSL/TLS automáticos e gratuitos
- Analytics detalhados de tráfego e ameaças

## 🔧 Configuração de Domínio

### Informações Básicas
| Parâmetro | Valor |
|-----------|-------|
| **Domínio** | fsociety.pt |
| **IP Público** | 188.81.65.191 |
| **DNS Setup** | Full |
| **Status** | ✅ Ativo |

O modo **Full DNS** significa que o Cloudflare é o servidor DNS autoritativo para o domínio, permitindo controle completo sobre os registos DNS e habilitando todas as funcionalidades de proxy e segurança.

### Nameservers
```
april.ns.cloudflare.com
jay.ns.cloudflare.com
```

## 🔐 SSL/TLS

### Configuração de Encriptação

| Configuração | Valor |
|--------------|-------|
| **Modo de Encriptação** | Full (strict) |
| **Certificado Principal** | Universal SSL |
| **Domínios Cobertos** | *.fsociety.pt, fsociety.pt |
| **Validade** | Até 2026-01-14 (managed) |
| **Certificado Backup** | Até 2026-01-20 |

#### O que significa "Full (strict)"?

Este é o modo mais seguro de operação SSL/TLS no Cloudflare:
1. **Cliente → Cloudflare**: Conexão encriptada (TLS)
2. **Cloudflare → Servidor Origin**: Conexão encriptada com validação do certificado
3. O certificado do servidor origin deve ser válido e confiável

### Estatísticas TLS (últimas 24 horas)

| Versão TLS | Conexões | Percentagem |
|------------|----------|-------------|
| **TLS 1.3** | 948 | 93.2% ✅ |
| TLS 1.2 | 17 | 1.7% |
| None (not secure) | 49 | 4.8% ⚠️ |
| Unknown | 2 | 0.2% |

**Análise**: 93.2% das conexões utilizam TLS 1.3, a versão mais moderna e segura. As 49 conexões não seguras podem ser de scanners ou bots que não suportam HTTPS.

### Funcionalidades SSL/TLS Ativas

- ✅ **Always Use HTTPS**: Redireciona automaticamente HTTP para HTTPS
- ✅ **HTTP Strict Transport Security (HSTS)**: Força browsers a usar apenas HTTPS
- ✅ **TLS 1.3**: Suporte para a versão mais recente do protocolo
- ✅ **Automatic HTTPS Rewrites**: Reescreve URLs internas de HTTP para HTTPS
- ✅ **Certificate Transparency Monitoring**: Monitoriza certificados emitidos para o domínio

## 🛡️ Funcionalidades de Segurança

### Proteção Ativa

#### 1. Bot Protection
- ✅ **Bot Fight Mode**: Bloqueia bots maliciosos automaticamente
  - JS Detections: Ativo
- ✅ **Block AI Bots**: Impede scrapers de IA não autorizados
- ✅ **AI Labyrinth**: Camada adicional contra bots de IA
- ✅ **Browser Integrity Check**: Verifica headers HTTP suspeitos

#### 2. DDoS Protection
- ✅ **HTTP DDoS Attack Protection**: Camada 7 (aplicação)
- ✅ **Network-layer DDoS Protection**: Camadas 3 e 4
- ✅ **SSL/TLS DDoS Protection**: Ataques específicos a TLS

#### 3. Web Application Firewall (WAF)
- ✅ **Cloudflare Managed WAF Ruleset**: Regras geridas pela Cloudflare
- **Ferramentas de Detecção Ativas**:
  - Web Application Exploits: 2/2 tools running
  - Bot Traffic: 2/2 tools running
  - API Abuse: 1/1 tool running
  - Client-side Abuse: 1/1 tool running

#### 4. Security Level
- ✅ **I'm Under Attack Mode**: Nível máximo de proteção ativado
  - Apresenta challenge JavaScript antes de aceder ao site
  - Útil durante ataques DDoS intensos
  - Pode impactar experiência de utilizadores legítimos

⚠️ **Nota**: O modo "Under Attack" está permanentemente ativo. Considere ajustar para "High" durante períodos normais para melhor experiência do utilizador.

## 📡 Registos DNS

### Tabela Completa de Registos

| Tipo | Nome | Conteúdo | Proxy Status |
|------|------|----------|--------------|
| A | fsociety.pt | 188.81.65.191 | ☁️ Proxied |
| A | mail | 188.81.65.191 | 🔴 DNS only |
| A | nextcloud | 188.81.65.191 | ☁️ Proxied |
| A | vpn | 188.81.65.191 | 🔴 DNS only |
| A | webmail | 188.81.65.191 | ☁️ Proxied |
| A | www | 188.81.65.191 | ☁️ Proxied |
| CNAME | autoconfig | mail.fsociety.pt | 🔴 DNS only |
| CNAME | autodiscover | mail.fsociety.pt | 🔴 DNS only |
| CNAME | em717937 | return.smtp2go.net | 🔴 DNS only |
| CNAME | link | track.smtp2go.net | 🔴 DNS only |
| CNAME | s717937_domainkey | dkim.smtp2go.net | 🔴 DNS only |
| MX | fsociety.pt | mail.fsociety.pt (10) | 🔴 DNS only |
| SRV | _autodiscover._tcp | mail.fsociety.pt:443 | 🔴 DNS only |
| TLSA | _25._tcp.mail | 3 1 1 a003db588844cda96... | 🔴 DNS only |
| TXT | dkim._domainkey | v=DKIM1;k=rsa;t=s;s=ema... | 🔴 DNS only |
| TXT | _dmarc | v=DMARC1; p=quarantine | 🔴 DNS only |
| TXT | fsociety.pt | v=spf1 ip4:188.81.65.191 -all | 🔴 DNS only |

### Análise da Configuração

**Registos com Proxy (☁️)**:
- `fsociety.pt`, `www`, `nextcloud`, `webmail` passam pelo Cloudflare
- Beneficiam de CDN, WAF e proteção DDoS
- IP real do servidor (188.81.65.191) fica oculto

**Registos DNS Only (🔴)**:
- `mail`, `vpn` apontam diretamente para o servidor
- Necessário para serviços que não funcionam corretamente através de proxy
- Email (SMTP/IMAP) requer conexão direta
- VPN requer conexão direta ao servidor

**Configuração de Email**:
- **SPF**: `v=spf1 ip4:188.81.65.191 -all` (rejeita emails de outros IPs)
- **DKIM**: Autenticação com chave RSA via SMTP2GO
- **DMARC**: Política de quarentena para emails não autenticados
- **TLSA**: DANE para validação de certificado SMTP

## 📊 Estatísticas e Métricas

### Visão Geral (últimas 24 horas)

| Métrica | Valor |
|---------|-------|
| **Total de Requests** | 1.03k |
| **Mitigated by Cloudflare** | 95 (31.65%) |
| **Allowed Requests** | 935 (68.35%) |

### Detecção de Ameaças

| Categoria | Ferramentas Ativas |
|-----------|-------------------|
| Web Application Exploits | 2/2 ✅ |
| DDoS Attacks | 2/2 ✅ |
| Bot Traffic | 2/2 ✅ |
| API Abuse | 1/1 ✅ |
| Client-side Abuse | 1/1 ✅ |

**Total**: 8/8 ferramentas de detecção operacionais

### Análise de Tráfego Mitigado

Dos 95 requests bloqueados nas últimas 24 horas:
- Scanners automatizados procurando vulnerabilidades
- Bots maliciosos tentando scraping não autorizado
- Tentativas de exploração de falhas conhecidas
- Tráfego de países/ASNs com má reputação

## 🔍 Troubleshooting

### Verificar Status do Cloudflare

```bash
# Verificar se o domínio está a usar Cloudflare
dig fsociety.pt

# Verificar nameservers
dig NS fsociety.pt

# Testar conectividade através do Cloudflare
curl -I https://fsociety.pt
```

### Problemas Comuns

#### 1. Site inacessível após ativar proxy

**Sintoma**: ERR_TOO_MANY_REDIRECTS ou erro 521

**Solução**:
```bash
# Verificar modo SSL/TLS no Cloudflare
# Deve ser "Full (strict)" se o origin tem certificado válido
# Ou "Full" se o origin tem certificado self-signed

# Verificar se o origin está a forçar HTTPS corretamente
curl -I http://188.81.65.191
```

#### 2. Email não funciona

**Sintoma**: Impossível enviar/receber emails

**Causa**: Registos MX não devem ter proxy ativo

**Solução**:
- Garantir que `mail.fsociety.pt` está em "DNS only"
- Portas 25, 587, 993, 465 não funcionam através do proxy Cloudflare

#### 3. Utilizadores legítimos bloqueados

**Sintoma**: Challenge pages para utilizadores normais

**Solução**:
```
1. Reduzir Security Level de "Under Attack" para "High"
2. Verificar regras WAF personalizadas
3. Adicionar exceções para IPs conhecidos
4. Verificar logs no Cloudflare Dashboard > Security > Events
```

### Comandos Úteis

```bash
# Limpar cache do Cloudflare (via API)
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
     -H "Authorization: Bearer {api_token}" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

# Verificar headers de segurança
curl -I https://fsociety.pt | grep -i "strict-transport-security"

# Testar TLS version
openssl s_client -connect fsociety.pt:443 -tls1_3
```

## 📚 Documentação Oficial

- [Cloudflare Docs](https://developers.cloudflare.com/)
- [SSL/TLS Best Practices](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/)
- [WAF Rules](https://developers.cloudflare.com/waf/)
- [DDoS Protection](https://developers.cloudflare.com/ddos-protection/)

---
## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: CrowdSec IDS/IPS ➡️](02-crowdsec.md)**

</div>

---

*Última atualização: Dezembro 2025*
