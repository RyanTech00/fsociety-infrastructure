# 🦠 Antivírus ClamAV

> **Proteção antivírus integrada para deteção de malware e vírus em emails**

---

## 📋 Índice

1. [Sobre o ClamAV](#-sobre-o-clamav)
2. [Integração com Mailcow](#-integração-com-mailcow)
3. [Atualizações de Assinaturas](#-atualizações-de-assinaturas)
4. [Monitorização e Logs](#-monitorização-e-logs)
5. [Configuração Avançada](#-configuração-avançada)
6. [Testes e Verificação](#-testes-e-verificação)
7. [Troubleshooting](#-troubleshooting)

---

## 🛡️ Sobre o ClamAV

**ClamAV** (Clam AntiVirus) é um motor antivírus open-source usado para detetar trojans, vírus, malware e outras ameaças.

### Características

| Característica | Descrição |
|----------------|-----------|
| **Versão** | Latest (via ghcr.io/mailcow/clamd:1.71) |
| **Base de Dados** | Main, Daily, Bytecode signatures |
| **Engine** | Libclamav |
| **Performance** | Scan rápido, baixo uso de CPU |
| **Atualizações** | Automáticas via freshclam |
| **Formato** | Emails, anexos, arquivos comprimidos |

### Arquitetura

```
┌─────────────────────────────────────────────────┐
│            POSTFIX (Recebe Email)               │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│               RSPAMD                            │
│      (Orchestração Anti-spam/Vírus)             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│              CLAMD (ClamAV Daemon)              │
│  ┌──────────────┐  ┌──────────────┐            │
│  │  Main.cvd    │  │   Daily.cvd  │            │
│  │ (Signatures) │  │  (Updates)   │            │
│  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Bytecode.cvd │  │   Custom     │            │
│  │  (Advanced)  │  │ Signatures   │            │
│  └──────────────┘  └──────────────┘            │
│                                                 │
│  Scan Result: CLEAN / VIRUS FOUND               │
└────────────────┬────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
┌──────────┐          ┌──────────┐
│ DELIVER  │          │ QUARANTINE│
│          │          │ or REJECT │
└──────────┘          └──────────┘
```

---

## 🔗 Integração com Mailcow

### Container ClamAV

```bash
# Ver status do container
sudo docker compose ps clamd-mailcow

# Logs em tempo real
sudo docker compose logs -f clamd-mailcow
```

### Integração com Rspamd

O ClamAV é chamado pelo Rspamd para cada email:

```bash
# Ver configuração no Rspamd
sudo docker compose exec rspamd-mailcow \
  rspamadm configdump antivirus
```

**Saída esperada:**
```lua
antivirus {
  clamav {
    servers = "clamd-mailcow:3310";
    symbol = "CLAM_VIRUS";
    type = "clamav";
  }
}
```

### Ação em Caso de Vírus

```bash
# Configurar ação no Rspamd
sudo nano /opt/mailcow-dockerized/data/conf/rspamd/local.d/antivirus.conf
```

```lua
clamav {
  # Socket do ClamAV
  servers = "clamd-mailcow:3310";
  
  # Símbolo adicionado se vírus encontrado
  symbol = "CLAM_VIRUS";
  
  # Tipo de scanner
  type = "clamav";
  
  # Timeout
  timeout = 15.0;
  
  # Log pattern
  log_clean = true;
  
  # Ação: reject (rejeitar) ou quarantine
  action = "reject";
}
```

---

## 🔄 Atualizações de Assinaturas

### Freshclam - Atualizador Automático

O ClamAV atualiza automaticamente as bases de dados de vírus via **freshclam**.

```bash
# Ver configuração do freshclam
sudo docker compose exec clamd-mailcow cat /etc/clamav/freshclam.conf
```

**Configuração padrão:**
```
# Servidor de updates
DatabaseMirror database.clamav.net

# Frequência de checks
Checks 24

# Diretório das bases de dados
DatabaseDirectory /var/lib/clamav
```

### Forçar Atualização Manual

```bash
# Atualizar manualmente
sudo docker compose exec clamd-mailcow freshclam

# Ver resultado
sudo docker compose exec clamd-mailcow freshclam --version
```

**Saída esperada:**
```
ClamAV 1.0.x/xxxx/Mon Dec  2 xx:xx:xx 2024
```

### Ver Versão das Bases de Dados

```bash
# Listar ficheiros CVD
sudo docker compose exec clamd-mailcow ls -lh /var/lib/clamav/

# Ver informação detalhada
sudo docker compose exec clamd-mailcow sigtool --info /var/lib/clamav/main.cvd
```

**Ficheiros de assinaturas:**
- `main.cvd` - Base principal (~100MB)
- `daily.cvd` - Atualizações diárias (~1-5MB)
- `bytecode.cvd` - Signatures compiladas
- `*.cld` - Bases incrementais

### Frequência de Atualizações

| Base | Frequência | Tamanho Aproximado |
|------|------------|-------------------|
| Main | Semanal | 100 MB |
| Daily | Diário | 1-5 MB |
| Bytecode | Semanal | 1 MB |

---

## 📊 Monitorização e Logs

### Health Status

```bash
# Verificar health do container
sudo docker compose ps clamd-mailcow

# Deve mostrar: Up, healthy
```

### Logs de Scan

```bash
# Ver logs do ClamAV
sudo docker compose logs clamd-mailcow --tail=100

# Filtrar por vírus encontrados
sudo docker compose logs clamd-mailcow | grep "FOUND"

# Ver apenas clean scans
sudo docker compose logs clamd-mailcow | grep "OK"
```

**Exemplo de log limpo:**
```
clamd-mailcow | /tmp/email.eml: OK
```

**Exemplo de vírus encontrado:**
```
clamd-mailcow | /tmp/email.eml: Win.Test.EICAR_HDB-1 FOUND
```

### Estatísticas

```bash
# Ver estatísticas via clamdscan
sudo docker compose exec clamd-mailcow clamdscan --version

# Testar conexão ao daemon
sudo docker compose exec clamd-mailcow \
  clamdscan --ping 3 --wait
```

### Integração com Watchdog

O Watchdog do Mailcow monitoriza o ClamAV:

```bash
# Ver status no watchdog
curl -s https://mail.fsociety.pt/api/v1/get/status/containers \
  -H "X-API-Key: <api_key>" | jq '.[] | select(.name=="clamd-mailcow")'
```

---

## ⚙️ Configuração Avançada

### Limites de Scan

```bash
# Editar configuração do ClamAV
sudo nano /opt/mailcow-dockerized/data/conf/clamav/clamd.conf
```

**Parâmetros importantes:**
```
# Tamanho máximo de ficheiro a escanear (50 MB)
MaxFileSize 52428800

# Tamanho máximo de scan (100 MB)
MaxScanSize 104857600

# Máximo de ficheiros em arquivo
MaxFiles 10000

# Recursão em arquivos
MaxRecursion 16

# Timeout de scan (5 minutos)
MaxScanTime 300000
```

### Performance Tuning

```bash
# Ajustar recursos no docker-compose.override.yml
sudo nano /opt/mailcow-dockerized/docker-compose.override.yml
```

```yaml
version: '2.1'
services:
  clamd-mailcow:
    mem_limit: 2g
    mem_reservation: 1g
    cpus: 1.0
```

### Desativar Tipos de Scan

```bash
# Em clamd.conf
ScanPE yes          # Executáveis Windows
ScanELF yes         # Executáveis Linux
ScanOLE2 yes        # Documentos Office
ScanPDF yes         # PDFs
ScanHTML yes        # HTML
ScanMail yes        # Emails
ScanArchive yes     # ZIP, RAR, etc.
```

---

## 🧪 Testes e Verificação

### Teste EICAR

EICAR é um ficheiro de teste padrão para antivírus (não é vírus real):

```bash
# Criar ficheiro EICAR
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com

# Testar scan
sudo docker compose exec clamd-mailcow clamdscan /tmp/eicar.com
```

**Resultado esperado:**
```
/tmp/eicar.com: Win.Test.EICAR_HDB-1 FOUND

----------- SCAN SUMMARY -----------
Infected files: 1
Time: 0.001 sec (0 m 0 s)
```

### Testar via Email

1. **Enviar email de teste com anexo EICAR:**
   - De: teste@example.com
   - Para: ryan.barbosa@fsociety.pt
   - Anexo: eicar.com

2. **Verificar rejeição:**

```bash
# Ver logs do Rspamd
sudo docker compose logs rspamd-mailcow | grep EICAR
```

**Resultado esperado:**
```
rspamd: CLAM_VIRUS(15.00)[eicar.com: Win.Test.EICAR_HDB-1]
```

### Scan de Mailbox Existente

```bash
# Escanear mailbox de utilizador
sudo docker compose exec clamd-mailcow \
  clamdscan -r /var/vmail/fsociety.pt/ryan.barbosa/Maildir/

# Scan recursivo de todo o vmail
sudo docker compose exec clamd-mailcow \
  clamdscan -r /var/vmail/
```

---

## 🔧 Troubleshooting

### ClamAV Não Inicia

**Problema:** Container em loop de restart

```bash
# Ver logs de erro
sudo docker compose logs clamd-mailcow --tail=50

# Comum: Memória insuficiente
```

**Solução:**
```bash
# Aumentar RAM da VM ou limitar outros containers
# Mínimo recomendado: 2 GB para ClamAV
```

### Atualizações Falhando

**Problema:** Freshclam não consegue atualizar

```bash
# Ver erro específico
sudo docker compose exec clamd-mailcow freshclam -v
```

**Soluções comuns:**
- Verificar conectividade internet
- Verificar DNS
- Aguardar (mirror pode estar ocupado)

### Performance Degradada

**Problema:** Scans muito lentos

```bash
# Ver uso de recursos
sudo docker stats clamd-mailcow
```

**Soluções:**
- Aumentar RAM alocada
- Reduzir MaxFileSize
- Adicionar mais vCPUs

### Falsos Positivos

**Problema:** Email legítimo marcado como vírus

```bash
# Ver qual ficheiro foi detetado
sudo docker compose logs rspamd-mailcow | grep CLAM_VIRUS
```

**Solução:**
```bash
# Criar whitelist (uso com cautela!)
sudo nano /opt/mailcow-dockerized/data/conf/rspamd/local.d/antivirus.conf
```

```lua
# Whitelist de hash SHA256 específico
whitelist {
  "sha256:abc123...";
}
```

---

## 📊 Estatísticas FSociety

| Métrica | Valor |
|---------|-------|
| **Container** | clamd-mailcow |
| **Imagem** | ghcr.io/mailcow/clamd:1.71 |
| **Status** | Healthy (100%) |
| **RAM Utilizada** | ~1.5 GB |
| **Assinaturas** | 8.7M+ |
| **Scans Realizados** | ~19 (desde último restart) |
| **Vírus Encontrados** | 0 |
| **Última Atualização** | Diária |

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

**[⬅️ Anterior: Rspamd](04-rspamd.md)** | **[Índice](README.md)** | **[Próximo: Webmail ➡️](06-webmail.md)**

</div>

---

*Última atualização: Dezembro 2024*
