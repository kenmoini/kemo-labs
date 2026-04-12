# PikaPKI - Root Certificate Authority

## Overview

PikaPKI is the **root of trust** for the entire homelab PKI chain. It is a TUI/CLI-based PKI management tool built on OpenSSL that creates and manages Root CAs, Intermediate CAs, Signing CAs, and leaf certificates. PikaPKI runs as an interactive container for certificate operations and an always-on Nginx sidecar to serve public bundles (CA certs and CRLs) over HTTP.

**PKI chain design:**
```
PikaPKI Root CA
  └── Intermediate CA (issued to StepCA)
        └── StepCA issues leaf certs via ACME
```

PikaPKI itself is used on-demand (interactively) to:
- Create and manage the Root CA
- Issue intermediate CA certificates for StepCA
- Rotate CRLs
- Generate and copy public bundles

The Nginx sidecar runs continuously to serve CA certificates and CRLs at `http://pki.lab.kemo.dev/`.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| PikaPKI (interactive) | `quay.io/kenmoini/pika-pki` | `latest` |
| Public bundle server | `docker.io/nginx` | `1.27-alpine` |

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8001 | TCP | Nginx serving public bundles (CA certs, CRLs) |
| 443 | TCP | Optional -- Traefik-terminated HTTPS for public bundles |

**Note:** PikaPKI itself exposes no network ports. It is an interactive TUI container run with `docker compose run` or `docker exec -it`.

## Environment Variables

### PikaPKI Container

| Variable | Value | Notes |
|----------|-------|-------|
| `PIKA_PKI_DIR` | `/data/.pika-pki` | Workspace directory inside the container |
| `PIKA_PKI_DEFAULT_ORG` | `Kemo Labs` | Default organization for CA subjects |
| `PIKA_PKI_DEFAULT_ORGUNIT` | `Infrastructure` | Default OU |
| `PIKA_PKI_DEFAULT_COUNTRY` | `US` | Default country code |
| `PIKA_PKI_DEFAULT_STATE` | `North Carolina` | Default state |
| `PIKA_PKI_DEFAULT_LOCALITY` | `Raleigh` | Default locality |
| `PIKA_PKI_DEFAULT_EMAIL` | `ken@kenmoini.com` | Default contact email |
| `PIKA_PKI_DEFAULT_CA_URI_BASE` | `http://pki.lab.kemo.dev/public` | Base URI for CRL distribution points and CA cert hosting |
| `TERM` | `xterm-256color` | Already set in image; needed for TUI rendering |

### Nginx Container

No special environment variables required. Configuration is via a mounted `default.conf`.

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Size Estimate |
|--------|---------------|---------|---------------|
| `/opt/workdir/caas/pika-pki/data` | `/data` (PikaPKI) | PKI workspace: Root CA keys, intermediate certs, CRLs, all PKI state | 100 MB |
| `/opt/workdir/caas/pika-pki/data` (subpath `/.pika-pki/public_bundles`) | `/usr/share/nginx/html` (Nginx, read-only) | Public bundles served by Nginx | Shared with above |
| `./nginx/default.conf` | `/etc/nginx/conf.d/default.conf` (Nginx) | Nginx config with directory listing enabled | Bind mount of local file |

**Backup priority: CRITICAL** -- The PKI workspace contains Root CA private keys. Loss means total PKI rebuild. Encrypt backups at rest.

## Resource Estimates

| Resource | PikaPKI (on-demand) | Nginx (always-on) |
|----------|--------------------|--------------------|
| CPU | Negligible (only during interactive use) | 0.1 cores |
| Memory | 64 MB | 16 MB |
| Disk | ~100 MB | Shared with PikaPKI volume |

## Network Configuration

- **Static IP:** `192.168.62.5`
- **DNS record:** `pki.lab.kemo.dev` -> `192.168.62.5`
- **Traefik:** Route `pki.lab.kemo.dev` to the Nginx container on port 80. TLS is optional for this endpoint since it serves public CA certs and CRLs (public data), but HTTPS is recommended for integrity.
- **macvlan/ipvlan network:** The Nginx container should be attached to the Docker macvlan network with the static IP. The PikaPKI interactive container can share this network or use the default bridge.

## Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| None (upstream) | -- | PikaPKI is the root of the trust chain; it has no dependencies on other workloads |
| StepCA (downstream) | Consumer | StepCA depends on intermediate CA cert + key issued by PikaPKI |
| Traefik (downstream) | Consumer | Traefik trusts the Root CA cert from PikaPKI |
| All TLS services (downstream) | Consumer | All services trust the Root CA certificate |

## Deployment Order

PikaPKI must be deployed and the Root CA + Intermediate CA created **before** StepCA can be configured. This is the first security workload to deploy.

## Special Considerations

### Interactive-Only Operations
PikaPKI is a TUI application. Certificate operations (creating Root CA, issuing intermediates, revoking certs, rotating CRLs) must be done interactively:
```bash
docker compose run --rm pika-pki
```
The Nginx sidecar is the only always-running service.

### Root CA Key Security
- The Root CA private key is password-protected by PikaPKI during creation.
- Store the Root CA password in HashiCorp Vault once Vault is operational (bootstrapping chicken-and-egg: initially store it securely outside the system).
- Consider keeping Root CA key material on encrypted storage or even offline after issuing the intermediate.

### CRL Rotation
CRLs default to 30-day expiry. Set up a cron job or systemd timer on the host to rotate CRLs and copy public bundles:
```bash
docker compose run --rm pika-pki -m rotateCRL -a /data/.pika-pki/roots/<root-ca>/intermediate-ca/<int-ca> -p /data/.pika-pki/<password-file>
docker compose run --rm pika-pki -m copyBundles
```

### Trust Distribution
The Root CA certificate must be distributed to:
1. StepCA (as its root trust anchor)
2. Traefik (to validate StepCA-issued certs, if needed)
3. All Docker hosts (for inter-service TLS verification)
4. Client machines that need to trust homelab services

### Nginx Configuration
Enable directory listing so browsers can browse available certs/CRLs:
```nginx
server {
    listen 8001;
    server_name pki.lab.kemo.dev;
    location / {
        root /usr/share/nginx/html;
        autoindex on;
        autoindex_exact_size off;
    }
}
```

### Initial Setup Sequence
1. Start PikaPKI interactively
2. Create Root CA (e.g., CN: "Kemo Labs Root CA", 10-year validity)
3. Create Intermediate CA under Root (e.g., CN: "Kemo Labs Intermediate CA", 5-year validity)
4. Create Signing CA under Intermediate (optional, or let StepCA be the signing CA)
5. Export intermediate CA cert + key for StepCA
6. Run `copyBundles` to populate public bundles
7. Start Nginx sidecar to serve bundles
8. Distribute Root CA cert to trust stores
