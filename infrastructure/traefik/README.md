# Traefik - Reverse Proxy and Load Balancer

Traefik serves as the central ingress point for all homelab services, providing reverse proxying, automatic service discovery via Docker labels, and TLS certificate management through the internal StepCA ACME server.

## Quick Start

```bash
# Ensure the root CA certificate is in place
cp /path/to/root_ca.crt ./certs/root_ca.crt

# Create the ACME storage file with correct permissions
touch ./data/acme.json && chmod 600 ./data/acme.json

# Create .env from template and set the dashboard auth
cp .env.example .env
# Edit .env: set TRAEFIK_DASHBOARD_AUTH (generate with htpasswd)

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `TRAEFIK_DASHBOARD_AUTH` | BasicAuth credentials for the dashboard (htpasswd format) |
| `LEGO_CA_CERTIFICATES` | Path to StepCA root CA cert inside the container |
| `TZ` | Timezone (default: `America/New_York`) |

Static configuration lives in `./config/traefik.yml`. Dynamic route definitions for non-Docker services go in `./config/dynamic/`.

## Access

| URL | Purpose |
|-----|---------|
| `https://traefik.lab.kemo.network` | Dashboard (requires BasicAuth) |

**Static IP:** 192.168.62.10

## Dependencies

- **DNS (PowerDNS)** -- wildcard `*.lab.kemo.network` must resolve to 192.168.62.10
- **StepCA (ACME)** -- must be reachable for certificate issuance
- **Docker socket** -- mounted read-only for container auto-discovery

## Maintenance

```bash
# View logs
docker compose logs -f traefik

# Update image
# Edit docker-compose.yml to new tag, then:
docker compose pull && docker compose up -d

# Back up ACME certificates
cp ./data/acme.json /path/to/backup/

# Check health
docker compose ps
```

The `acme.json` file must always have mode `600` or Traefik will refuse to start. Back it up regularly to avoid unnecessary certificate re-issuance.
