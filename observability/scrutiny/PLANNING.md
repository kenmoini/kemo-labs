# Scrutiny - Disk S.M.A.R.T. Monitoring

## Overview

Scrutiny is a hard drive health dashboard and monitoring tool that collects S.M.A.R.T. (Self-Monitoring, Analysis, and Reporting Technology) data from all disks in the system. It provides a web UI showing disk health status, historical trends, and failure predictions. Critical for a homelab with significant local storage to get early warning of disk failures.

Scrutiny has two deployment modes: an all-in-one "omnibus" container (web + collector) or separate web and collector containers. For a single-host homelab, the omnibus image is simplest.

## Docker Images

| Component | Image | Tag |
|-----------|-------|-----|
| Scrutiny (omnibus) | `ghcr.io/analogj/scrutiny` | `v0.8.1-omnibus` |

Alternative split deployment:

| Component | Image | Tag |
|-----------|-------|-----|
| Scrutiny Web | `ghcr.io/analogj/scrutiny` | `v0.8.1-web` |
| Scrutiny Collector | `ghcr.io/analogj/scrutiny` | `v0.8.1-collector` |

> **Note:** Verify these tags against GitHub releases at deployment time. The omnibus image bundles InfluxDB internally.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 8080 | TCP | Scrutiny Web | Web UI and API |
| 8086 | TCP | InfluxDB (internal) | Metrics storage (omnibus bundles this) |

Only port 8080 needs to be exposed externally. Port 8086 is internal to the omnibus container.

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `SCRUTINY_WEB_INFLUXDB_HOST` | `0.0.0.0` | InfluxDB bind address (omnibus default) |
| `SCRUTINY_WEB_INFLUXDB_PORT` | `8086` | InfluxDB port (omnibus default) |
| `COLLECTOR_CRON_SCHEDULE` | `0 */4 * * *` | How often to collect S.M.A.R.T. data (every 4 hours) |

Most configuration is done via a `scrutiny.yaml` config file rather than environment variables.

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `scrutiny-config` | `/opt/scrutiny/config` | Configuration and SQLite DB | 50MB |
| `scrutiny-influxdb` | `/opt/scrutiny/influxdb` | InfluxDB time-series data | 500MB - 2GB |
| `/run/udev` | `/run/udev:ro` | Host udev data for disk identification | bind mount (read-only) |

## Resource Estimates

| Component | CPU (cores) | Memory (min) | Memory (recommended) |
|-----------|-------------|-------------|---------------------|
| Scrutiny (omnibus) | 0.25 | 128MB | 512MB |

CPU usage spikes briefly during S.M.A.R.T. data collection (every few hours) and is negligible otherwise. InfluxDB (bundled in omnibus) accounts for most of the memory usage.

## Dependencies

- **Traefik** (infrastructure/traefik): Reverse proxy for HTTPS access.
- **StepCA ACME**: TLS certificates via Traefik.
- **DNS**: `scrutiny.lab.kemo.network` A record pointing to 192.168.62.33.
- **Host disk access**: Requires privileged access to host disk devices and smartmontools.

## Network Configuration

- **Static IP:** `192.168.62.33`
- **Network:** Bridged macvlan or equivalent on `192.168.62.0/23`
- Exposed via Traefik with TLS at `https://scrutiny.lab.kemo.network`

### Traefik Labels

```
traefik.enable=true
traefik.http.routers.scrutiny.rule=Host(`scrutiny.lab.kemo.network`)
traefik.http.routers.scrutiny.entrypoints=websecure
traefik.http.routers.scrutiny.tls=true
traefik.http.routers.scrutiny.tls.certresolver=step-ca
traefik.http.services.scrutiny.loadbalancer.server.port=8080
```

## Special Considerations

### Privileged Container / Device Access
Scrutiny's collector needs direct access to host disk devices to read S.M.A.R.T. data. This requires either:

1. **Privileged mode** (simplest):
   ```yaml
   privileged: true
   ```

2. **Capability-based** (more secure):
   ```yaml
   cap_add:
     - SYS_RAWIO
     - SYS_ADMIN
   devices:
     - /dev/sda
     - /dev/sdb
     # ... list all disks
   ```

The privileged approach is simpler for a homelab since the disk list may change. The capability-based approach requires explicitly listing each device.

### Device Discovery
Mount `/dev` or individual `/dev/sdX` and `/dev/nvmeXnY` devices into the container. Also mount `/run/udev:ro` for device metadata (model, serial, etc.).

Example device mounts:
```yaml
devices:
  - /dev/sda
  - /dev/sdb
  - /dev/nvme0n1
  - /dev/nvme1n1
volumes:
  - /run/udev:/run/udev:ro
```

Audit the host with `lsblk` or `smartctl --scan` before deployment to identify all physical disks.

### smartmontools Dependency
The Scrutiny collector image bundles `smartctl` internally. No host-level smartmontools installation is needed when using the Docker image.

### Collection Schedule
The default collection schedule runs every 30 minutes. For a homelab, every 4 hours (`0 */4 * * *`) is sufficient and reduces unnecessary disk I/O. Adjust via the `COLLECTOR_CRON_SCHEDULE` environment variable or in the config file.

### NVMe vs SATA/SAS
Scrutiny supports both NVMe and SATA/SAS drives. NVMe drives use different S.M.A.R.T. attributes. Ensure both device types are mounted if present.

### Notification Support
Scrutiny supports notifications via Shoutrrr (email, Slack, Discord, Gotify, etc.) for disk health alerts. Configure in `scrutiny.yaml`:
```yaml
notify:
  urls:
    - "discord://token@id"
```

### InfluxDB Data Retention
The bundled InfluxDB stores historical S.M.A.R.T. metrics. Data is relatively small (a few attributes per disk per collection interval). Even with years of data, storage stays under 2GB for a typical homelab disk count.

### Host Disk Changes
If physical disks are added or removed, restart the Scrutiny container so it re-scans available devices. If using explicit device mounts (non-privileged mode), update the compose file to include new devices.

### Grafana Integration
Scrutiny's bundled InfluxDB can be added as a data source in Grafana for unified disk health dashboards alongside other metrics. The InfluxDB API is accessible on port 8086 if exposed.
