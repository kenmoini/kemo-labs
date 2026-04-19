# Scrutiny - Disk S.M.A.R.T. Monitoring

Scrutiny monitors hard drive health by collecting S.M.A.R.T. data from all disks, providing a web dashboard with health status, historical trends, and failure predictions. Uses the omnibus image which bundles the web UI, collector, and InfluxDB.

## Quick Start

```bash
# Identify host disks
lsblk
smartctl --scan

# Edit docker-compose.yml to list your disk devices under 'devices:'

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `COLLECTOR_CRON_SCHEDULE` | S.M.A.R.T. collection frequency (default: `0 */4 * * *`) |

Edit the `devices:` section in docker-compose.yml to match your host disks (e.g., `/dev/sda`, `/dev/nvme0n1`). The container needs `SYS_RAWIO` and `SYS_ADMIN` capabilities for disk access.

## Access

| URL | Purpose |
|-----|---------|
| `https://scrutiny.lab.kemo.dev` | Disk health dashboard |

**Static IP:** 192.168.42.33

## Dependencies

- **Traefik** -- reverse proxy for HTTPS access
- **Host disk access** -- requires capabilities and device passthrough

## Maintenance

```bash
# View logs
docker compose logs -f scrutiny

# Update image
docker compose pull && docker compose up -d

# If disks are added or removed, restart the container
docker compose restart scrutiny

# Configure notifications in scrutiny.yaml for disk health alerts
# Supports Discord, Slack, email via Shoutrrr

# InfluxDB data (bundled) stays under 2 GB for typical homelab disk counts
```

Mount `/run/udev:ro` for device metadata (model, serial). Audit your host with `smartctl --scan` before deployment to identify all physical disks. Both NVMe and SATA/SAS drives are supported.
