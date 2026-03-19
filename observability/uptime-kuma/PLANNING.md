# Uptime Kuma - Uptime Monitoring

## Overview

Uptime Kuma is a self-hosted monitoring tool that checks the availability of services via HTTP(S), TCP, DNS, ping, and other protocols. It provides a clean web UI with status pages, notifications (email, Slack, Discord, etc.), and historical uptime data. It will monitor all homelab services and external dependencies.

## Docker Images

| Component | Image | Tag |
|-----------|-------|-----|
| Uptime Kuma | `louislam/uptime-kuma` | `1.23.16` |

> **Note:** Verify this tag against Docker Hub / GitHub releases at deployment time. Uptime Kuma uses a single container with an embedded SQLite database.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 3001 | TCP | Uptime Kuma | Web UI and API |

## Environment Variables

Uptime Kuma uses very few environment variables. Most configuration is done through the web UI after first launch.

| Variable | Value | Description |
|----------|-------|-------------|
| `UPTIME_KUMA_PORT` | `3001` | Listening port (default) |
| `DATA_DIR` | `/app/data` | Data directory path (default) |

### Optional

| Variable | Value | Description |
|----------|-------|-------------|
| `UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN` | `true` | Allow embedding in iframes (for Grafana dashboards) |
| `NODE_EXTRA_CA_CERTS` | `/app/data/ca-certs/root_ca.crt` | Custom CA certificate for monitoring internal TLS services |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `uptime-kuma-data` | `/app/data` | SQLite DB, config, certificates | 500MB - 1GB |
| `./ca-certs/` | `/app/data/ca-certs` | Optional: custom CA certs for internal TLS verification | bind mount |

The SQLite database stores all monitor configuration, heartbeat history, and notification settings. Back up the `/app/data` volume regularly.

## Resource Estimates

| Component | CPU (cores) | Memory (min) | Memory (recommended) |
|-----------|-------------|-------------|---------------------|
| Uptime Kuma | 0.25 | 128MB | 256MB |

Resource usage scales with the number of monitors and check frequency. For a homelab with 50-100 monitors at 60-second intervals, 256MB is sufficient.

## Dependencies

- **Traefik** (infrastructure/traefik): Reverse proxy for HTTPS access.
- **StepCA ACME**: TLS certificates via Traefik.
- **DNS**: `uptime.lab.kemo.network` A record pointing to 192.168.62.32.
- **StepCA root certificate** (optional): If monitoring internal HTTPS services signed by StepCA, mount the root CA cert and set `NODE_EXTRA_CA_CERTS` so Uptime Kuma trusts them.

## Network Configuration

- **Static IP:** `192.168.62.32`
- **Network:** Bridged macvlan or equivalent on `192.168.62.0/23`
- Exposed via Traefik with TLS at `https://uptime.lab.kemo.network`
- Needs outbound network access to reach monitored services (both internal LAN and external internet)

### Traefik Labels

```
traefik.enable=true
traefik.http.routers.uptime-kuma.rule=Host(`uptime.lab.kemo.network`)
traefik.http.routers.uptime-kuma.entrypoints=websecure
traefik.http.routers.uptime-kuma.tls=true
traefik.http.routers.uptime-kuma.tls.certresolver=step-ca
traefik.http.services.uptime-kuma.loadbalancer.server.port=3001
```

## Special Considerations

### Custom CA Certificates
Since the homelab uses StepCA for internal TLS, Uptime Kuma needs the StepCA root CA certificate to validate HTTPS endpoints without triggering certificate errors. Mount the root CA and set `NODE_EXTRA_CA_CERTS`. Alternatively, individual monitors can be configured to ignore TLS errors, but trusting the CA is cleaner.

### First-Run Setup
Uptime Kuma requires creating an admin account on first access via the web UI. There is no way to pre-seed credentials via environment variables. Complete this step immediately after deployment.

### Notification Channels
Configure notification channels (email, Discord, Slack, webhook, etc.) after first login. Uptime Kuma supports 90+ notification providers. Consider setting up at least one push notification channel for critical service alerts.

### Status Pages
Uptime Kuma can serve public status pages showing the health of selected monitors. These can be exposed via a separate subdomain if desired (e.g., `status.lab.kemo.network`).

### SQLite Considerations
Uptime Kuma uses SQLite exclusively (no external database option). This is fine for homelab scale but means:
- Backup is simply copying the `/app/data` directory
- No concurrent write scaling (not needed for single-instance)
- Database can grow over time with heartbeat history; configure data retention in the UI

### Monitoring the Monitoring
Consider adding an external uptime check (e.g., a simple cron curl from another machine) to detect if Uptime Kuma itself goes down.

### Grafana Integration
Uptime Kuma exposes a Prometheus-compatible metrics endpoint at `/metrics`. Configure the Grafana Alloy stack to scrape this endpoint for uptime data in Grafana dashboards.

### Iframe Embedding
Set `UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN=true` if you want to embed Uptime Kuma status pages in Grafana dashboards or a homepage dashboard.
