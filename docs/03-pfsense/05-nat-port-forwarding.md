# 🔄 NAT e Port Forwarding

> Documentação completa das configurações de NAT (Network Address Translation) e Port Forwarding do pfSense.

---

## 📋 Conceitos Básicos

### NAT (Network Address Translation)

**Função**: Traduzir endereços IP privados para o endereço IP público da WAN.

**Tipos**:
- **Outbound NAT**: Tráfego saindo da rede interna para a Internet
- **Port Forward**: Tráfego entrando da Internet para servidores internos
- **1:1 NAT**: Mapeamento 1-para-1 de IP público para IP privado

---

## 🌐 Outbound NAT (Saída)

```
Firewall → NAT → Outbound
```

### Modo de Operação

| Modo | Descrição | Utilização |
|------|-----------|------------|
| **Automatic** | ✅ **ATIVO** | Cria regras automaticamente |
| Manual | Controlo total manual | Cenários avançados |
| Hybrid | Mix automático + manual | Regras customizadas adicionais |
| Disable | Desativa NAT | Nunca usar em produção |

### Configuração Atual

```
Mode: Automatic outbound NAT rule generation
```

**Regras Automáticas Geradas**:

| # | Interface | Source | Translation | Descrição |
|---|-----------|--------|-------------|-----------|
| 1 | WAN | 192.168.1.0/24 | WAN address | LAN → Internet |
| 2 | WAN | 10.0.0.0/24 | WAN address | DMZ → Internet |
| 3 | WAN | 10.8.0.0/24 | WAN address | VPN RADIUS → Internet |
| 4 | WAN | 10.9.0.0/24 | WAN address | VPN Local → Internet |

### Exemplo de Regra Automática

```
Interface: WAN
Protocol: any
Source: 192.168.1.0/24
Source Port: *
Destination: *
Destination Port: *
NAT Address: WAN address (192.168.31.100)
NAT Port: *
Static Port: No

Description: Auto created rule for LAN
```

### Verificação

```bash
# Via CLI/SSH
pfctl -s nat

# Ver conexões NAT ativas
pfctl -s state | grep NAT
```

**Saída esperada**:
```
nat on vtnet0 from 192.168.1.0/24 to any -> (vtnet0)
nat on vtnet0 from 10.0.0.0/24 to any -> (vtnet0)
nat on vtnet0 from 10.8.0.0/24 to any -> (vtnet0)
nat on vtnet0 from 10.9.0.0/24 to any -> (vtnet0)
```

---

## 📥 Port Forwarding (Entrada)

```
Firewall → NAT → Port Forward
```

### Lista de Port Forwards

| # | WAN Port | Proto | Destino | Local Port | Descrição |
|---|----------|-------|---------|------------|-----------|
| 1 | 25 | TCP | MAIL_IP (10.0.0.20) | 25 | SMTP → Mailcow |
| 2 | 110 | TCP | MAIL_IP (10.0.0.20) | 110 | POP3 → Mailcow |
| 3 | 143 | TCP | MAIL_IP (10.0.0.20) | 143 | IMAP → Mailcow |
| 4 | 465 | TCP | MAIL_IP (10.0.0.20) | 465 | SMTPS → Mailcow |
| 5 | 587 | TCP | MAIL_IP (10.0.0.20) | 587 | Submission → Mailcow |
| 6 | 993 | TCP | MAIL_IP (10.0.0.20) | 993 | IMAPS → Mailcow |
| 7 | 995 | TCP | MAIL_IP (10.0.0.20) | 995 | POP3S → Mailcow |
| 8 | 4190 | TCP | MAIL_IP (10.0.0.20) | 4190 | Sieve → Mailcow |
| 9 | 80 | TCP | WEB_IP (10.0.0.30) | 80 | HTTP → Webserver |
| 10 | 443 | TCP | WEB_IP (10.0.0.30) | 443 | HTTPS → Webserver |
| 11 | 8007 | TCP | PBS_IP (192.168.1.30) | 8007 | PBS UI (src: Proxmox) |

### Configuração Detalhada

#### Port Forward 1-8: Mailcow Services

```
Interface: WAN
Protocol: TCP
Destination: WAN address
Destination Port: [25|110|143|465|587|993|995|4190]

Redirect Target IP: MAIL_IP (10.0.0.20)
Redirect Target Port: [25|110|143|465|587|993|995|4190] (same)

Description: Public Mail - [SMTP|POP3|IMAP|SMTPS|Submission|IMAPS|POP3S|Sieve]

NAT Reflection: Enable (NAT + Proxy)
Filter Rule Association: Add associated filter rule
```

**Exemplo SMTP (Porta 25)**:
```
Interface: WAN
Address Family: IPv4
Protocol: TCP

Source:
- Type: any

Destination:
- Type: WAN address
- Port: 25 (SMTP)

Redirect Target IP: 10.0.0.20 (MAIL_IP)
Redirect Target Port: 25

Extra Options:
- No XMLRPC Sync: ❌
- NAT Reflection: Use system default
- Filter rule association: Add associated filter rule

Description: Public Mail - SMTP
```

#### Port Forward 9-10: Web Services

```
Interface: WAN
Protocol: TCP
Destination: WAN address
Destination Port: [80|443]

Redirect Target IP: WEB_IP (10.0.0.30)
Redirect Target Port: [80|443]

Description: Public Web - [HTTP|HTTPS]

NAT Reflection: Enable (NAT + Proxy)
Filter Rule Association: Add associated filter rule
```

**Exemplo HTTPS (Porta 443)**:
```
Interface: WAN
Protocol: TCP
Destination: WAN address
Port: 443

Redirect Target: 10.0.0.30
Redirect Port: 443

Description: Public Web - HTTPS
```

#### Port Forward 11: PBS Management (Restricted)

```
Interface: WAN
Protocol: TCP

Source:
- Type: Single host or alias
- Address: PROXMOX_HOST (192.168.31.34)

Destination:
- Type: WAN address
- Port: 8007

Redirect Target IP: PBS_IP (192.168.1.30)
Redirect Target Port: 8007

Description: Proxmox VE → PBS Management UI (restricted source)

Filter Rule Association: Add associated filter rule
```

### Regras de Firewall Associadas

**Importante**: Port forwards criam automaticamente regras de firewall na interface WAN.

```
Firewall → Rules → WAN

# Regras auto-criadas pelo NAT
[Auto-Rule] NAT SMTP → Mailcow
[Auto-Rule] NAT HTTP → Webserver
...etc
```

---

## 🔀 Redirecionamentos Especiais

### Mailcow HTTPS → Webserver

**Cenário**: Redirecionar tráfego HTTPS do Mailcow para o Webserver via regra DMZ.

```
Firewall → Rules → DMZ

Action: Pass
Protocol: TCP
Source: !MAIL_IP (not Mailcow)
Destination: MAIL_IP
Port: 443

Redirect:
- Enable: ✅
- Target: WEB_IP (10.0.0.30)
- Port: 443

Description: Redirect Mailcow HTTPS → Webserver (DMZ rule)
```

**Motivo**: Permite que requests HTTPS destinadas ao Mailcow sejam redirecionadas para o webserver (Nginx) que faz proxy para os serviços apropriados.

---

## 🔍 NAT Reflection

### O que é NAT Reflection?

Permite que clientes **internos** acedam a servidores internos usando o **IP público** da WAN.

**Exemplo**:
- Cliente LAN (192.168.1.50) quer aceder a mail.fsociety.pt
- DNS resolve para IP público (192.168.31.100)
- NAT Reflection redireciona para 10.0.0.20 (interno)

### Configuração Global

```
System → Advanced → Firewall & NAT

NAT Reflection mode for port forwards:
- Mode: NAT + Proxy
  (mais compatível, funciona com UDP)

Enable NAT Reflection for 1:1 NAT:
- ✅ Enabled

Enable automatic outbound NAT for Reflection:
- ✅ Enabled
```

### Modos de NAT Reflection

| Modo | Descrição | Performance | Compatibilidade |
|------|-----------|-------------|-----------------|
| **Disable** | Desativado | Alta | Baixa |
| **NAT + Proxy** | ✅ **RECOMENDADO** | Média | Alta (TCP+UDP) |
| **Pure NAT** | Apenas NAT | Alta | Média (TCP only) |

---

## 📊 Verificação e Diagnóstico

### Ver Regras NAT Ativas

```bash
# Via CLI/SSH
pfctl -s nat

# Ver com mais detalhe
pfctl -s nat -v
```

**Saída esperada**:
```
rdr on vtnet0 proto tcp from any to 192.168.31.100 port 25 -> 10.0.0.20 port 25
rdr on vtnet0 proto tcp from any to 192.168.31.100 port 80 -> 10.0.0.30 port 80
rdr on vtnet0 proto tcp from any to 192.168.31.100 port 443 -> 10.0.0.30 port 443
...
```

### Ver Estados NAT

```
Diagnostics → States

Filter:
- Interface: WAN
- Protocol: TCP
```

**Exemplo de estado NAT ativo**:
```
WAN TCP 203.0.113.50:45678 → 192.168.31.100:25 (10.0.0.20:25) ESTABLISHED
```

### Testar Port Forward

```bash
# Externamente (de um host fora da rede)
telnet 192.168.31.100 25
telnet 192.168.31.100 80
telnet 192.168.31.100 443

# Verificar conexões
curl -I http://192.168.31.100
```

### Packet Capture

```
Diagnostics → Packet Capture

Interface: WAN
Address Family: IPv4
Protocol: TCP
Port: 25 (ou outro)
Packet Count: 100

Start → Ver tráfego NAT
```

---

## 🔐 Segurança NAT

### Boas Práticas

#### 1. Limitar Origem (Source)

```
✅ BOM:
Source: 192.168.31.34 (Proxmox específico)
Destination Port: 8007 → PBS

❌ MAU:
Source: any
Destination Port: 22 → SSH server
```

#### 2. Usar Aliases

```
✅ BOM:
Redirect Target: MAIL_IP
(se IP mudar, atualiza em todos os forwards)

❌ MAU:
Redirect Target: 10.0.0.20
(hardcoded, dificulta manutenção)
```

#### 3. Logging

```
✅ Ativar logging para:
- Port forwards sensíveis (SSH, RDP, etc.)
- Troubleshooting

❌ Evitar logging para:
- Tráfego web intenso (80, 443)
- Port forwards com muito tráfego
```

#### 4. Rate Limiting (Opcional)

```
Firewall → Rules → WAN → Edit regra NAT

Advanced Options:
- Max connections: 1000
- Max new connections: 100
- State timeout: 60

Útil para prevenir abuse de port forwards públicos
```

---

## 🛠️ Gestão de NAT

### Adicionar Port Forward

```
Firewall → NAT → Port Forward → Add

1. Interface: WAN
2. Protocol: TCP/UDP
3. Destination: WAN address
4. Destination Port: Porta pública
5. Redirect Target IP: IP interno
6. Redirect Target Port: Porta interna
7. Description: Descrição clara
8. NAT Reflection: Use system default
9. Filter Rule Association: Add associated filter rule
10. Save → Apply Changes
```

### Editar Port Forward

```
Firewall → NAT → Port Forward → Edit

⚠️ Aviso: Alterar porta pode quebrar serviços ativos
```

### Eliminar Port Forward

```
Firewall → NAT → Port Forward → Delete

⚠️ Aviso: A regra de firewall associada também será eliminada
```

### Duplicar Port Forward

```
Firewall → NAT → Port Forward → Copy (ícone)

Útil para criar port forwards similares rapidamente
```

---

## 🐛 Troubleshooting

### Port Forward não funciona

**Sintoma**: Não consigo aceder ao serviço de fora

**Diagnóstico**:
```
1. Verificar port forward:
   Firewall → NAT → Port Forward

2. Verificar regra de firewall WAN:
   Firewall → Rules → WAN
   (deve existir regra associada)

3. Verificar estados:
   Diagnostics → States
   (procurar pelo IP destino)

4. Ver logs:
   Status → System Logs → Firewall
   (ver se tráfego está a ser bloqueado)
```

**Soluções Comuns**:
- Porta WAN mal configurada
- IP interno incorreto
- Regra de firewall desativada
- Serviço não está a correr no servidor destino

### NAT Reflection não funciona

**Sintoma**: Acesso funciona de fora mas não de dentro

**Diagnóstico**:
```
1. Verificar configuração:
   System → Advanced → Firewall & NAT
   - NAT Reflection: NAT + Proxy

2. Verificar DNS:
   - DNS interno deve resolver para IP público
   - Ou usar Split DNS (interno resolve para IP privado)

3. Testar:
   curl http://192.168.31.100 (de cliente interno)
```

**Solução**:
- Ativar NAT Reflection
- Ou configurar Split DNS (recomendado para performance)

### Conexões NAT ficam presas

**Sintoma**: Não consigo reconectar após timeout

**Diagnóstico**:
```
Diagnostics → States → Reset States

Ou via CLI:
pfctl -F states
```

**Solução**:
- Ajustar timeouts:
  ```
  System → Advanced → Firewall & NAT
  Firewall Optimization: Conservative
  ```

---

## 📈 Estatísticas e Monitorização

### Ver Utilização NAT

```
Status → System Logs → Firewall → NAT

Filtrar por:
- Port forwards específicos
- IPs origem
- Timestamps
```

### ntopng - Análise Detalhada

```
Services → ntopng

Flows → Filters:
- Protocol: TCP
- Port: 25, 80, 443, etc.
- Interface: WAN

Ver:
- Bandwidth usage
- Top talkers
- Geographic distribution
```

### Comandos CLI Úteis

```bash
# Ver regras NAT
pfctl -s nat

# Ver estados com NAT
pfctl -s state | grep NAT

# Estatísticas NAT
pfctl -s info | grep -i nat

# Ver tabelas de NAT
pfctl -t -T show

# Reset todas as conexões NAT (CUIDADO!)
pfctl -F states
```

---

## 📊 Resumo de Configuração NAT

### Estatísticas

| Tipo | Quantidade | Descrição |
|------|------------|-----------|
| **Outbound NAT** | 4 regras | Automático (LAN, DMZ, VPN) |
| **Port Forwards** | 11 regras | Serviços públicos |
| **1:1 NAT** | 0 regras | Não utilizado |
| **Redirecionamentos** | 1 regra | Mailcow → Webserver |

### Serviços Públicos (Port Forwards)

| Serviço | Portas | Destino | Tráfego Estimado |
|---------|--------|---------|------------------|
| **Mailcow** | 8 portas | 10.0.0.20 | Alto |
| **Webserver** | 2 portas | 10.0.0.30 | Muito Alto |
| **PBS** | 1 porta | 192.168.1.30 | Baixo (restrito) |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2024/2025 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

## 📖 Referências

- [pfSense NAT Documentation](https://docs.netgate.com/pfsense/en/latest/nat/index.html)
- [Port Forward Configuration](https://docs.netgate.com/pfsense/en/latest/nat/port-forwards.html)
- [Outbound NAT](https://docs.netgate.com/pfsense/en/latest/nat/outbound.html)
- [NAT Reflection](https://docs.netgate.com/pfsense/en/latest/nat/reflection.html)

---

<div align="center">

**[⬅️ Voltar: Regras de Firewall](04-regras-firewall.md)** | **[Índice](README.md)** | **[Próximo: OpenVPN ➡️](06-openvpn.md)**

</div>

---

*Última atualização: Dezembro 2024*
