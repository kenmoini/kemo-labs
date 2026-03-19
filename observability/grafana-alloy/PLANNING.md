# Grafana Alloy Observability Stack

## Overview

Full Grafana observability stack providing metrics, logs, traces, and dashboards for the entire homelab. Grafana Alloy replaces the older Grafana Agent as the unified telemetry collector, forwarding data to purpose-built backends: Mimir (metrics), Loki (logs), and Tempo (traces). Grafana provides the visualization and alerting frontend.

All components run in a single Docker Compose deployment on a dedicated static IP.

## Docker Images

| Component | Image | Tag |
|-----------|-------|-----|
| Grafana | `grafana/grafana` | `11.6.0` |
| Grafana Alloy | `grafana/alloy` | `1.9.1` |
| Loki | `grafana/loki` | `3.5.0` |
| Mimir | `grafana/mimir` | `2.16.0` |
| Tempo | `grafana/tempo` | `2.7.2` |

> **Note:** Verify these tags against Docker Hub at deployment time. Pin to specific versions, not `latest`.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 3000 | TCP | Grafana | Web UI and API |
| 3100 | TCP | Loki | HTTP API (push/query) |
| 9009 | TCP | Mimir | HTTP API (remote write/query) |
| 3200 | TCP | Tempo | HTTP API (query) |
| 4317 | TCP | Alloy | OTLP gRPC receiver |
| 4318 | TCP | Alloy | OTLP HTTP receiver |
| 12345 | TCP | Alloy | Alloy UI / health |

Internal-only ports (container-to-container, no host binding needed):

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 9095 | TCP | Mimir | gRPC (internal) |
| 9096 | TCP | Loki | gRPC (internal) |

## Environment Variables

### Grafana

| Variable | Value | Description |
|----------|-------|-------------|
| `GF_SERVER_ROOT_URL` | `https://grafana.lab.kemo.network` | Public URL |
| `GF_SERVER_DOMAIN` | `grafana.lab.kemo.network` | Server domain |
| `GF_SECURITY_ADMIN_USER` | `admin` | Admin username |
| `GF_SECURITY_ADMIN_PASSWORD` | (secret) | Admin password, set via `.env` file |
| `GF_USERS_ALLOW_SIGN_UP` | `false` | Disable public signup |
| `GF_LOG_LEVEL` | `warn` | Log verbosity |
| `GF_INSTALL_PLUGINS` | `` | Additional plugins if needed |

### Loki

Configured via `loki-config.yaml` mounted into the container. No required environment variables.

### Mimir

Configured via `mimir-config.yaml` mounted into the container. No required environment variables.

### Tempo

Configured via `tempo-config.yaml` mounted into the container. No required environment variables.

### Alloy

Configured via `alloy-config.alloy` (River format) mounted into the container. Key args:

- `--config.file=/etc/alloy/config.alloy`
- `--stability.level=generally-available`

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `grafana-data` | `/var/lib/grafana` | Dashboards, plugins, SQLite DB | 500MB |
| `loki-data` | `/loki` | Log chunks and index | 20-50GB+ |
| `mimir-data` | `/data` | Metric TSDB blocks | 20-50GB+ |
| `tempo-data` | `/var/tempo` | Trace data | 10-20GB |
| `./config/loki-config.yaml` | `/etc/loki/local-config.yaml` | Loki configuration | bind mount |
| `./config/mimir-config.yaml` | `/etc/mimir/mimir.yaml` | Mimir configuration | bind mount |
| `./config/tempo-config.yaml` | `/etc/tempo/tempo.yaml` | Tempo configuration | bind mount |
| `./config/alloy-config.alloy` | `/etc/alloy/config.alloy` | Alloy pipeline config | bind mount |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket for Alloy log/metric discovery | bind mount (read-only) |
| `./provisioning/datasources/` | `/etc/grafana/provisioning/datasources/` | Grafana datasource provisioning | bind mount |

## Resource Estimates

| Component | CPU (cores) | Memory (min) | Memory (recommended) |
|-----------|-------------|-------------|---------------------|
| Grafana | 0.5 | 256MB | 512MB |
| Alloy | 0.5 | 256MB | 512MB |
| Loki | 1.0 | 512MB | 2GB |
| Mimir | 1.0 | 512MB | 2GB |
| Tempo | 0.5 | 256MB | 1GB |
| **Total** | **3.5** | **1.75GB** | **6GB** |

## Dependencies

- **Traefik** (infrastructure/traefik): Reverse proxy for HTTPS access to Grafana UI.
- **StepCA ACME**: TLS certificates via Traefik integration.
- **Docker socket**: Alloy needs read-only access to `/var/run/docker.sock` for container discovery, log collection, and Docker metrics.
- **DNS**: `grafana.lab.kemo.network` A record pointing to 192.168.62.30.

## Network Configuration

- **Static IP:** `192.168.62.30`
- **Network:** Bridged macvlan or equivalent on `192.168.62.0/23`
- Grafana exposed via Traefik with TLS at `https://grafana.lab.kemo.network`
- Alloy OTLP endpoints (4317/4318) exposed on the static IP for other workloads to send telemetry
- Loki (3100), Mimir (9009), Tempo (3200) endpoints exposed on the static IP for direct push from external sources
- Internal Docker network for inter-service communication

### Traefik Labels (Grafana)

```
traefik.enable=true
traefik.http.routers.grafana.rule=Host(`grafana.lab.kemo.network`)
traefik.http.routers.grafana.entrypoints=websecure
traefik.http.routers.grafana.tls=true
traefik.http.routers.grafana.tls.certresolver=step-ca
traefik.http.services.grafana.loadbalancer.server.port=3000
```

## Special Considerations

### Alloy Docker Socket Access
Alloy requires read-only access to the Docker socket (`/var/run/docker.sock`) to discover running containers and collect their logs and metrics. This is a privileged operation; mount as read-only (`:ro`).

### Alloy Configuration Format
Alloy uses the "River" configuration language (`.alloy` files), not the older YAML-based Grafana Agent config. The config defines a pipeline of components: sources, processors, and exporters.

### Alloy as Central Collector
Alloy should be configured to:
- Scrape Prometheus metrics from other Docker containers (via Docker service discovery)
- Collect Docker container logs and forward to Loki
- Accept OTLP traces (gRPC on 4317, HTTP on 4318) and forward to Tempo
- Optionally scrape its own internal metrics and node-level metrics

### Loki Single-Instance Mode
Run Loki in monolithic (single-instance) mode for homelab simplicity. Use the filesystem backend for chunks and index storage. Configure retention (e.g., 30 days) to manage disk usage.

### Mimir Single-Instance Mode
Run Mimir in monolithic mode with local filesystem storage. Configure retention and compaction settings appropriate for homelab scale. Mimir replaces Prometheus as the long-term metrics store.

### Tempo Single-Instance Mode
Run Tempo in monolithic mode with local filesystem backend. Configure trace retention (e.g., 7-14 days) since traces consume significant storage.

### Grafana Data Source Provisioning
Pre-provision Grafana data sources via a YAML file mounted to `/etc/grafana/provisioning/datasources/`:
- Loki at `http://loki:3100`
- Mimir (Prometheus type) at `http://mimir:9009/prometheus`
- Tempo at `http://tempo:3200`

This avoids manual data source configuration on first boot.

### Resource Scaling
Loki and Mimir are the most resource-hungry components. On a 128GB+ host, the recommended allocations above are conservative. Monitor actual usage and increase if the homelab grows in workload count.

### Retention Policies
Configure retention in each backend config file to prevent unbounded disk growth:
- Loki: 30-day retention
- Mimir: 90-day retention
- Tempo: 14-day retention
