# INPUT

> [Commit e4216d3](https://github.com/kenmoini/kemo-labs/commit/e4216d36a82c99412e68b7fcf6c58d0312e89cde)

I'm redeploying my homelab.  It's running on a single physical Fedora host and already has Libvirt/KVM for VM workloads and Docker for container workloads setup.  Both already have networks bridged in for static and DHCP IP allocation in the 192.168.42.0/23 range with the second half being the DHCP pool.  All workloads will use the DNS zone "lab.kemo.dev".  I'm wanting to deploy the following workloads:

- **PKI** - [PikaPKI](https://github.com/kenmoini/pika-pki)
- **Load Balancer** - [Traefik](https://doc.traefik.io/traefik/getting-started/quick-start/)
- **Dropbox** - NGINX container for easy access and [Copyparty](https://github.com/9001/copyparty/tree/hovudstraum/scripts/docker) for uploads and management.  Both mounting the same path for access to the same documents
- **Shared DBs** - [phpMyAdmin](https://docs.phpmyadmin.net/en/latest/setup.html#installing-using-docker), MariaDB, PGSQL, Valkey, MQTT, [Databasus](https://github.com/databasus/databasus?tab=readme-ov-file#option-3-docker-compose-setup) for backups
- **ACME** - [StepCA](https://smallstep.com/docs/step-ca/installation/#docker)
- **DNS** - PowerDNS Auth & Recursive Servers, [PiHole](https://docs.pi-hole.net/docker/) for Ad Blocking
- **Identity Services** - [Authentik](https://docs.goauthentik.io/install-config/install/docker-compose/) for LDAP & OIDC
- **Observability** - Grafana Alloy Stack, [Dozzle](https://dozzle.dev) for live logs and monitoring, [Uptime Kuma](https://uptimekuma.org/install-uptime-kuma-docker/), & [Scrutiny](https://github.com/AnalogJ/scrutiny?tab=readme-ov-file#docker) (for disks)
- **SCM** - [Gitlab](https://docs.gitlab.com/install/docker/installation/#install-gitlab-by-using-docker-compose), [Renovate](https://docs.renovatebot.com/examples/self-hosting/#gitlab-cicd-pipeline), [Code Server](https://github.com/coder/code-server) for a consistent in-browser IDE across all my devices, [IT Tools](https://it-tools.tech)
- **Outbound Proxy** - Squid
- **Container Registry** - [Nexus](https://vince.cojot.name/blog_2024_using-sonatype-nexus-as-a-generic-proxy-registry-t.html)
- **Secrets Management** - [Hashicorp Vault](https://ambar-thecloudgarage.medium.com/hashicorp-vault-with-docker-compose-0ea2ce1ca5ab)
- **S3 Object Store** - [RustFS](https://github.com/rustfs/rustfs?tab=readme-ov-file#2-docker-quick-start-option-2)
- **Backups** - [Kopia](https://kopia.io/docs/installation/#docker-images) to RustFS
- **Boot/Power Services** - [Netboot.xyz](https://netboot.xyz/docs/selfhosting/#deploying-with-docker), [NUT](https://thehomelabber.com/guides/network-ups-monitoring/) + [PeaNUT](https://github.com/Brandawg93/PeaNUT)
- **Network Testing** - iPerf3 Server, [Open Speed Test](https://openspeedtest.com/selfhosted-speedtest)
- **Landing Page** - [Homepage](https://gethomepage.dev/installation/docker/)
- **Home Automation** - Home Assistant, [Scrypted](https://docs.scrypted.app/install/linux-docker.html#docker-compose-yml)
- **SMTP** - [Mailcow](https://docs.mailcow.email/getstarted/install/)
- **Link Shortener** - [Shlink](https://shlink.io/documentation/install-docker-image/)
- **Kubernetes** - [Talos Linux in VMs](https://oneuptime.com/blog/post/2026-03-03-configure-talos-linux-on-libvirt-kvm/view)
- **Documentation** - [Netbox](https://github.com/netbox-community/netbox-docker/wiki/Getting-Started), [Affine](https://docs.affine.pro/self-host-affine/install/docker-compose-recommend), [Draw.io](https://github.com/jgraph/docker-drawio), [Paperless NGX](https://docs.paperless-ngx.com/setup/#docker), [Paperless AI](https://github.com/clusterzx/paperless-ai/wiki/2.-Installation)
- **AI Things** - [Open WebUI](https://docs.openwebui.com/getting-started/quick-start/), [n8n](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/), [Postiz](https://docs.postiz.com/installation/docker-compose)

- Use an agent team to review and research the list and create a Planing document in each workload's folder.
- Determine if any other key workloads are missing and suggest them.
- Reorder the workload deployment strategy to meet dependencies some may have on others and make an overall Planning document.
- Use an agent team to create the deployment files, manifests, and scripts needed to deploy the ensemble.  Use Docker Compose whenever possible, VMs when needed. Talos Kubernetes is for other workloads not listed here.
- Write the documentation to support the workloads.
- Ask me any questions to clarify

# OUTPUT

Homelab 2026 - Project Complete

190 files across 11 categories and 34 workloads

```
┌──────────────────────────────────────┬───────┐
│              File Type               │ Count │
├──────────────────────────────────────┼───────┤
│ PLANNING.md (per-workload research)  │ 37    │
├──────────────────────────────────────┼───────┤
│ README.md (documentation)            │ 37    │
├──────────────────────────────────────┼───────┤
│ docker-compose.yml                   │ 34    │
├──────────────────────────────────────┼───────┤
│ .env.example                         │ 34    │
├──────────────────────────────────────┼───────┤
│ Shell scripts                        │ 12    │
├──────────────────────────────────────┼───────┤
│ Config files (YAML, HCL, conf, etc.) │ 36    │
└──────────────────────────────────────┴───────┘
```

What was delivered:

1. Research & Planning — Each workload researched with Docker images, ports, env vars, resource estimates, and dependency mapping
2. Master Plan — PLANNING.md at repo root with full IP allocation, 15-phase deployment order, dependency graph, resource budget, and
  missing workload suggestions
1. Deployment Files — Production-ready docker-compose.yml + .env.example for every stack, plus Traefik configs, DB init scripts,
Mosquitto config, Vault HCL, Alloy/Loki/Mimir/Tempo configs, and Talos Kubernetes VM scripts
1. Orchestration — scripts/deploy.sh deploys all phases in order, scripts/setup-network.sh creates the macvlan network
2. Documentation — Top-level README with architecture diagram + 34 per-workload READMEs

Key things to review before deploying:

- IP allocation expanded — Database stack uses .15-.19 (one per container), Grafana/Alloy uses .30+.35, Ollama uses .73
- Resource budget — ~105 GB Docker + 72 GB Kubernetes exceeds 128 GB at peak. Consider smaller Talos cluster initially
- Secrets — Copy all .env.example to .env and replace placeholder passwords before deploying
- Mailcow — Uses its own compose tooling; run communication/mailcow/setup.sh instead of the master deploy script
- Suggested additions — Portainer, Watchtower/Diun, Ntfy, Vaultwarden (see PLANNING.md)