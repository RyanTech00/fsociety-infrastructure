# 🛡️ Segurança Perimetral FSociety

> A infraestrutura FSociety implementa uma arquitetura de segurança em múltiplas camadas para proteger os serviços contra ameaças externas e internas além da Pfsense.
>
> Este documento consolida toda a configuração de segurança perimetral da organização.

---

## 🏗️ Arquitetura de Segurança em Camadas

A estratégia de defesa em profundidade da FSociety é composta por três camadas complementares:

### 1. **Camada Externa - Cloudflare**
Primeira linha de defesa, operando na edge da rede:
- **WAF (Web Application Firewall)**: Proteção contra ataques web (SQL injection, XSS, etc.)
- **DDoS Protection**: Mitigação de ataques distribuídos de negação de serviço
- **CDN**: Cache global e aceleração de conteúdo
- **SSL/TLS**: Encriptação end-to-end com certificados gerenciados

### 2. **Camada Perimetral - pfSense**
Firewall principal da infraestrutura:
- **Firewall**: Controle de tráfego por regras e políticas
- **NAT**: Tradução de endereços de rede
- **VPN**: Acesso seguro remoto à infraestrutura
- [03-pfsense](../03-pfsense/) - Firewall principal da infraestrutura

### 3. **Camada Interna - CrowdSec**
Sistema de detecção e prevenção de intrusões distribuído:
- **IDS/IPS**: Detecção e bloqueio de comportamentos maliciosos
- **Inteligência Colaborativa**: Partilha de ameaças com a comunidade global
- **Multi-Engine**: 4 engines instalados em servidores críticos

## 📊 Métricas Globais de Segurança

### Cloudflare (últimas 24 horas)
- **Total de Requisições**: 1.03k
- **Ameaças Mitigadas**: 95 (31.65%)
- **Ferramentas de Detecção Ativas**: 8/8

### CrowdSec (últimos 7 dias)
- **Ataques Prevenidos**: 16.3k
- **Decisões Ativas**: 15 IPs banidos
- **Tráfego Malicioso Bloqueado**: 2.53 MB (6.61k pacotes)
- **Recursos Poupados**: 360.51 MB de tráfego outgoing

### Distribuição de Ameaças Bloqueadas
| Tipo de Ataque | Quantidade | Percentagem |
|----------------|------------|-------------|
| HTTP Scan | 3.37k | 20.8% |
| HTTP Exploit | 3.03k | 18.6% |
| HTTP Bruteforce | 2.95k | 18.1% |
| HTTP Crawl | 2.73k | 16.8% |
| VM Management Exploit | 2.13k | 13.1% |

## 📁 Estrutura da Documentação

```
docs/09-seguranca/
├── README.md           # Este documento - visão geral
├── 01-cloudflare.md    # Configuração completa do Cloudflare
└── 02-crowdsec.md      # CrowdSec consolidado (4 engines)
```

### [01-cloudflare.md](01-cloudflare.md)
Documentação completa da configuração Cloudflare:
- Configuração de domínio e DNS
- SSL/TLS e certificados
- Funcionalidades de segurança ativas
- WAF e regras personalizadas
- Estatísticas e métricas

### [02-crowdsec.md](02-crowdsec.md)
Documentação consolidada do CrowdSec:
- Organização e engines registados
- Scenarios e bouncers por servidor
- Métricas de remediação
- Decisões ativas e blocklists
- CVEs detectados e mitigados

## 🎯 Filosofia de Segurança

A abordagem da FSociety segue os princípios de:

1. **Defesa em Profundidade**: Múltiplas camadas independentes
2. **Zero Trust**: Verificação contínua em todas as camadas
3. **Inteligência Colaborativa**: Partilha de ameaças com a comunidade
4. **Monitorização Ativa**: Métricas e alertas em tempo real
5. **Automação**: Resposta automática a incidentes

## 🔗 Links Úteis

- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [CrowdSec Console](https://app.crowdsec.net)
- [pfSense Web Interface](https://pfsense.fsociety.pt)

## 📚 Documentação Relacionada

- [08-mailcow](../08-mailcow/) - Segurança do servidor de email
- [04-file-server](../04-file-server/) - Segurança do servidor de ficheiros
- [05-web-server](../05-web-server/) - Segurança do servidor web
- [06-domain-server](../06-domain-server/) - Segurança do controlador de domínio

---
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

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Configuração Cloudflare ➡️](01-cloudflare.md)**

</div>

---

*Última atualização: Dezembro 2025*
