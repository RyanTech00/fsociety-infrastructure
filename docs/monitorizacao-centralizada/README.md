# 📊 Monitorização Centralizada - FSociety.pt

> **Sistema de Observabilidade em Tempo Real**  
>  
> Documentação completa do sistema de monitorização centralizado da infraestrutura FSociety.pt, incluindo implementação do Netdata Cloud, alertas automatizados e análise preditiva com IA.

---

## 📋 Visão Geral

A infraestrutura FSociety utiliza **Netdata Cloud** como plataforma de monitorização em tempo real dos 6 servidores principais. Esta solução proporciona:

- ✅ **Visibilidade em tempo real** de todos os servidores
- 🔔 **Alertas automatizados** via email e notificações push
- 🤖 **Análise preditiva** com inteligência artificial
- 📱 **Aplicação móvel** para resposta a incidentes
- 🔍 **Auto-descoberta** de mais de 800 serviços

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Netdata Cloud                            │
│              https://app.netdata.cloud                      │
│                 (Dashboard Centralizado)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ MQTT over TLS 1.3
                       │
       ┌───────────────┼───────────────┬─────────────────┐
       │               │               │                 │
       ▼               ▼               ▼                 ▼
┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│ dc.        │  │ files.     │  │ mail.      │  │ web.       │
│ fsociety.pt│  │ fsociety.pt│  │ fsociety.pt│  │ fsociety.pt│
│            │  │            │  │            │  │            │
│ Agent      │  │ Agent      │  │ Agent      │  │ Agent      │
│ :19999     │  │ :19999     │  │ :19999     │  │ :19999     │
└────────────┘  └────────────┘  └────────────┘  └────────────┘
```

**Servidores Monitorizados:**
- dc.fsociety.pt (Domain Controller)
- files.fsociety.pt (Fileserver)
- mail.fsociety.pt (Proxmox Host)
- web.fsociety.pt (Web Server)
- backup.fsociety.pt (Backup Server)
- monitoring.fsociety.pt (VPN/Monitoring)

---

## 🎯 Características Principais

| Característica | Descrição |
|---------------|-----------|
| **Granularidade** | 1 segundo (detecção de anomalias transientes) |
| **Overhead** | 1-3% CPU, ~150MB RAM por servidor |
| **Retenção** | 14 dias (tier gratuito) |
| **Auto-descoberta** | 800+ integrações automáticas |
| **Deployment** | <5 minutos por servidor |
| **Comunicação** | MQTT over TLS 1.3 |

---

## 📚 Índice da Documentação

| # | Documento | Descrição |
|---|-----------|-----------|
| 1 | [Netdata Cloud](01-netdata.md) | Implementação, configuração e utilização do Netdata |

---

## 🚀 Quick Start

### Acesso ao Dashboard

- **Dashboard Centralizado:** https://app.netdata.cloud
- **Agent Local (qualquer servidor):** http://SERVER_IP:19999
- **Aplicação Mobile:** Disponível na App Store e Google Play

### Credenciais

- **Email:** institucional@estg.ipp.pt
- **Space:** FSociety Infrastructure

---

## 📊 Métricas Monitorizadas

### 🖥️ Recursos de Sistema

- **CPU:** Utilização por core, load average, context switches
- **Memória:** RAM, swap, cached, buffers
- **Disco:** I/O por dispositivo, IOPS, latência
- **Rede:** Bandwidth, packets, errors, drops

### 🔧 Serviços Aplicacionais

#### Domain Controller (dc.fsociety.pt)
- Sessões SMB ativas
- Operações LDAP/s (autenticações, pesquisas, binds)
- Queries MySQL segmentadas por tipo
- Pedidos de autenticação FreeRADIUS

#### Email Server (mail.fsociety.pt)
- Postfix queue size
- Sessões Dovecot IMAP/POP3
- I/O específico do armazenamento Maildir

#### Fileserver (files.fsociety.pt)
- Métricas individualizadas de 9 containers Docker
- Utilização de recursos por container

---

## 🔔 Sistema de Alertas

### Canais de Notificação

| Canal | Descrição | Latência |
|-------|-----------|----------|
| **Email** | Alertas com severidade Warning+ | ~1 minuto |
| **Push Mobile** | Notificações críticas | Tempo real |
| **Dashboard** | Visualização de todos os alertas | Tempo real |

### Níveis de Severidade

- 🔴 **Critical:** Requer ação imediata
- 🟡 **Warning:** Requer atenção
- 🔵 **Info:** Informativo

### Alertas Configurados

- System reboot required
- High CPU usage (>80% sustained)
- Memory exhaustion (<10% free)
- Disk space critical (<10%)
- Service down
- Swap thrashing
- I/O saturation

---

## 🤖 Capacidades de IA

O Netdata Cloud integra funcionalidades de machine learning para observabilidade proativa:

### AI Insights

- **Anomaly Detection:** Detecção de padrões anómalos antes de se tornarem críticos
- **Capacity Planning:** Predição de tendências baseada em histórico
- **Root Cause Analysis:** Análise automatizada quando alertas disparam

### Exemplo de Análise

**Case Study: Análise de 7 dias (168 horas)**
- 108 transições de alertas processadas
- 806.400 data points analisados (6 servidores)
- Tempo de análise: 45 segundos
- Equivalente manual: 4-6 horas/administrador

**Insights Identificados:**
- ⚠️ **P0:** Memory exhaustion pattern (87% degradação em 22h)
- ⚠️ **P1:** Coordinated I/O spike (backups não escalonados)
- 💡 **P2:** Oportunidades de otimização

---

## 🔧 Ferramentas Complementares

| Ferramenta | Função | URL |
|------------|--------|-----|
| **Netdata Cloud** | Monitorização centralizada | https://app.netdata.cloud |
| **Netdata Local** | Troubleshooting profundo | http://IP:19999 |
| **Cockpit** | Administração de sistemas | https://IP:9090 |
| **App Mobile** | Resposta a incidentes móvel | iOS/Android |

---

## 📈 Resultados Operacionais

### Métricas Iniciais (Dashboard)

| Servidor | CPU | Load | Disk I/O | Observações |
|----------|-----|------|----------|-------------|
| dc.fsociety.pt | 19% | 2.0 | Normal | Samba AD, MySQL, FreeRADIUS auto-descobertos |
| files.fsociety.pt | 27% | - | Normal | 9 containers Docker individualizados |
| mail.fsociety.pt | - | - | 155 KiB/s | Armazenamento Maildir (I/O típico) |

### Impacto

- ✅ **Deployment:** 6 servidores em ~35 minutos
- ✅ **MTTD:** Reduzido de horas para segundos
- ✅ **Visibilidade:** Comparável a soluções enterprise (Datadog, Dynatrace)
- ✅ **Custo:** Tier gratuito adequado para contexto académico

---

## ⚠️ Limitações Conhecidas

| Limitação | Impacto | Mitigação |
|-----------|---------|-----------|
| Retenção 14 dias | Histórico limitado | Aceitável para académico / Upgrade se necessário |
| pfSense incompatível | Sem monitorização do firewall | Base FreeBSD não suportada |
| AI Insights: 10 créditos/mês | Análises limitadas | Uso estratégico / Upgrade para produção |

---

## 🎓 Informação Académica

| Campo | Informação |
|-------|------------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Unidade Curricular** | Administração de Sistemas II |
| **Ano Letivo** | 2025/2026 |
| **Autores** | Ryan Barbosa, Hugo Correia, Igor Araújo |

---

## 📖 Referências

- [Netdata Cloud Documentation](https://learn.netdata.cloud/)
- [Netdata Agent Documentation](https://learn.netdata.cloud/docs/agent)
- [NIST 800-53 - Security Controls](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- Tanenbaum, A. S., & Wetherall, D. J. (2021). *Computer Networks* (6th ed.)

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../../LICENSE).

---

<div align="center">

**[⬅️ Voltar à Documentação Principal](../index.md)** | **[Próximo: Netdata ➡️](01-netdata.md)**

</div>

---

*Última atualização: Dezembro 2025*
