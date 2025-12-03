# 🔐 SSL - Let's Encrypt Wildcard

> **Certificados SSL wildcard para *.fsociety.pt**

---

## 📋 Instalação e Configuração

### Instalar Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Obter Certificado Wildcard

```bash
sudo certbot certonly --manual \
  --preferred-challenges=dns \
  --email admin@fsociety.pt \
  --agree-tos \
  -d fsociety.pt \
  -d *.fsociety.pt
```

### Configurar DNS TXT Record

Durante o processo, será pedido para criar um registo DNS TXT:

```
_acme-challenge.fsociety.pt. TXT "valor_gerado_pelo_certbot"
```

Adicionar no Cloudflare e aguardar propagação (~5 min).

### Renovação Automática

```bash
# Testar renovação
sudo certbot renew --dry-run

# Cron já configurado em /etc/cron.d/certbot
```

### Ficheiros do Certificado

```
/etc/letsencrypt/live/fsociety.pt/
├── fullchain.pem    # Certificado completo
├── privkey.pem      # Chave privada
├── chain.pem        # Cadeia intermediária
└── cert.pem         # Certificado apenas
```

---

<div align="center">

**[⬅️ Voltar: Proxy Mailcow](06-proxy-mailcow.md)** | **[Próximo: DNS Cloudflare ➡️](08-dns-cloudflare.md)**

</div>
