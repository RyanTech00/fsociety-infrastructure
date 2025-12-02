# 🔐 FSociety.pt - Documentação da Infraestrutura

Bem-vindo à documentação técnica do projeto **FSociety.pt**, uma infraestrutura empresarial segura implementada como projeto universitário na ESTG/IPP.

## 📋 Sobre o Projeto

Este projeto implementa uma infraestrutura de rede empresarial completa baseada numa arquitetura **Four-Legged Firewall**, integrando serviços essenciais com políticas de acesso rigorosas e mecanismos de proteção em múltiplas camadas.

### Tecnologias Implementadas

| Componente | Tecnologia | Função |
|------------|------------|--------|
| Virtualização | Proxmox VE 8.x | Hypervisor Type-1 |
| Firewall | pfSense CE | Segmentação e segurança perimetral |
| Identidade | Samba AD DC | Active Directory + DNS + DHCP |
| VPN | OpenVPN + RADIUS | Acesso remoto seguro |
| Email | Postfix + Dovecot + PMG | Servidor de email corporativo |
| Ficheiros | Nextcloud | Colaboração e partilha |
| Proteção Externa | Cloudflare | WAF + CDN + DDoS Mitigation |

## 🗺️ Arquitetura de Rede

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                 ┌────────▼────────┐
                 │   CLOUDFLARE    │  WAF / CDN / DDoS
                 │   (Proxy Layer) │
                 └────────┬────────┘
                          │
              ┌───────────▼───────────┐
              │      pfSense          │
              │   (Four-Legged FW)    │
              │                       │
              │  WAN: 188.81.65.191   │
              └───┬───────┬───────┬───┘
                  │       │       │
       ┌──────────┘       │       └──────────┐
       │                  │                  │
┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
│     LAN     │    │     DMZ     │    │     VPN     │
│192.168.1.0/24│   │ 10.0.0.0/24 │    │ 10.8.0.0/24 │
├─────────────┤    ├─────────────┤    ├─────────────┤
│ Samba AD DC │    │ Mail Server │    │ Remote Users│
│ Nextcloud   │    │ Web Server  │    │ by Group    │
│ Backup Srv  │    │ Mail Gateway│    │             │
│ Workstations│    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 📚 Índice da Documentação

### 1. Arquitetura e Planeamento
- [Visão Geral da Arquitetura](01-arquitetura/visao-geral.md)
- [Diagrama de Rede](01-arquitetura/diagrama-rede.md)
- [Plano de Endereçamento IP](01-arquitetura/plano-enderecamento.md)

### 2. Proxmox VE
- [Instalação do Proxmox VE](02-proxmox/instalacao.md)
- [Configuração de VMs](02-proxmox/configuracao-vms.md)

### 3. pfSense Firewall
- [Instalação do pfSense](03-pfsense/instalacao.md)
- [Configuração de Interfaces](03-pfsense/interfaces.md)
- [Regras de Firewall](03-pfsense/regras-firewall.md)
- [NAT e Port Forwarding](03-pfsense/nat-port-forwarding.md)

### 4. Active Directory
- [Samba AD Domain Controller](04-active-directory/samba-ad.md)
- [DNS e DHCP Integrados](04-active-directory/dns-dhcp.md)
- [FreeRADIUS com LDAP](04-active-directory/freeradius.md)

### 5. Serviços DMZ
- [Proxmox Mail Gateway](05-dmz/proxmox-mail-gateway.md)
- [Postfix e Dovecot](05-dmz/postfix-dovecot.md)
- [Servidor Web](05-dmz/webserver.md)

### 6. VPN
- [OpenVPN com Autenticação RADIUS](06-vpn/openvpn-radius.md)

### 7. Nextcloud
- [Instalação e Integração LDAP](07-nextcloud/instalacao-ldap.md)

### 8. Cloudflare
- [WAF, CDN e Configuração DNS](08-cloudflare/waf-cdn-dns.md)

---

## 🎓 Informação Académica

| Campo | Valor |
|-------|-------|
| **Instituição** | ESTG - Instituto Politécnico do Porto |
| **Curso** | [Nome do Curso] |
| **Unidade Curricular** | [Nome da UC] |
| **Autor** | Ryan |
| **Ano Letivo** | 2024/2025 |

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](../LICENSE).

---

<p align="center">
  <strong>FSociety.pt</strong> - Infraestrutura Empresarial Segura<br>
  <em>Projeto Universitário ESTG/IPP</em>
</p>
