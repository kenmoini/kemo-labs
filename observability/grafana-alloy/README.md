# Grafana Alloy Observability Stack

Full Grafana observability stack providing metrics (Mimir), logs (Loki), traces (Tempo), and dashboards (Grafana). Grafana Alloy serves as the unified telemetry collector, forwarding data to purpose-built backends.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set GF_ADMIN_PASSWORD (required)

# Ensure config files exist:
#   ./config/loki-config.yaml
#   ./config/mimir-config.yaml
#   ./config/tempo-config.yaml
#   ./config/alloy-config.alloy
#   ./grafana/provisioning/datasources/

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `GF_ADMIN_PASSWORD` | Grafana admin password (required) |
| `GF_ADMIN_USER` | Grafana admin username (default: `admin`) |
| `GF_LOG_LEVEL` | Log verbosity (default: `warn`) |
| `GF_INSTALL_PLUGINS` | Additional Grafana plugins |

Backend services (Loki, Mimir, Tempo) are configured via YAML files in `./config/`. Alloy uses the River configuration language (`.alloy` files).

## Access

| URL | Purpose |
|-----|---------|
| `https://grafana.lab.kemo.network` | Grafana dashboards and alerting |
| `192.168.62.35:4317` | Alloy OTLP gRPC receiver (for sending traces) |
| `192.168.62.35:4318` | Alloy OTLP HTTP receiver |
| `192.168.62.30:3100` | Loki API (log push/query) |
| `192.168.62.30:9009` | Mimir API (metrics remote write) |

**Grafana Static IP:** 192.168.62.30 | **Alloy Static IP:** 192.168.62.35

## Dependencies

- **Traefik** -- reverse proxy for Grafana HTTPS access
- **Docker socket** -- Alloy needs read-only access for container discovery and log collection

## Maintenance

```bash
# View logs
docker compose logs -f grafana alloy

# Update images (pin to specific versions)
docker compose pull && docker compose up -d

# Configure retention in backend configs:
#   Loki: 30 days, Mimir: 90 days, Tempo: 14 days

# Data sources are pre-provisioned via ./grafana/provisioning/datasources/
```

Loki and Mimir are the most storage-intensive components (20-50 GB each). Monitor disk usage and adjust retention policies as needed.
