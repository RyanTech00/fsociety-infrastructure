# 📊 Netdata Cloud - Monitorização em Tempo Real

> **Plataforma de Observabilidade da Infraestrutura FSociety**  
>  
> Guia completo de implementação, configuração e utilização do Netdata Cloud para monitorização centralizada de 6 servidores.

---

## 📋 Índice

1. [Justificação da Escolha](#-justificação-da-escolha)
2. [Implementação](#-implementação)
3. [Dashboard Centralizado](#-dashboard-centralizado)
4. [Sistema de Alertas](#-sistema-de-alertas)
5. [Inteligência Artificial](#-inteligência-artificial)
6. [Métricas por Serviço](#-métricas-por-serviço)
7. [Integração com Ecossistema](#-integração-com-ecossistema)
8. [Troubleshooting](#-troubleshooting)

---

## 🎯 Justificação da Escolha

### Problema a Resolver

A operação de infraestruturas distribuídas apresenta um desafio fundamental: **como manter visibilidade sobre o estado de múltiplos sistemas heterogéneos sem sobrecarregar a equipa técnica?**

Falhas não detetadas podem propagar-se silenciosamente, resultando em:
- 🔴 Indisponibilidade de serviços
- 💾 Perda de dados
- ⏱️ Tempo de resposta elevado a incidentes

### Por que Netdata Cloud?

Segundo as recomendações do **NIST 800-53** para gestão de infraestruturas, sistemas de monitorização devem proporcionar visibilidade contínua com impacto mínimo nos recursos monitorizados.

#### Fatores Diferenciadores

| Critério | Netdata Cloud | Benefício |
|----------|---------------|-----------|
| **Deployment** | <5 min/servidor | Setup rápido sem complexidade |
| **Configuração** | Zero-config | Auto-descoberta de 800+ serviços |
| **Custo** | Tier gratuito completo | Viável para contexto académico |
| **Performance** | 1-3% CPU, 150MB RAM | Overhead reduzido |
| **Granularidade** | 1 segundo | Detecção de anomalias transientes |
| **Interface** | Dashboard centralizado | Visão agregada de toda a infraestrutura |

### Comparação com Alternativas

| Feature | Netdata | Prometheus+Grafana | Zabbix | Datadog |
|---------|---------|-------------------|--------|---------|
| Setup Time | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Auto-discovery | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Custo | Grátis | Grátis | Grátis | Pago |
| AI Insights | ⭐⭐⭐⭐ | ❌ | ❌ | ⭐⭐⭐⭐⭐ |
| Mobile App | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🚀 Implementação

O processo de deployment seguiu **três fases**:

### Fase 1: Criação do Space

1. **Aceder ao portal:** https://app.netdata.cloud
2. **Registo com email institucional:** `user@estg.ipp.pt`
3. **Criar Space:** "FSociety Infrastructure"
4. **Obter token de claiming:** Token temporário gerado automaticamente

```bash
# Exemplo de token (expira em 24h)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
ROOM_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Fase 2: Instalação Automatizada

Em cada servidor Ubuntu, executar o script oficial:

```bash
# Download do script de instalação
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh

# Instalação com claiming automático
sh /tmp/netdata-kickstart.sh --stable-channel \
  --claim-token $TOKEN \
  --claim-rooms $ROOM_ID \
  --claim-url https://app.netdata.cloud
```

#### O que o Script Faz

1. ✅ Instala dependências necessárias
2. ✅ Compila o Netdata (≈5 minutos)
3. ✅ Configura comunicação MQTT over TLS 1.3
4. ✅ Regista o servidor no Cloud
5. ✅ Ativa atualizações automáticas

#### Segurança da Comunicação

- **Protocolo:** MQTT over TLS 1.3
- **Encriptação:** End-to-end
- **Autenticação:** Token-based
- **Integridade:** Garantida por TLS

> 🔒 A utilização de MQTT sobre TLS garante que a comunicação entre agentes e cloud mantém confidencialidade e integridade (Tanenbaum, 2021).

### Fase 3: Validação

```bash
# Verificar status do serviço
systemctl status netdata

# Verificar logs
journalctl -u netdata -f

# Testar acesso local
curl http://localhost:19999/api/v1/info
```

#### Checklist de Validação

- [ ] Serviço `netdata` ativo e enabled
- [ ] Sem erros nos logs
- [ ] Servidor aparece no dashboard Cloud com status "Live"
- [ ] Tempo de aparição: <60 segundos

---

## 📊 Dashboard Centralizado

### Visão Geral

![Netdata Dashboard](../../images/netdata-all-nodes.png)

O dashboard centralizado apresenta:

- **Visão agregada** dos 6 servidores
- **Métricas em tempo real:** CPU, RAM, Load, Disk I/O
- **Status de conectividade:** Live / Offline / Stale
- **Alertas ativos** por servidor

### Estrutura do Dashboard

```
┌─────────────────────────────────────────────────────────┐
│  FSociety Infrastructure                                │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Overview                                       │    │
│  │  • Total Nodes: 6/6 online                      │    │
│  │  • Active Alerts: 3                             │    │
│  │  • Average Load: 2.5                            │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ dc.fsociety  │  │ files.fsociety│  │ mail.fsociety│ │
│  │ CPU: 19%     │  │ CPU: 27%      │  │ I/O: 155KB/s │ │
│  │ Load: 2.0    │  │ Containers: 9 │  │ Uptime: 15d  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Métricas Iniciais Observadas

#### dc.fsociety.pt (Domain Controller)

```yaml
CPU Usage: 19%
Load Average: 2.0
Services Auto-discovered:
  - Samba AD DC
  - MySQL Server
  - FreeRADIUS
Status: Operacional
```

#### files.fsociety.pt (Fileserver)

```yaml
CPU Usage: 27%
Docker Containers: 9
Container Metrics: Individualizadas
Status: Operacional
```

#### mail.fsociety.pt (Email Server)

```yaml
Disk I/O: 155 KiB/s
Storage Type: Maildir (comportamento típico)
Reason: 1 ficheiro por email
Status: Operacional
```

---

## 🔔 Sistema de Alertas

### Alertas por Email

![Netdata Alert Email](../../images/netdata-alert-email.png)

#### Anatomia de um Alerta

```
From: Netdata Cloud <alerts@netdata.cloud>
To: user@estg.ipp.pt
Subject: ⚠️ [WARNING] dc.fsociety.pt - System requires reboot

┌─────────────────────────────────────────────┐
│ ALERT DETAILS                               │
├─────────────────────────────────────────────┤
│ Node:      dc.fsociety.pt                   │
│ Alert:     System requires reboot           │
│ Severity:  Warning                          │
│ Triggered: 2024-12-06 14:30:15 UTC         │
│ Reason:    Package updates installed        │
└─────────────────────────────────────────────┘

Recommended Action:
Schedule reboot during maintenance window to apply updates.
```

#### Exemplo Real

Durante a implementação, foi recebido um alerta automático:

- **Trigger:** Instalação do próprio Netdata
- **Causa:** Atualização de múltiplos packages
- **Severidade:** Warning
- **Ação tomada:** Reboot agendado para janela de manutenção
- **Resultado:** ✅ Interrupção não programada evitada

### Aplicação Mobile

![Netdata Mobile App](../../images/netdata-mobile-alerts1.png)

#### Funcionalidades

- 📱 **Push Notifications:** Alertas críticos em tempo real
- 📊 **Visualização de métricas:** Gráficos interativos
- 🔍 **Filtros:** Por criticidade, servidor, tipo
- 🔔 **Gestão de alertas:** Acknowledge, snooze, resolve

#### Impacto no MTTD

| Método | MTTD | Contexto |
|--------|------|----------|
| **Descoberta passiva** | Horas | Administrador acede ao sistema |
| **Notificação push** | Segundos | Alerta enviado automaticamente |

**Redução:** De horas para segundos = **99%+ de melhoria**

---

## 🤖 Inteligência Artificial

### AI Insights Dashboard

![AI Insights](../..images/netdata-ai-insights.png)

O módulo de IA representa uma evolução de **monitorização reativa** para **observabilidade proativa**.

### Funcionalidades de Machine Learning

#### 1. Anomaly Detection

Detecção de comportamentos anómalos antes de se tornarem críticos:

```python
# Exemplo de padrão detetado
Pattern: Memory degradation
Baseline: 1418 MiB available
Current: 179 MiB available
Change: -87% in 22 hours
Classification: P0 (Critical)
```

#### 2. Capacity Planning

Predição de tendências baseada em histórico:

```python
# Exemplo de predição
Resource: Disk Space
Current: 65% used
Trend: +2.5% per week
Prediction: Full in 14 weeks
Recommendation: Plan expansion
```

#### 3. Root Cause Analysis

Análise automatizada quando alertas disparam:

```python
# Exemplo de análise
Alert: High CPU usage
Correlations found:
  - Docker container X: +45% CPU
  - Process Y: 15 threads spawned
  - Network I/O: +200%
Root Cause: Container misconfiguration
```

---

## 📈 Case Study: Análise de 7 Dias

### Contexto

- **Período analisado:** 168 horas (7 dias completos)
- **Servidores:** 6 nodes
- **Data points:** ≈806.400 métricas
- **Tempo de análise:** 45 segundos
- **Equivalente manual:** 4-6 horas/admin

### Insights Identificados

#### Insight #1: Memory Exhaustion (P0 - Crítico)

```yaml
Server: files.fsociety.pt
Pattern: Progressive memory degradation
Timeline:
  - Day 1: 1418 MiB available
  - Day 2: 179 MiB available (22h later)
  - Degradation: 87% reduction
Correlations:
  - Swap usage: 31.75% (RAM em swap)
  - I/O wait: Peak de 42.15%
  - Pattern: Swap thrashing detected
Recommended Actions:
  1. Identify memory leaks with `ps aux --sort=-%mem`
  2. Review Docker container memory limits
  3. Consider RAM upgrade if persistent
  4. Implement swap optimization
```

#### Insight #2: Coordinated I/O Spike (P1 - Alto)

```yaml
Event: Simultaneous I/O saturation
Affected: All 6 servers
Timeframe: 08:56-09:12 UTC (16 minutes)
Pattern: Daily occurrence
Root Cause Analysis:
  - Backup jobs scheduled simultaneously
  - No staggering implemented
  - Network bandwidth saturated
Impact:
  - Service degradation during window
  - Backup completion time: 2.5x longer
Recommendation:
  - Implement staggered backups
  - Interval: 15-30 minutes between servers
  - Expected improvement: 60% faster completion
```

#### Insight #3: Optimization Opportunities (P2)

```yaml
Findings:
  1. Unused services consuming resources
  2. Suboptimal cache configurations
  3. Non-critical processes during peak hours
Potential Savings:
  - CPU: ~12%
  - RAM: ~800 MiB
  - I/O: ~25%
```

### Valor da Análise

- ⏱️ **Tempo economizado:** 4-6 horas de análise manual
- 🎯 **Precisão:** Correlações automatizadas impossíveis manualmente
- 📊 **Escalabilidade:** Análise de 806K+ métricas em segundos
- 💡 **Proatividade:** Problemas identificados antes de incidentes

---

## 🔍 Métricas por Serviço

### Auto-Discovery

O Netdata implementa auto-discovery de **800+ integrações**, monitorizando:

- ✅ Recursos de hardware (CPU, RAM, Disco, Rede)
- ✅ Serviços de sistema (systemd, cron, logs)
- ✅ Aplicações específicas (databases, web servers, etc.)

### Domain Controller (dc.fsociety.pt)

```yaml
Samba AD DC:
  - SMB sessions: Active connections
  - LDAP operations/s: Binds, searches, modifications
  - Replication status: Partner sync status

MySQL Server:
  - Queries by type: SELECT, INSERT, UPDATE, DELETE
  - Connection pool: Active, idle, waiting
  - Slow query log: Queries >1s

FreeRADIUS:
  - Authentication requests: Accept, reject, challenge
  - Accounting packets: Start, stop, update
  - Client statistics: Per-client metrics
```

### Email Server (mail.fsociety.pt)

```yaml
Postfix:
  - Queue size: Current messages
  - Alerts: >100 messages = Warning
  - Delivery rate: Messages/second
  - Bounce rate: Failed deliveries

Dovecot:
  - IMAP sessions: Active connections
  - POP3 sessions: Active connections
  - Login rate: Successful/failed

Storage:
  - Maildir I/O: Read/write operations
  - File count: Total emails stored
  - Directory operations: IOPS
```

### Fileserver (files.fsociety.pt)

```yaml
Docker Containers: (9 individualizados)
  Container 1 - Nextcloud:
    - CPU: Per-container utilization
    - Memory: RSS, cache, swap
    - Network: Rx/Tx bytes
    - Disk I/O: Read/write ops
  
  Container 2 - Zammad:
    - [same metrics structure]
  
  [... 7 more containers]
```

![App Metrics](../../images/netdata-apps-metrics.png)

### Benefício da Granularidade

> 💡 **Visibilidade end-to-end:** Problemas frequentemente manifestam-se como degradação de performance de aplicações **antes** de saturação de recursos físicos.

Exemplo:
```
Sintoma: Website lento
Métrica hardware: CPU 45% (normal)
Métrica aplicacional: Nginx worker stuck
Root cause: Configuração de worker_processes incorreta
```

---

## 🔗 Integração com Ecossistema

### Divisão de Responsabilidades

```
┌──────────────────────────────────────────────────────┐
│               Ecossistema de Administração           │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────┐  ┌──────────────────────────┐   │
│  │    Cockpit     │  │    Netdata Cloud         │   │
│  │  :9090         │  │  app.netdata.cloud       │   │
│  │                │  │                          │   │
│  │ • Services     │  │ • Monitoring             │   │
│  │ • Terminal     │  │ • Alerts                 │   │
│  │ • Storage      │  │ • AI Insights            │   │
│  │ • Updates      │  │ • Mobile App             │   │
│  └────────────────┘  └──────────────────────────┘   │
│                                                      │
│  ┌────────────────┐  ┌──────────────────────────┐   │
│  │ Netdata Local  │  │   Mobile App             │   │
│  │ :19999         │  │   iOS/Android            │   │
│  │                │  │                          │   │
│  │ • Deep dive    │  │ • Push notifications     │   │
│  │ • Debugging    │  │ • On-the-go monitoring   │   │
│  └────────────────┘  └──────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### Quando Usar Cada Ferramenta

| Cenário | Ferramenta | Razão |
|---------|-----------|-------|
| Reiniciar serviço | Cockpit | Interface administrativa |
| Ver tendências de CPU | Netdata Cloud | Visão agregada |
| Debug de processo específico | Netdata Local | Granularidade máxima |
| Alerta fora de horas | Mobile App | Notificações push |

---

## ⚠️ Troubleshooting

### Problemas Comuns

#### 1. Servidor não aparece no Cloud

```bash
# Verificar status do claiming
sudo netdata-claim.sh -status

# Re-claim se necessário
sudo netdata-claim.sh -token=TOKEN -rooms=ROOM_ID \
  -url=https://app.netdata.cloud

# Reiniciar serviço
sudo systemctl restart netdata
```

#### 2. Métricas não atualizam

```bash
# Verificar logs
sudo journalctl -u netdata -n 100 -f

# Verificar conectividade
curl https://app.netdata.cloud

# Testar API local
curl http://localhost:19999/api/v1/info
```

#### 3. Alertas não chegam

1. Verificar configuração de email no dashboard Cloud
2. Confirmar notificações na app móvel
3. Verificar pasta spam/junk
4. Testar alerta manual: **Actions → Test notification**

#### 4. Alto uso de recursos

```bash
# Desativar plugins não necessários
sudo nano /etc/netdata/netdata.conf

[plugins]
    python.d = no     # Se não usar Python plugins
    charts.d = no     # Se não usar Charts plugins
    node.d = no       # Se não usar Node plugins

# Reduzir frequência de coleta (não recomendado)
[global]
    update every = 2  # Default: 1 second
```

---

## 📊 Estatísticas de Utilização

### Recursos Consumidos

| Servidor | CPU | RAM | Disco | Rede |
|----------|-----|-----|-------|------|
| dc.fsociety.pt | 1.5% | 145 MB | 200 MB | ~50 KB/s |
| files.fsociety.pt | 2.8% | 168 MB | 200 MB | ~75 KB/s |
| mail.fsociety.pt | 1.2% | 138 MB | 200 MB | ~40 KB/s |
| **Média** | **1.8%** | **150 MB** | **200 MB** | **55 KB/s** |

### Métricas de Observabilidade

- **Servidores monitorizados:** 6/6 (100%)
- **Serviços auto-descobertos:** 45+
- **Métricas coletadas:** 800+/servidor
- **Granularidade temporal:** 1 segundo
- **Latência de alertas:** <60 segundos
- **Uptime do sistema:** 99.9%

---

## 🎓 Referências

1. **Netdata Documentation**
   - https://learn.netdata.cloud/

2. **NIST 800-53 Rev. 5**
   - Security and Privacy Controls for Information Systems
   - https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final

3. **Tanenbaum, A. S., & Wetherall, D. J. (2021)**
   - *Computer Networks* (6th ed.)
   - Capítulo sobre segurança de comunicações

4. **Site Reliability Engineering (Google)**
   - https://sre.google/books/

---

<div align="center">

**[⬅️ Voltar](README.md)** | **[📊 Dashboard](https://app.netdata.cloud)** | **[📱 Mobile App](https://apps.apple.com/app/netdata/)**

</div>

---

*Última atualização: Dezembro 2025*
