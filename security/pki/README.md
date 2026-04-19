# PikaPKI - Root Certificate Authority

PikaPKI is the root of trust for the entire homelab PKI chain. It provides an interactive TUI for managing Root CAs, Intermediate CAs, and certificates, plus an Nginx sidecar that continuously serves public CA bundles and CRLs over HTTP.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set organization defaults

# Start the Nginx bundle server
docker compose up -d

# Run PikaPKI interactively to create CAs
docker compose run --rm pika-pki

# Inside the TUI:
#   1. Create Root CA
#   2. Create Intermediate CA
#   3. Copy public bundles
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `PIKA_PKI_DEFAULT_ORG` | Default organization name |
| `PIKA_PKI_DEFAULT_COUNTRY` | Default country code |
| `PIKA_PKI_DEFAULT_CA_URI_BASE` | Base URI for CRL distribution points |
| `PIKA_PKI_DEFAULT_EMAIL` | Default contact email |

## Access

| URL | Purpose |
|-----|---------|
| `https://pki.lab.kemo.dev` | Public CA certificates and CRLs (Nginx) |

**Static IP:** 192.168.42.5

## Dependencies

**None** -- PikaPKI is the root of the trust chain and has no upstream dependencies. Deploy it first.

Downstream consumers: StepCA, Traefik, all TLS-enabled services.

## Maintenance

```bash
# Rotate CRLs (run periodically via cron)
docker compose run --rm pika-pki -m rotateCRL -a /data/.pika-pki/roots/<root-ca>/intermediate-ca/<int-ca>
docker compose run --rm pika-pki -m copyBundles

# View Nginx logs
docker compose logs -f nginx

# CRITICAL: Back up the PKI data volume (contains Root CA private keys)
docker run --rm -v pki-data:/data -v /path/to/backup:/backup alpine tar czf /backup/pki-data.tar.gz /data
```

The PKI workspace contains Root CA private keys. Loss means total PKI rebuild. Encrypt backups at rest.
