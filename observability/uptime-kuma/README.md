# Uptime Kuma - Uptime Monitoring

Uptime Kuma is a self-hosted monitoring tool that checks service availability via HTTP(S), TCP, DNS, ping, and other protocols. It provides status pages, notifications, and historical uptime data for all homelab services.

## Quick Start

```bash
docker compose up -d

# Complete initial setup at:
# https://uptime.lab.kemo.dev
# Create an admin account on first access (cannot be pre-seeded)
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN` | Allow iframe embedding (default: `true`) |
| `NODE_EXTRA_CA_CERTS` | Path to custom CA cert for trusting internal TLS services |

Most configuration is done through the web UI after first launch. Mount the StepCA root CA certificate to trust internal HTTPS endpoints.

## Access

| URL | Purpose |
|-----|---------|
| `https://uptime.lab.kemo.dev` | Monitoring dashboard and status pages |

**Static IP:** 192.168.42.32

## Dependencies

- **Traefik** -- reverse proxy for HTTPS access
- **StepCA root certificate** (optional) -- mount to trust internal HTTPS services

## Maintenance

```bash
# View logs
docker compose logs -f uptime-kuma

# Update image
docker compose pull && docker compose up -d

# Back up data (SQLite database + config)
docker run --rm -v uptime-kuma-data:/data -v /path/to/backup:/backup \
  alpine tar czf /backup/uptime-kuma.tar.gz /data

# Prometheus metrics available at /metrics for Grafana integration
```

Uptime Kuma uses SQLite exclusively. Backup is simply copying the `/app/data` volume. Configure data retention in the UI to manage database growth. Set up notification channels (email, Discord, Slack) after first login.
