# Homelab 2026

> This is an experiment to see if I can vibe code my way into refreshing my homelab workloads.  Prompts can be seen in [./.prompts/](./.prompts/)

A single-host homelab running ~87 Podman containers and a 6-node Kubernetes cluster on Fedora with KVM + Podman Compose. Every service gets a static IP on a shared macvlan network and automated TLS certificates via an internal ACME CA.

## Infrastructure

Everything here is meant to be run on a single Fedora host, however in my lab I run a few different hosts:

- **Tardis** - An MS-02 Ultra, the primary host for my lab stack
- **Raichu** - An MSI EdgeXpert (DGX Spark) that runs my local LLMs
- **Rocinante** - An MS-01 ESXi host for testing vSphere things
- **Galactica** - An MS-A2 that runs Single Node OpenShift

## Architecture

```
+-----------------------------------------------------------------+
|  Fedora Host (128GB+ RAM, 32+ cores)                            |
|                                                                 |
|  +-----------------------------------------------------------+  |
|  |  Podman                                                   |  |
|  |                                                           |  |
|  |  Phase 0   [ PikaPKI (Root CA) ]                          |  |
|  |  Phase 1   [ PowerDNS Auth/Recursor | Pi-hole | StepCA ]  |  |
|  |  Phase 2   [ Traefik (LB) | Squid (Proxy) ]               |  |
|  |  Phase 3   [ MariaDB | PostgreSQL | Valkey | MQTT | S3 ]  |  |
|  |  Phase 4   [ Authentik | Vault ]                          |  |
|  |  Phase 5   [ Grafana Alloy | Dozzle | Uptime | Scrutiny ] |  |
|  |  Phase 6   [ Nexus | Kopia | Dropbox ]                    |  |
|  |  Phase 7   [ GitLab | Netbox | Paperless NGX ]            |  |
|  |  Phase 8   [ Renovate | Paperless AI ]                    |  |
|  |  Phase 9   [ Mailcow | Shlink | Ntfy ]                    |  |
|  |  Phase 10  [ Affine | Draw.io | Code | WUD | Semaphore ]  |  |
|  |  Phase 11  [ Home Assistant | Scrypted ]                  |  |
|  |  Phase 12  [ Open WebUI + Ollama | n8n | Postiz ]         |  |
|  |  Phase 13  [ Netboot.xyz | NUT | iPerf3 | SpeedTest ]     |  |
|  +-----------------------------------------------------------+  |
|                                                                 |
|  +-----------------------------------------------------------+  |
|  |  Libvirt / KVM                                            |  |
|  |  Phase 14  [ Talos CP x3 | Talos Worker x3 ]              |  |
|  +-----------------------------------------------------------+  |
|                                                                 |
|  br0 ──── 192.168.92.0/23 (bridge) ──── Access VLAN             |
|  br0.62 ──── 192.168.62.0/23 (bridge) ──── Lab VLAN 62          |
|  br0.70 ──── 192.168.70.0/24 (bridge) ──── Disconnected VLAN 70 |
|  br0.86 ──── 192.168.86.0/24 (bridge) ──── Isolated VLAN 86     |
+-----------------------------------------------------------------+
```

## Quick Start

### Prerequisites

- Fedora (44+) with Libvirtd, Podman, and Podman Compose installed
- Network bridge interfaces configured for each VLAN (see [Networks](#networks) below)
- 128GB+ RAM (see [Resource Notes](#resource-notes) for tuning)
- This repository cloned to the host

### 1. Create the Podman networks

Create all predefined bridged networks at once:

```bash
./scripts/setup-network.sh --all
```

This creates one Podman bridged network per VLAN. To also enable host-to-container communication (macvlan shim interfaces):

```bash
./scripts/setup-network.sh --shims
```

To list predefined and existing networks:

```bash
./scripts/setup-network.sh --list
```

To create a single network interactively or via named parameters:

```bash
# Interactive
./scripts/setup-network.sh

# Named parameters
./scripts/setup-network.sh \
  --name homelab-lab \
  --subnet 192.168.62.0/23 \
  --gateway 192.168.62.1 \
  --ip-range 192.168.62.0/24 \
  --parent br0.62
```

### 2. Deploy all stacks in order

```bash
./scripts/deploy.sh
```

The deploy script brings up each phase sequentially with health-check gates between them. To deploy a specific phase:

```bash
./scripts/deploy.sh --phase 3
```

### 3. Distribute the Root CA

After Phase 0 completes, copy the PikaPKI root CA certificate to your browser, host trust store, and any devices that need to trust `*.lab.kemo.network`.

## Networks

The homelab uses multiple VLANs, each mapped to a Libvirt/Podman bridge network via host bridge interfaces.

| Network Name | Subnet | Gateway | Parent | Purpose |
|----------------|--------|---------|--------|---------|
| `homelab-access` | 192.168.92.0/23 | 192.168.92.1 | `br0` | Access VLAN - management and uplinks |
| `homelab-lab` | 192.168.62.0/23 | 192.168.62.1 | `br0.62` | Lab VLAN 62 - primary workload network |
| `homelab-disconnected` | 192.168.70.0/24 | 192.168.70.1 | `br0.70` | Disconnected VLAN 70 - no upstream connectivity |
| `homelab-isolated` | 192.168.86.0/24 | 192.168.86.1 | `br0.86` | Isolated VLAN 86 - restricted traffic |

All homelab workloads run on `homelab-lab` (192.168.62.0/23) by default. The other networks are available for workloads that need network isolation (e.g., malware analysis, build sandboxes, testing).

Host bridge interfaces (`br0`, `br0.62`, `br0.70`, `br0.86`) must exist before creating the Libvirt/Podman networks.

## Directory Structure

| Directory | Category | Workloads |
|-----------|----------|-----------|
| `ai/` | AI and Workflows | Open WebUI + Ollama, n8n, Postiz |
| `automation/` | Home Automation | Home Assistant, Scrypted |
| `communication/` | Communication | Mailcow, Shlink, Ntfy |
| `compute/` | Virtualization | Talos Kubernetes (KVM) |
| `databases/` | Data Layer | MariaDB, PostgreSQL, Valkey, MQTT |
| `development/` | Development Tools | GitLab, Renovate, Code Server, IT Tools |
| `documentation/` | Docs and Knowledge | Netbox, Affine, Draw.io, Paperless NGX/AI |
| `infrastructure/` | Core Infrastructure | DNS, Traefik, Squid, Boot Services, Homepage, WUD, Semaphore |
| `observability/` | Monitoring | Grafana Alloy, Dozzle, Uptime Kuma, Scrutiny |
| `scripts/` | Automation | deploy.sh, setup-network.sh |
| `security/` | Security | PikaPKI, StepCA, Authentik, Vault |
| `storage/` | Storage | RustFS (S3), Nexus, Kopia, Dropbox |

Each workload directory contains a `docker-compose.yml` and any supporting configuration files.

## IP Allocation

### Core Infrastructure (192.168.62.2 -- 192.168.62.15)

| IP | Service |
|----|---------|
| .2 | PowerDNS Authoritative |
| .3 | PowerDNS Recursor |
| .4 | Pi-hole |
| .5 | PikaPKI |
| .6 | StepCA (ACME) |
| .7 | HashiCorp Vault |
| .8 | Authentik |
| .10 | Traefik (Load Balancer) |
| .11 | Squid (Outbound Proxy) |
| .12 | Boot Services (Netboot/NUT/PeaNUT) |
| .13 | Network Testing (iPerf3/SpeedTest) |
| .9 | WUD (What's Up Docker) |
| .14 | Homepage Dashboard |
| .15-.19 | Shared Databases (MariaDB, PostgreSQL, Valkey, MQTT, phpMyAdmin) |
| .25 | Semaphore (Ansible UI) |

### Services (192.168.62.20 -- 192.168.62.82)

| IP | Service |
|----|---------|
| .20 | RustFS (S3) |
| .21 | Nexus (Container Registry) |
| .22 | Kopia (Backups) |
| .23 | Dropbox (NGINX + Copyparty) |
| .30 | Grafana Alloy Stack |
| .31 | Dozzle |
| .32 | Uptime Kuma |
| .33 | Scrutiny |
| .40 | GitLab CE |
| .41 | Renovate |
| .42 | Code Server |
| .43 | IT Tools |
| .50 | Netbox |
| .51 | Affine |
| .52 | Draw.io |
| .53 | Paperless NGX |
| .54 | Paperless AI |
| .60 | Home Assistant |
| .61 | Scrypted |
| .70 | Open WebUI + Ollama |
| .71 | n8n |
| .72 | Postiz |
| .80 | Mailcow |
| .81 | Shlink |
| .82 | Ntfy (Push Notifications) |

### Kubernetes (192.168.62.99 -- 192.168.62.112)

| IP | Node |
|----|------|
| .99 | Talos VIP (Control Plane) |
| .100-.102 | talos-cp-1 through talos-cp-3 |
| .110-.112 | talos-w-1 through talos-w-3 |

All IPs are on the 192.168.62.0/23 subnet. DHCP is served from .128/24 and above.

## Deployment Phases

| Phase | Name | Key Workloads | Gate |
|-------|------|---------------|------|
| 0 | Foundation | PikaPKI | Root CA and intermediate cert issued |
| 1 | Core Infrastructure | DNS Stack, StepCA | DNS resolves, ACME endpoint responds |
| 2 | Networking | Traefik, Squid | Traefik dashboard up, test cert issued |
| 3 | Data Layer | Shared DBs, RustFS | All DB engines healthy, S3 works |
| 4 | Identity and Secrets | Authentik, Vault | Auth setup done, Vault unsealed |
| 5 | Observability | Grafana, Dozzle, Uptime Kuma, Scrutiny | Grafana loads, Dozzle shows logs |
| 6 | Storage Services | Nexus, Kopia, Dropbox | Nexus pulls images, Kopia connects |
| 7 | Core Apps | GitLab, Netbox, Paperless NGX | Login and basic operations work |
| 8 | App Extensions | Renovate, Paperless AI | Scheduled runs configured |
| 9 | Communication | Mailcow, Shlink, Ntfy | Email send/receive, short URLs, notifications work |
| 10 | Docs and Tools | Affine, Draw.io, Code Server, IT Tools, Homepage, WUD, Semaphore | UIs accessible |
| 11 | Home Automation | Home Assistant, Scrypted | HA connected to MQTT |
| 12 | AI and Workflows | Open WebUI, n8n, Postiz | Ollama responds, n8n workflows run |
| 13 | Boot and Network | Netboot.xyz, NUT, iPerf3, SpeedTest | PXE boot menu loads |
| 14 | Kubernetes | Talos VMs (6 nodes) | Cluster healthy via talosctl |

## TLS Strategy

The foundation of a good environment is proper Public Key Infrastructure.  PikaPKI handles the creation of Root/Intermediate/Signing CAs some of which are delegated to things like Squid and StepCA.

```
Kemo Labs Root CA (self-signed root, long-lived)
  +-- Kemo Labs Intermediate CA (issued by PikaPKI, ACME-enabled)
        +-- Kemo Labs Signing CA (for long-life/manual certificates)
        +-- Kemo Labs Squid Proxy CA (for SSL MitM'ing)
  +-- Kemo Labs StepCA Intermediate CA (issued by PikaPKI, ACME-enabled)
        +-- *.lab.kemo.network (auto-issued, 90-day rotation)
```

1. **PikaPKI** generates and manages the CA chain (Phase 0).
2. **StepCA** runs as an ACME server with an intermediate CA signed by PikaPKI (Phase 1).
3. **Traefik** uses the ACME protocol to automatically request and renew certificates from StepCA for every routed service (Phase 2).
4. The **PikaPKI Root CA** must be distributed to all clients, containers, and Kubernetes nodes for trust.  [Read this for information on how to do that](https://kenmoini.com/post/2024/02/adding-trusted-root-certificate-authority/).

## Key URLs

All services are accessible via `*.lab.kemo.network`. Services behind Traefik resolve via a wildcard DNS record pointing to 192.168.62.10.

| Service | URL |
|---------|-----|
| Traefik Dashboard | `https://traefik.lab.kemo.network` |
| Pi-hole | `https://pihole.lab.kemo.network` |
| PikaPKI | `https://pki.lab.kemo.network` |
| StepCA | `https://acme.lab.kemo.network` |
| Vault | `https://vault.lab.kemo.network` |
| Authentik | `https://auth.lab.kemo.network` |
| Grafana | `https://grafana.lab.kemo.network` |
| Dozzle | `https://dozzle.lab.kemo.network` |
| Uptime Kuma | `https://uptime.lab.kemo.network` |
| Scrutiny | `https://scrutiny.lab.kemo.network` |
| RustFS (S3) | `https://s3.lab.kemo.network` |
| Nexus | `https://nexus.lab.kemo.network` |
| Kopia | `https://kopia.lab.kemo.network` |
| GitLab | `https://gitlab.lab.kemo.network` |
| Netbox | `https://netbox.lab.kemo.network` |
| Paperless NGX | `https://paperless.lab.kemo.network` |
| Affine | `https://affine.lab.kemo.network` |
| Draw.io | `https://drawio.lab.kemo.network` |
| Code Server | `https://code.lab.kemo.network` |
| IT Tools | `https://it-tools.lab.kemo.network` |
| Homepage | `https://home.lab.kemo.network` |
| Home Assistant | `https://ha.lab.kemo.network` |
| Scrypted | `https://scrypted.lab.kemo.network` |
| Open WebUI | `https://ai.lab.kemo.network` |
| n8n | `https://n8n.lab.kemo.network` |
| Postiz | `https://postiz.lab.kemo.network` |
| Mailcow | `https://mail.lab.kemo.network` |
| Shlink | `https://shlink.lab.kemo.network` |
| Ntfy | `https://ntfy.lab.kemo.network` |
| WUD | `https://wud.lab.kemo.network` |
| Semaphore | `https://semaphore.lab.kemo.network` |

## Managing Individual Stacks

Each workload is a self-contained Podman Compose project. Manage them individually from the repo root:

```bash
# Start a single stack
docker compose -f infrastructure/dns/docker-compose.yml up -d

# Stop a single stack
docker compose -f infrastructure/dns/docker-compose.yml down

# View logs
docker compose -f infrastructure/dns/docker-compose.yml logs -f

# Pull latest images and recreate
docker compose -f infrastructure/dns/docker-compose.yml pull
docker compose -f infrastructure/dns/docker-compose.yml up -d

# Restart a single service within a stack
docker compose -f infrastructure/dns/docker-compose.yml restart pihole
```

All stacks share the external `homelab` macvlan network, so stopping one stack does not affect others.

## Backup Strategy

| What | How | Destination |
|------|-----|-------------|
| Database logical dumps | Databasus (scheduled) | Local filesystem, then Kopia |
| Filesystem and volumes | Kopia | RustFS S3 buckets |
| GitLab repositories | `gitlab-backup create` | Local, then Kopia |
| Vault secrets | `vault operator raft snapshot` | RustFS |
| Configuration (this repo) | Git | GitLab (self-hosted) |

## Resource Notes

Estimated peak usage for all Podman workloads is ~106 GB RAM. The Talos Kubernetes cluster adds up to 72 GB. Running everything simultaneously exceeds 128 GB. Recommendations:

- Start the Kubernetes cluster with fewer or smaller nodes (e.g., 3 CP at 4 GB + 2 workers at 8 GB = 28 GB).
- Use smaller Ollama models or offload inference to a GPU.
- Tune GitLab by reducing Puma workers.
- Run AI workloads only when actively needed.

## Kubernetes

The Talos Linux cluster (Phase 14) runs as KVM virtual machines managed by libvirt, separate from the Podman workloads. It is deployed last because it takes the longest to stabilize and has the heaviest resource footprint.

Configuration lives in `compute/talos-kubernetes/`. The cluster uses its own IP range (192.168.62.99-112) with a shared VIP at .99 for the control plane.

## Further Reading

- [PLANNING.md](PLANNING.md) -- Full deployment plan with dependency graph, DNS records, Valkey DB index allocation, and resource estimates.
