# 🔧 Manutenção - Proxmox VE

> Guia de manutenção do Proxmox VE, incluindo atualizações, monitorização, logs e troubleshooting.

---

## 📋 Visão Geral

A manutenção regular do Proxmox VE garante estabilidade, segurança e performance ótima da infraestrutura de virtualização.

### Tarefas de Manutenção

| Frequência | Tarefa |
|------------|--------|
| **Diária** | Verificar status das VMs e backups |
| **Semanal** | Revisar logs, verificar espaço em disco |
| **Mensal** | Atualizações de segurança, limpeza de backups antigos |
| **Trimestral** | Atualizações major, teste de restores |
| **Anual** | Auditoria completa, planeamento de capacidade |

---

## 🔄 Atualizações

### Verificar Versão Atual

```bash
# Versão do Proxmox VE
pveversion

# Saída esperada:
# pve-manager/9.0.3/...

# Versão detalhada de todos os componentes
pveversion -v

# Kernel
uname -r
# 6.14.8-2-pve
```

### Repositórios

#### Ver Repositórios Configurados

```bash
# Ver repositórios ativos
cat /etc/apt/sources.list
cat /etc/apt/sources.list.d/*.list

# Verificar se enterprise está desativado
cat /etc/apt/sources.list.d/pve-enterprise.list
# Deve estar comentado: #deb https://enterprise.proxmox.com/...
```

#### Configuração Recomendada (No-Subscription)

```bash
# /etc/apt/sources.list
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib

# Proxmox VE no-subscription
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription

# /etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
```

### Processo de Atualização

#### Atualizações de Segurança (Mensal)

```bash
# Atualizar lista de pacotes
apt update

# Ver atualizações disponíveis
apt list --upgradable

# Atualizar pacotes
apt upgrade -y

# Atualizar sistema (inclui kernel)
apt dist-upgrade -y

# Limpar pacotes antigos
apt autoremove -y
apt autoclean

# Verificar se reboot é necessário
# Se kernel foi atualizado, reiniciar:
reboot
```

#### Atualizações Major (Trimestral)

```bash
# Antes de atualizar:
# 1. Backup da configuração
tar czf /root/pve-backup-$(date +%Y%m%d).tar.gz /etc/pve

# 2. Backup de VMs críticas
vzdump --all --storage pbs-store --mode snapshot

# 3. Verificar changelog
# https://pve.proxmox.com/wiki/Roadmap

# 4. Atualizar
apt update
apt dist-upgrade

# 5. Verificar logs
journalctl -xe

# 6. Reiniciar se necessário
reboot

# 7. Verificar VMs após reboot
qm list
pvesh get /cluster/resources
```

### Atualizações via Web UI

1. **Node → Updates**

2. Clicar em **Refresh**

3. Ver lista de atualizações disponíveis

4. Clicar em **Upgrade** (terminal interativo)

5. Seguir instruções na tela

---

## 📊 Monitorização

### Dashboard Web UI

**Node → Summary**

Métricas visíveis:
- **CPU Usage**: Utilização de CPU
- **Memory**: RAM utilizada/total
- **Swap**: Swap utilizado
- **Storage**: Espaço em disco
- **Network**: Tráfego de rede
- **Uptime**: Tempo desde último boot

### Monitorização via CLI

#### Status Geral

```bash
# Status do node
pvesh get /nodes/mail/status

# Status de todas as VMs
qm list

# Status de storage
pvesm status

# Status de serviços
systemctl status pve-cluster
systemctl status pvedaemon
systemctl status pveproxy
systemctl status pvestatd
```

#### CPU e Memória

```bash
# Top (processos)
top

# Htop (melhor visualização)
htop

# Uso de CPU por core
mpstat -P ALL 2

# Uso de memória detalhado
free -h
cat /proc/meminfo
```

#### Disco e I/O

```bash
# Espaço em disco
df -h

# Uso de inodes
df -i

# I/O stats
iostat -x 2

# VMs com mais I/O
iotop

# SMART status dos discos
smartctl -H /dev/sda
smartctl -H /dev/nvme0n1
smartctl -a /dev/sda | grep -i error
```

#### Rede

```bash
# Interfaces de rede
ip addr show

# Estatísticas de rede
ip -s link

# Tráfego em tempo real
iftop

# Conexões ativas
ss -tuln

# Bridges
brctl show
```

### Alertas e Notificações

#### Configurar Alertas de Email

```bash
# Editar configuração
nano /etc/pve/datacenter.cfg

# Adicionar:
email_from: proxmox@fsociety.pt
mailto: admin@fsociety.pt
```

#### Script de Monitorização

```bash
# Criar script de monitorização
nano /usr/local/bin/pve-health-check.sh
```

```bash
#!/bin/bash
# Proxmox VE Health Check
# Executar diariamente via cron

MAILTO="admin@fsociety.pt"
HOSTNAME=$(hostname)
REPORT="/tmp/pve-health-report.txt"

# Limpar relatório anterior
> $REPORT

echo "=== Proxmox VE Health Check ===" >> $REPORT
echo "Hostname: $HOSTNAME" >> $REPORT
echo "Date: $(date)" >> $REPORT
echo "" >> $REPORT

# CPU
echo "=== CPU ===" >> $REPORT
uptime >> $REPORT
echo "" >> $REPORT

# Memória
echo "=== Memory ===" >> $REPORT
free -h >> $REPORT
echo "" >> $REPORT

# Disco
echo "=== Disk Space ===" >> $REPORT
df -h | grep -E "^/dev|^Filesystem" >> $REPORT
echo "" >> $REPORT

# Storage Pools
echo "=== Storage Pools ===" >> $REPORT
pvesm status >> $REPORT
echo "" >> $REPORT

# VMs Status
echo "=== VMs Status ===" >> $REPORT
qm list >> $REPORT
echo "" >> $REPORT

# Serviços
echo "=== Services ===" >> $REPORT
systemctl status pve-cluster | grep Active >> $REPORT
systemctl status pvedaemon | grep Active >> $REPORT
systemctl status pveproxy | grep Active >> $REPORT
echo "" >> $REPORT

# Alertas
ALERTS=0

# Verificar espaço em disco > 80%
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "ALERT: Root filesystem at ${DISK_USAGE}%" >> $REPORT
    ALERTS=$((ALERTS+1))
fi

# Verificar memória > 90%
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "ALERT: Memory usage at ${MEM_USAGE}%" >> $REPORT
    ALERTS=$((ALERTS+1))
fi

# Enviar email se houver alertas
if [ $ALERTS -gt 0 ]; then
    mail -s "ALERT: Proxmox VE Health Check - $HOSTNAME" $MAILTO < $REPORT
else
    mail -s "OK: Proxmox VE Health Check - $HOSTNAME" $MAILTO < $REPORT
fi
```

```bash
# Tornar executável
chmod +x /usr/local/bin/pve-health-check.sh

# Agendar execução diária
cat >> /etc/cron.d/pve-health-check << EOF
# Proxmox health check diário às 08:00
0 8 * * * root /usr/local/bin/pve-health-check.sh
EOF
```

---

## 📜 Logs

### Localização dos Logs

| Log | Localização | Descrição |
|-----|-------------|-----------|
| **System** | /var/log/syslog | Logs gerais do sistema |
| **Auth** | /var/log/auth.log | Autenticação e SSH |
| **Daemon** | /var/log/daemon.log | Serviços do sistema |
| **PVE Tasks** | /var/log/pve/tasks/ | Tarefas do Proxmox |
| **Cluster** | /var/log/pve-firewall.log | Firewall do cluster |
| **QEMU** | /var/log/pve/qemu-server/ | Logs de VMs |

### Visualizar Logs

#### Via Web UI

**Node → System → Syslog**
- Ver logs do sistema em tempo real
- Filtrar por serviço ou palavra-chave

**VM → Task History**
- Ver histórico de tarefas da VM
- Logs de start, stop, backup, etc.

#### Via CLI

```bash
# System logs
journalctl -xe

# Logs de hoje
journalctl --since today

# Logs de um serviço
journalctl -u pvedaemon

# Logs de uma VM
tail -f /var/log/pve/qemu-server/102.log

# Tasks ativas
tail -f /var/log/pve/tasks/active

# Logs de backup
grep vzdump /var/log/syslog

# Últimas 100 linhas de auth
tail -100 /var/log/auth.log
```

### Rotação de Logs

```bash
# Configuração logrotate
cat /etc/logrotate.d/proxmox-ve

# Forçar rotação manual
logrotate -f /etc/logrotate.conf

# Ver tamanho dos logs
du -sh /var/log/*
```

---

## 🧹 Limpeza e Otimização

### Limpar Backups Antigos

```bash
# Listar backups
ls -lh /var/lib/vz/dump/

# Remover backups com mais de 30 dias
find /var/lib/vz/dump/ -name "*.vma*" -mtime +30 -delete

# Via Web UI:
# Storage → local → Content
# Selecionar backups antigos → Remove
```

### Limpar Templates e ISOs Não Utilizados

```bash
# Listar ISOs
ls -lh /var/lib/vz/template/iso/

# Remover ISOs antigos
rm /var/lib/vz/template/iso/old-iso.iso

# Listar templates
ls -lh /var/lib/vz/template/cache/
```

### Limpar Logs Antigos

```bash
# Remover logs com mais de 60 dias
find /var/log -name "*.gz" -mtime +60 -delete

# Limpar journal
journalctl --vacuum-time=30d
journalctl --vacuum-size=1G
```

### Otimizar LVM

```bash
# Ver fragmentação
lvs -a -o +seg_count

# Se necessário, desfragmentar (requer downtime das VMs)
# 1. Parar VMs no storage
# 2. Executar:
# lvconvert --merge /dev/pve/data
```

---

## 🔍 Troubleshooting

### VMs Não Iniciam

**Diagnóstico:**

```bash
# Ver logs da VM
tail -f /var/log/pve/qemu-server/<vmid>.log

# Tentar iniciar manualmente
qm start <vmid>

# Ver erros
journalctl -xe | grep <vmid>
```

**Causas comuns:**

1. Storage não disponível
   ```bash
   pvesm status
   mount | grep vz
   ```

2. Lock na VM
   ```bash
   qm unlock <vmid>
   ```

3. Recursos insuficientes
   ```bash
   free -h
   df -h
   ```

### Interface Web Não Acessível

**Diagnóstico:**

```bash
# Verificar serviço
systemctl status pveproxy

# Reiniciar serviço
systemctl restart pveproxy

# Verificar porta 8006
ss -tuln | grep 8006

# Verificar logs
journalctl -u pveproxy
```

### Storage Cheio

**Solução:**

```bash
# Identificar uso
df -h
du -sh /var/lib/vz/*

# Limpar backups antigos
find /var/lib/vz/dump/ -mtime +30 -delete

# Expandir storage se necessário
lvextend -L +50G /dev/pve/root
resize2fs /dev/pve/root
```

### Performance Baixa

**Diagnóstico:**

```bash
# CPU
top
mpstat -P ALL

# Memória
free -h
vmstat 2

# Disco
iostat -x 2
iotop

# Rede
iftop
```

**Soluções:**

1. Reduzir over-provisioning de CPU/RAM
2. Mover VMs para storage mais rápido
3. Aumentar recursos físicos
4. Otimizar configuração de VMs

---

## 📋 Checklist de Manutenção

### Diária

- [ ] Verificar dashboard (VMs running, resources)
- [ ] Verificar backups executados com sucesso
- [ ] Revisar alertas/emails

### Semanal

- [ ] Revisar logs de erro
- [ ] Verificar espaço em disco
- [ ] Verificar utilização de recursos
- [ ] Testar acesso SSH/Web

### Mensal

- [ ] Aplicar atualizações de segurança
- [ ] Limpar backups antigos (> 30 dias)
- [ ] Limpar ISOs/templates não utilizados
- [ ] Verificar SMART dos discos
- [ ] Atualizar documentação

### Trimestral

- [ ] Testar restore de backup
- [ ] Atualizações major do Proxmox
- [ ] Auditoria de segurança
- [ ] Revisão de capacidade
- [ ] Backup da configuração do host

### Anual

- [ ] Planeamento de capacidade
- [ ] Revisão de políticas de backup
- [ ] Auditoria completa
- [ ] Atualização de documentação
- [ ] Renovação de certificados

---

## 📖 Recursos Úteis

### Documentação Oficial

| Recurso | URL |
|---------|-----|
| **Proxmox VE Admin Guide** | https://pve.proxmox.com/pve-docs/pve-admin-guide.html |
| **Proxmox VE API** | https://pve.proxmox.com/pve-docs/api-viewer/ |
| **Proxmox Forum** | https://forum.proxmox.com/ |
| **Proxmox Wiki** | https://pve.proxmox.com/wiki/ |

### Comandos de Referência

```bash
# Ver todas as VMs
qm list

# Ver configuração de VM
qm config <vmid>

# Consola de VM
qm terminal <vmid>

# Snapshot de VM
qm snapshot <vmid> <snapshot-name>

# Restore snapshot
qm rollback <vmid> <snapshot-name>

# Migrar VM (se cluster)
qm migrate <vmid> <target-node>

# Clonar VM
qm clone <vmid> <novo-vmid>
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

**[⬅️ Anterior: Backup](05-backup-config.md)** | **[Índice](README.md)** | **[Próximo: PBS ➡️](../07-proxmox-backup/README.md)**

</div>

---

*Última atualização: Dezembro 2025*
