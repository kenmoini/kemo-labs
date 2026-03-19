# Homelab 2026 - Master Deployment Plan

## Host Environment

- **OS:** Fedora (latest)
- **Virtualization:** Libvirt/KVM (for Talos Kubernetes VMs)
- **Containers:** Docker + Docker Compose (for everything else)
- **Network:** 192.168.62.0/23 (bridged), static IPs from .0/24, DHCP from .128/24+
- **DNS Zone:** lab.kemo.network
- **Resources:** 128GB+ RAM, 32+ cores
- **TLS Strategy:** PikaPKI root CA → StepCA intermediate → ACME auto-certs via Traefik

---

## IP Allocation Scheme

### Core Infrastructure (192.168.62.2 - 192.168.62.15)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.2 | PowerDNS Authoritative | infrastructure/dns |
| 192.168.62.3 | PowerDNS Recursor | infrastructure/dns |
| 192.168.62.4 | Pi-hole | infrastructure/dns |
| 192.168.62.5 | PikaPKI | security/pki |
| 192.168.62.6 | StepCA (ACME) | security/acme |
| 192.168.62.7 | HashiCorp Vault | security/vault |
| 192.168.62.8 | Authentik | security/identity |
| 192.168.62.10 | Traefik (Load Balancer) | infrastructure/traefik |
| 192.168.62.11 | Squid (Outbound Proxy) | infrastructure/outbound-proxy |
| 192.168.62.12 | Boot Services (Netboot/NUT/PeaNUT) | infrastructure/boot-services |
| 192.168.62.13 | Network Testing (iPerf3/SpeedTest) | infrastructure/network-testing |
| 192.168.62.14 | Homepage Dashboard | infrastructure/landing-page |
| 192.168.62.15 | Shared Databases (MariaDB) | databases/shared |
| 192.168.62.16 | Shared Databases (PostgreSQL) | databases/shared |
| 192.168.62.17 | Shared Databases (Valkey) | databases/shared |
| 192.168.62.18 | Shared Databases (Mosquitto) | databases/shared |
| 192.168.62.19 | Shared Databases (phpMyAdmin) | databases/shared |

### Infrastructure Tools (192.168.62.9, 192.168.62.25)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.9 | WUD (What's Up Docker) | infrastructure/wud |
| 192.168.62.25 | Semaphore (Ansible UI) | infrastructure/semaphore |

### Storage (192.168.62.20 - 192.168.62.23)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.20 | RustFS (S3) | storage/s3 |
| 192.168.62.21 | Nexus (Registry) | storage/container-registry |
| 192.168.62.22 | Kopia (Backups) | storage/backups |
| 192.168.62.23 | Dropbox (NGINX + Copyparty) | storage/dropbox |

### Observability (192.168.62.30 - 192.168.62.33)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.30 | Grafana Alloy Stack | observability/grafana-alloy |
| 192.168.62.31 | Dozzle | observability/dozzle |
| 192.168.62.32 | Uptime Kuma | observability/uptime-kuma |
| 192.168.62.33 | Scrutiny | observability/scrutiny |

### Development (192.168.62.40 - 192.168.62.43)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.40 | GitLab CE | development/gitlab |
| 192.168.62.41 | Renovate | development/renovate |
| 192.168.62.42 | Code Server | development/code-server |
| 192.168.62.43 | IT Tools | development/it-tools |

### Documentation (192.168.62.50 - 192.168.62.54)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.50 | Netbox | documentation/netbox |
| 192.168.62.51 | Affine | documentation/affine |
| 192.168.62.52 | Draw.io | documentation/drawio |
| 192.168.62.53 | Paperless NGX | documentation/paperless-ngx |
| 192.168.62.54 | Paperless AI | documentation/paperless-ai |

### Home Automation (192.168.62.60 - 192.168.62.61)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.60 | Home Assistant | automation/home-assistant |
| 192.168.62.61 | Scrypted | automation/scrypted |

### AI & Automation (192.168.62.70 - 192.168.62.72)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.70 | Open WebUI + Ollama | ai/open-webui |
| 192.168.62.71 | n8n | ai/n8n |
| 192.168.62.72 | Postiz | ai/postiz |

### Communication (192.168.62.80 - 192.168.62.82)

| IP | Service | Category |
|----|---------|----------|
| 192.168.62.80 | Mailcow | communication/mailcow |
| 192.168.62.81 | Shlink | communication/shlink |
| 192.168.62.82 | Ntfy (Push Notifications) | communication/ntfy |

### Kubernetes Cluster (192.168.62.99 - 192.168.62.112)

| IP | Service | Role |
|----|---------|------|
| 192.168.62.99 | Talos VIP | Control Plane VIP |
| 192.168.62.100 | talos-cp-1 | Control Plane |
| 192.168.62.101 | talos-cp-2 | Control Plane |
| 192.168.62.102 | talos-cp-3 | Control Plane |
| 192.168.62.110 | talos-w-1 | Worker |
| 192.168.62.111 | talos-w-2 | Worker |
| 192.168.62.112 | talos-w-3 | Worker |

---

## Valkey (Redis) Database Index Allocation

| DB | Service |
|----|---------|
| 0 | Netbox (task queue) |
| 1 | Netbox (cache) |
| 2 | Affine |
| 3 | Paperless NGX (Celery) |
| 4 | Authentik |
| 5 | GitLab |
| 6 | Postiz |
| 7-15 | Reserved for future use |

---

## Dependency Graph

```
Phase 0 (Foundation - No Dependencies):
  PKI (PikaPKI) ─── Root of trust, everything chains from this

Phase 1 (Core Infrastructure - Depends on PKI):
  DNS (PowerDNS Auth + Recursor + PiHole)
  ACME (StepCA) ─── Needs intermediate CA from PikaPKI

Phase 2 (Networking - Depends on DNS + ACME):
  Traefik ─── Needs DNS + ACME for cert issuance
  Outbound Proxy (Squid)

Phase 3 (Data Layer - Depends on DNS, Traefik):
  Shared Databases (MariaDB, PostgreSQL, Valkey, MQTT)
  S3 Object Store (RustFS)

Phase 4 (Identity & Secrets - Depends on Databases):
  Authentik ─── Needs PostgreSQL + Valkey
  Vault ─── Can run standalone, benefits from TLS

Phase 5 (Observability - Depends on Traefik):
  Grafana Alloy Stack
  Dozzle
  Uptime Kuma
  Scrutiny

Phase 6 (Storage Services - Depends on S3, Traefik):
  Nexus (Container Registry)
  Kopia (Backups) ─── Needs RustFS
  Dropbox (NGINX + Copyparty)

Phase 7 (Core Applications - Depends on Databases, Identity):
  GitLab ─── Needs PostgreSQL + Valkey + (optionally Authentik)
  Netbox ─── Needs PostgreSQL + Valkey
  Paperless NGX ─── Needs PostgreSQL + Valkey

Phase 8 (Application Extensions - Depends on Phase 7):
  Renovate ─── Needs GitLab
  Paperless AI ─── Needs Paperless NGX + AI backend
  Databasus ─── Configured alongside databases but listed here for backup scheduling

Phase 9 (Communication & Notifications - Depends on DNS, Traefik):
  Mailcow ─── Self-contained stack, needs DNS records (MX, SPF, DKIM)
  Shlink ─── Needs PostgreSQL
  Ntfy ─── Push notification hub (receives from Uptime Kuma, Scrutiny, WUD, Grafana, HA)

Phase 10 (Documentation & Tools - Depends on Traefik, optionally Databases):
  Affine ─── Needs PostgreSQL + Valkey + pgvector extension
  Draw.io ─── Stateless
  Code Server
  IT Tools ─── Stateless
  Homepage Dashboard
  WUD ─── Needs Docker socket + Ntfy for notifications
  Semaphore ─── Needs PostgreSQL (Ansible UI)

Phase 11 (Home Automation - Depends on MQTT):
  Home Assistant ─── Needs MQTT
  Scrypted ─── Integrates with Home Assistant

Phase 12 (AI & Workflows - Depends on Databases, Traefik):
  Open WebUI + Ollama
  n8n ─── Needs PostgreSQL
  Postiz ─── Needs PostgreSQL + Valkey + Temporal

Phase 13 (Network & Boot Services):
  Boot Services (Netboot.xyz, NUT, PeaNUT)
  Network Testing (iPerf3, OpenSpeedTest)

Phase 14 (Kubernetes - Depends on DNS, PKI):
  Talos Linux VMs (deploy last, longest to stabilize)
```

---

## Deployment Phases (Execution Order)

### Phase 0: Foundation
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| PikaPKI | security/pki/ | 1 | 128 MB |

**Gate:** Root CA generated and intermediate CA cert issued for StepCA.

### Phase 1: Core Infrastructure
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| DNS Stack | infrastructure/dns/ | 3 | 512 MB |
| StepCA | security/acme/ | 1 | 256 MB |

**Gate:** `dig lab.kemo.network @192.168.62.2` resolves. StepCA ACME endpoint responds.

### Phase 2: Networking
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Traefik | infrastructure/traefik/ | 1 | 256 MB |
| Squid | infrastructure/outbound-proxy/ | 1 | 512 MB |

**Gate:** Traefik dashboard accessible. ACME cert issuance works for a test domain.

### Phase 3: Data Layer
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Shared Databases | databases/shared/ | 6 | 2-6 GB |
| RustFS | storage/s3/ | 1 | 512 MB |

**Gate:** All database engines healthy. S3 bucket creation works.

### Phase 4: Identity & Secrets
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Authentik | security/identity/ | 2 | 1.5-2.5 GB |
| Vault | security/vault/ | 1 | 256-512 MB |

**Gate:** Authentik initial setup complete. Vault initialized and unsealed.

### Phase 5: Observability
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Grafana Alloy | observability/grafana-alloy/ | 5 | 4-6 GB |
| Dozzle | observability/dozzle/ | 1 | 128 MB |
| Uptime Kuma | observability/uptime-kuma/ | 1 | 256 MB |
| Scrutiny | observability/scrutiny/ | 1 | 512 MB |

**Gate:** Grafana dashboard loads. Dozzle shows container logs.

### Phase 6: Storage Services
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Nexus | storage/container-registry/ | 1 | 4-6 GB |
| Kopia | storage/backups/ | 1 | 256 MB |
| Dropbox | storage/dropbox/ | 2 | 256 MB |

**Gate:** Nexus Docker proxy pulls images. Kopia connects to RustFS.

### Phase 7: Core Applications
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| GitLab | development/gitlab/ | 1 | 6-10 GB |
| Netbox | documentation/netbox/ | 2 | 2-3 GB |
| Paperless NGX | documentation/paperless-ngx/ | 3 | 2-4 GB |

**Gate:** GitLab login works. Netbox reachable. Paperless ingests a test document.

### Phase 8: Application Extensions
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Renovate | development/renovate/ | 1 (scheduled) | 1-2 GB |
| Paperless AI | documentation/paperless-ai/ | 1 | 512 MB |

### Phase 9: Communication & Notifications
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Mailcow | communication/mailcow/ | 18 | 6-10 GB |
| Shlink | communication/shlink/ | 2 | 512 MB |
| Ntfy | communication/ntfy/ | 1 | 64 MB |

**Gate:** Mailcow sends/receives test email. Shlink creates short URL. Ntfy receives test notification.

### Phase 10: Documentation & Tools
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Affine | documentation/affine/ | 2 | 1-2 GB |
| Draw.io | documentation/drawio/ | 1 | 512 MB |
| Code Server | development/code-server/ | 1 | 512 MB |
| IT Tools | development/it-tools/ | 1 | 64 MB |
| Homepage | infrastructure/landing-page/ | 1 | 128 MB |
| WUD | infrastructure/wud/ | 1 | 128 MB |
| Semaphore | infrastructure/semaphore/ | 1 | 256 MB |

### Phase 11: Home Automation
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Home Assistant | automation/home-assistant/ | 1 | 1-2 GB |
| Scrypted | automation/scrypted/ | 2 | 2-4 GB |

### Phase 12: AI & Workflows
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Open WebUI + Ollama | ai/open-webui/ | 2 | 4-32 GB |
| n8n | ai/n8n/ | 1 | 512 MB |
| Postiz | ai/postiz/ | 5-6 | 2-4 GB |

### Phase 13: Network & Boot Services
| Workload | Dir | Containers | Est. RAM |
|----------|-----|-----------|----------|
| Boot Services | infrastructure/boot-services/ | 3 | 256 MB |
| Network Testing | infrastructure/network-testing/ | 2 | 128 MB |

### Phase 14: Kubernetes
| Workload | Dir | VMs | Est. RAM |
|----------|-----|-----|----------|
| Talos Cluster | compute/talos-kubernetes/ | 6 | 72 GB |

---

## Resource Summary

### Docker Workloads (estimated peak)
| Category | Containers | RAM (peak) |
|----------|-----------|-----------|
| Infrastructure | 13 | ~2.5 GB |
| Security | 5 | ~4 GB |
| Databases | 6 | ~6 GB |
| Storage | 5 | ~7 GB |
| Observability | 8 | ~7 GB |
| Development | 4 | ~14 GB |
| Documentation | 9 | ~10 GB |
| Automation | 3 | ~6 GB |
| AI | 8 | ~38 GB |
| Communication | 21 | ~10.5 GB |
| Boot/Network | 5 | ~0.5 GB |
| **Docker Total** | **~87** | **~106 GB** |

### VM Workloads
| Workload | VMs | RAM |
|----------|-----|-----|
| Talos Kubernetes | 6 | 72 GB |

### Total: ~177 GB peak
This exceeds 128 GB if everything runs simultaneously at peak. Recommendations:
1. Deploy Kubernetes cluster with fewer/smaller nodes initially (e.g., 3 CP @ 4GB + 2 W @ 8GB = 28 GB)
2. Ollama RAM usage depends on model size — use smaller models or offload to GPU
3. GitLab can be tuned down with fewer Puma workers
4. Consider deploying AI workloads only when actively needed

---

## Suggested Additional Workloads

### Consider Adding
1. **Portainer** — Docker management UI for inspecting/restarting containers
   - Category: `infrastructure/portainer/`
   - Minimal resources: 128 MB RAM

2. **Vaultwarden** — Self-hosted Bitwarden password manager
   - Category: `security/vaultwarden/`

3. **Gluetun** — VPN client container for selective traffic routing
   - Category: `infrastructure/vpn/`

4. **Forgejo/Gitea** — Lightweight Git alternative if GitLab resource usage is too high

---

## Shared Docker Network

All Docker Compose stacks will connect to a shared macvlan or ipvlan network for static IP assignment:

```bash
# Create once on the host before deploying any stack
docker network create \
  --driver macvlan \
  --subnet=192.168.62.0/23 \
  --gateway=192.168.62.1 \
  --ip-range=192.168.62.0/24 \
  -o parent=br0 \
  homelab
```

Each docker-compose.yml references this as an external network:
```yaml
networks:
  homelab:
    external: true
```

---

## DNS Records Required

All services need A records in PowerDNS Auth. A wildcard approach simplifies this:

```
*.lab.kemo.network.  A  192.168.62.10  (Traefik)
```

Services with direct access (not behind Traefik) need explicit records:
```
dns-auth.lab.kemo.network.     A  192.168.62.2
dns-recursor.lab.kemo.network. A  192.168.62.3
pihole.lab.kemo.network.       A  192.168.62.4
pki.lab.kemo.network.          A  192.168.62.5
acme.lab.kemo.network.         A  192.168.62.6
vault.lab.kemo.network.        A  192.168.62.7
auth.lab.kemo.network.         A  192.168.62.8
db.lab.kemo.network.           A  192.168.62.15
s3.lab.kemo.network.           A  192.168.62.20
gitlab.lab.kemo.network.       A  192.168.62.40  (for SSH access)
mail.lab.kemo.network.         A  192.168.62.80
ha.lab.kemo.network.           A  192.168.62.60  (host network)
scrypted.lab.kemo.network.     A  192.168.62.61  (host network)

; Kubernetes
talos-vip.lab.kemo.network.    A  192.168.62.99
talos-cp-1.lab.kemo.network.   A  192.168.62.100
talos-cp-2.lab.kemo.network.   A  192.168.62.101
talos-cp-3.lab.kemo.network.   A  192.168.62.102
talos-w-1.lab.kemo.network.    A  192.168.62.110
talos-w-2.lab.kemo.network.    A  192.168.62.111
talos-w-3.lab.kemo.network.    A  192.168.62.112

; Mail
mail.lab.kemo.network.         MX 10 mail.lab.kemo.network.
```

---

## Certificate Chain of Trust

```
PikaPKI Root CA (self-signed, long-lived)
  └── StepCA Intermediate CA (issued by PikaPKI)
        └── *.lab.kemo.network (auto-issued via ACME, 90-day rotation)
```

Distribute PikaPKI root CA to:
- All Docker containers (via mounted CA bundle)
- Traefik (LEGO_CA_CERTIFICATES)
- Host OS trust store
- Browsers/devices on the network
- Kubernetes nodes (Talos machine config)

---

## Backup Strategy

| Layer | Tool | Target |
|-------|------|--------|
| Database logical backups | Databasus | Local filesystem → Kopia |
| Filesystem backups | Kopia | RustFS S3 buckets |
| GitLab repositories | `gitlab-backup create` | Local → Kopia |
| Vault secrets | `vault operator raft snapshot` | RustFS |
| Configuration (this repo) | Git | GitLab (self-hosted) |
