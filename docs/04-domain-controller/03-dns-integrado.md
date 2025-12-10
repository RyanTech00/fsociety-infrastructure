# 🌐 DNS Integrado do Samba AD

> **Configuração das zonas DNS integradas com o Active Directory**

---
        
## 📹 Demonstração

O vídeo abaixo demonstra a configuração completa do DNS integrado, incluindo as 4 zonas DNS, registos A, PTR, SRV, MX/TXT e teste de forwarder:

https://github.com/user-attachments/assets/e1436b9a-00f3-4a5b-9ac6-e0c2cb5b9990

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Zonas DNS](#-zonas-dns)
3. [Registos A (Forward)](#-registos-a-forward)
4. [Registos PTR (Reverse)](#-registos-ptr-reverse)
5. [Registos MX e Email](#-registos-mx-e-email)
6. [Registos SRV do AD](#-registos-srv-do-ad)
7. [DNS Forwarders](#-dns-forwarders)
8. [Verificação e Testes](#-verificação-e-testes)
9. [Referências](#-referências)

---

## 📖 Visão Geral

### DNS Integrado vs Externo

O Samba AD DC utiliza um servidor DNS integrado (SAMBA_INTERNAL) que:

- **Armazena registos na base de dados LDAP** do AD
- **Replica automaticamente** entre Domain Controllers
- **Suporta atualizações dinâmicas** (DDNS) autenticadas por Kerberos
- **Mantém registos SRV** essenciais para o funcionamento do AD

### Portas e Protocolos

| Porta | Protocolo | Serviço |
|-------|-----------|---------|
| 53 | TCP | DNS (transferências de zona, queries grandes) |
| 53 | UDP | DNS (queries padrão) |

---

## 🗂️ Zonas DNS

### Zonas Configuradas

| Zona | Tipo | Descrição |
|------|------|-----------|
| fsociety.pt | Forward | Zona principal do domínio |
| 1.168.192.in-addr.arpa | Reverse | Resolução inversa da LAN |
| _msdcs.fsociety.pt | Forward | Registos de localização do AD |
| 0.0.10.in-addr.arpa | Reverse | Resolução inversa da DMZ |

### Verificar Zonas Existentes

```bash
# Listar todas as zonas
sudo samba-tool dns zonelist dc.fsociety.pt -U Administrator

# Ver informação de uma zona específica
sudo samba-tool dns zoneinfo dc.fsociety.pt fsociety.pt -U Administrator
```

### Criar Zona Reversa da LAN

```bash
# Criar zona reversa para 192.168.1.0/24
sudo samba-tool dns zonecreate dc.fsociety.pt 1.168.192.in-addr.arpa -U Administrator
```

### Criar Zona Reversa da DMZ

```bash
# Criar zona reversa para 10.0.0.0/24
sudo samba-tool dns zonecreate dc.fsociety.pt 0.0.10.in-addr.arpa -U Administrator
```

---

## 📝 Registos A (Forward)

### Registos da Zona fsociety.pt

| Hostname | IP | Descrição |
|----------|----|-----------| 
| dc | 192.168.1.10 | Domain Controller |
| mail | 10.0.0.20 | Servidor de Email (Mailcow) |
| files | 192.168.1.40 | Servidor de Ficheiros (Nextcloud) |
| webserver | 10.0.0.30 | Servidor Web |
| backup | 192.168.1.50 | Proxmox Backup Server |

### Adicionar Registos A

```bash
# Domain Controller (já existe após provisão)
sudo samba-tool dns add dc.fsociety.pt fsociety.pt dc A 192.168.1.10 -U Administrator

# Mail Server
sudo samba-tool dns add dc.fsociety.pt fsociety.pt mail A 10.0.0.20 -U Administrator

# Files Server (Nextcloud)
sudo samba-tool dns add dc.fsociety.pt fsociety.pt files A 192.168.1.40 -U Administrator

# Web Server
sudo samba-tool dns add dc.fsociety.pt fsociety.pt webserver A 10.0.0.30 -U Administrator

# Backup Server
sudo samba-tool dns add dc.fsociety.pt fsociety.pt backup A 192.168.1.50 -U Administrator
```

### Verificar Registos A

```bash
# Listar todos os registos da zona
sudo samba-tool dns query dc.fsociety.pt fsociety.pt @ ALL -U Administrator

# Verificar registo específico
host dc.fsociety.pt localhost
host mail.fsociety.pt localhost
```

---

## 🔄 Registos PTR (Reverse)

### Registos PTR da LAN (192.168.1.x)

| IP | PTR | Hostname |
|----|-----|----------|
| 192.168.1.10 | 10 | dc.fsociety.pt |
| 192.168.1.40 | 40 | files.fsociety.pt |
| 192.168.1.50 | 50 | backup.fsociety.pt |

### Adicionar Registos PTR da LAN

```bash
# DC
sudo samba-tool dns add dc.fsociety.pt 1.168.192.in-addr.arpa 10 PTR dc.fsociety.pt -U Administrator

# Files Server
sudo samba-tool dns add dc.fsociety.pt 1.168.192.in-addr.arpa 40 PTR files.fsociety.pt -U Administrator

# Backup Server
sudo samba-tool dns add dc.fsociety.pt 1.168.192.in-addr.arpa 50 PTR backup.fsociety.pt -U Administrator
```

### Registos PTR da DMZ (10.0.0.x)

| IP | PTR | Hostname |
|----|-----|----------|
| 10.0.0.20 | 20 | mail.fsociety.pt |
| 10.0.0.30 | 30 | webserver.fsociety.pt |

### Adicionar Registos PTR da DMZ

```bash
# Mail Server
sudo samba-tool dns add dc.fsociety.pt 0.0.10.in-addr.arpa 20 PTR mail.fsociety.pt -U Administrator

# Web Server
sudo samba-tool dns add dc.fsociety.pt 0.0.10.in-addr.arpa 30 PTR webserver.fsociety.pt -U Administrator
```

### Verificar Registos PTR

```bash
# Verificar resolução inversa
host 192.168.1.10 localhost
host 10.0.0.20 localhost
```

---

## 📧 Registos MX e Email

### Registos MX

| Prioridade | Mail Server | Descrição |
|------------|-------------|-----------|
| TXT | @ | v=spf1 include:spf. smtp2go.com -all |

### Adicionar Registos MX

```bash
# MX principal
sudo samba-tool dns add dc.fsociety.pt fsociety.pt @ MX "mail.fsociety.pt 10" -U Administrator
```

### Registos SPF, DKIM e DMARC

#### SPF (Sender Policy Framework)

```bash
# Registo SPF
sudo samba-tool dns add dc.fsociety.pt fsociety.pt @ TXT "v=spf1 mx ip4:188.81.65.191 ip4:10.0.0.20 ~all" -U Administrator
```

**Explicação do SPF:**
- `v=spf1` - Versão do SPF
- `mx` - Permite servidores MX do domínio
- `ip4:188.81.65.191` - IP público do servidor
- `ip4:10.0.0.20` - IP do servidor de email
- `~all` - Soft fail para outros IPs

#### DMARC (Domain-based Message Authentication)

```bash
# Registo DMARC
sudo samba-tool dns add dc.fsociety.pt fsociety.pt _dmarc TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@fsociety.pt; ruf=mailto:postmaster@fsociety.pt; fo=1" -U Administrator
```

**Explicação do DMARC:**
- `v=DMARC1` - Versão DMARC
- `p=quarantine` - Política: quarentena para emails falhados
- `rua` - Email para relatórios agregados
- `ruf` - Email para relatórios forenses
- `fo=1` - Gerar relatório se qualquer verificação falhar

#### DKIM (DomainKeys Identified Mail)

O registo DKIM é gerado pelo servidor de email (Mailcow) e deve ser adicionado após configuração:

```bash
# Exemplo de registo DKIM (chave gerada pelo Mailcow)
sudo samba-tool dns add dc.fsociety.pt fsociety.pt dkim._domainkey TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBA..." -U Administrator
```

### Tabela Resumo de Registos de Email

| Tipo | Nome | Valor |
|------|------|-------|
| MX | @ | mail.fsociety.pt (10) |
| TXT | @ | v=spf1 include:spf. smtp2go.com -all |
| TXT | _dmarc | v=DMARC1; p=quarantine; ... |
| TXT | dkim._domainkey | v=DKIM1; k=rsa; p=... |

---

## 🔧 Registos SRV do AD

### Registos Criados Automaticamente

O Samba AD DC cria automaticamente os seguintes registos SRV na zona `_msdcs.fsociety.pt`:

| Serviço | Registo SRV | Porta |
|---------|-------------|-------|
| LDAP | _ldap._tcp.fsociety.pt | 389 |
| LDAP GC | _ldap._tcp.gc._msdcs.fsociety.pt | 3268 |
| Kerberos | _kerberos._tcp.fsociety.pt | 88 |
| Kerberos UDP | _kerberos._udp.fsociety.pt | 88 |
| Kpasswd | _kpasswd._tcp.fsociety.pt | 464 |
| Kpasswd UDP | _kpasswd._udp.fsociety.pt | 464 |

### Verificar Registos SRV

```bash
# LDAP
host -t SRV _ldap._tcp.fsociety.pt localhost

# Kerberos
host -t SRV _kerberos._tcp.fsociety.pt localhost

# Global Catalog
host -t SRV _gc._tcp.fsociety.pt localhost

# Verificar todos os registos SRV
sudo samba-tool dns query dc.fsociety.pt _msdcs.fsociety.pt @ ALL -U Administrator
```

### Saída Esperada

```
_ldap._tcp.fsociety.pt has SRV record 0 100 389 dc.fsociety.pt.
_kerberos._tcp.fsociety.pt has SRV record 0 100 88 dc.fsociety.pt.
_gc._tcp.fsociety.pt has SRV record 0 100 3268 dc.fsociety.pt.
```

---

## 🔀 DNS Forwarders

### Configurar DNS Forwarders

Os forwarders são utilizados para resolver nomes externos ao domínio fsociety.pt.

**Configuração em `/etc/samba/smb.conf`:**

```ini
[global]
    dns forwarder = 192.168.1.1
```

### Forwarders Configurados

| Servidor | IP | Descrição |
|----------|----|-----------| 
| pfSense | 192.168.1.1 | Gateway/DNS da rede |
| Google DNS | 8.8.8.8 | DNS público (backup) |

### Adicionar Múltiplos Forwarders

Para adicionar múltiplos forwarders, edite `/etc/samba/smb.conf`:

```ini
[global]
    dns forwarder = 192.168.1.1 8.8.8.8
```

Ou use o comando:

```bash
# Verificar configuração atual
sudo samba-tool dns serverinfo dc.fsociety.pt -U Administrator
```

### Testar Resolução Externa

```bash
# Resolver nome externo via forwarder
nslookup google.com localhost

# Testar com dig
dig @localhost google.com
```

---

## ✅ Verificação e Testes

### Verificação Completa de DNS

```bash
#!/bin/bash
# Script de verificação de DNS

echo "=== Verificação de DNS do Samba AD ==="

echo -e "\n--- Zonas DNS ---"
# Nota: Será solicitada a password do Administrator
sudo samba-tool dns zonelist dc.fsociety.pt -U Administrator

echo -e "\n--- Registos A ---"
for host in dc mail files webserver; do
    echo -n "$host.fsociety.pt: "
    host $host.fsociety.pt localhost 2>/dev/null | grep "has address" || echo "ERRO"
done

echo -e "\n--- Registos PTR ---"
for ip in 192.168.1.10 192.168.1.40 10.0.0.20; do
    echo -n "$ip: "
    host $ip localhost 2>/dev/null | grep "pointer" || echo "ERRO"
done

echo -e "\n--- Registos SRV ---"
host -t SRV _ldap._tcp.fsociety.pt localhost
host -t SRV _kerberos._tcp.fsociety.pt localhost

echo -e "\n--- Registos MX ---"
host -t MX fsociety.pt localhost

echo -e "\n--- Registos TXT (SPF/DMARC) ---"
host -t TXT fsociety.pt localhost
host -t TXT _dmarc.fsociety.pt localhost

echo -e "\n--- Forwarder Test ---"
nslookup google.com localhost
```

### Testes Individuais

```bash
# Testar resolução forward
dig @localhost dc.fsociety.pt

# Testar resolução reversa
dig @localhost -x 192.168.1.10

# Testar registos MX
dig @localhost MX fsociety.pt

# Testar registos TXT
dig @localhost TXT fsociety.pt

# Testar SOA
dig @localhost SOA fsociety.pt
```

### Verificar Replicação DNS

```bash
# Estado do DNS
sudo samba-tool dns serverinfo dc.fsociety.pt -U Administrator

# Verificar partições DNS no AD
sudo samba-tool drs showrepl
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Causa | Solução |
|----------|-------|---------|
| Registo não resolve | Cache DNS | `sudo rndc flush` ou reiniciar samba |
| Zona não existe | Não foi criada | `samba-tool dns zonecreate` |
| Erro de permissão | Autenticação | Usar `-U Administrator` |
| Forwarder não funciona | Conectividade | Verificar firewall |

### Logs de DNS

```bash
# Ver logs do Samba
sudo tail -f /var/log/samba/log.samba

# Aumentar verbosidade (temporário)
sudo samba-tool dns serverinfo dc.fsociety.pt -U Administrator --debuglevel=3
```

### Reiniciar DNS

```bash
# Reiniciar serviço Samba (inclui DNS)
sudo systemctl restart samba-ad-dc

# Verificar estado
sudo systemctl status samba-ad-dc
```

---

## 📚 Referências

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| Samba DNS Administration | https://wiki.samba.org/index.php/DNS_Administration |
| samba-tool dns | https://wiki.samba.org/index.php/Samba-tool/dns |
| AD-integrated DNS | https://wiki.samba.org/index.php/DNS |

### RFCs

| RFC | Descrição |
|-----|-----------|
| RFC 1035 | Domain Names - Implementation and Specification |
| RFC 2782 | DNS SRV Records |
| RFC 7208 | Sender Policy Framework (SPF) |
| RFC 7489 | DMARC |
| RFC 6376 | DomainKeys Identified Mail (DKIM) |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 🔗 Navegação

| Anterior | Índice | Próximo |
|----------|--------|---------|
| [← Samba AD DC](02-samba-ad-dc.md) | [📚 Índice](README.md) | [DHCP Server →](04-dhcp-server.md) |

---

<div align="center">

**[⬆️ Voltar ao Topo](#-dns-integrado-do-samba-ad)**

---

*Última atualização: Dezembro 2025*

</div>
