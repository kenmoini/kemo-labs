# Kopia - Backup Solution

## Overview

Kopia is a fast, encrypted backup tool with deduplication. It backs up homelab data (configs, databases, media) to the RustFS S3 object store. Provides a web UI for managing snapshots, policies, and restore operations.

## Docker Image

- **Image:** `kopia/kopia:0.19`
- **Tag policy:** Pin to minor version

## Static IP & DNS

- **IP:** 192.168.62.22
- **DNS:** `backups.lab.kemo.network`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 51515 | TCP/HTTPS | Kopia server UI and API |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `KOPIA_PASSWORD` | Repository password (encryption key) | (secret) |
| `AWS_ACCESS_KEY_ID` | RustFS S3 access key | (from RustFS) |
| `AWS_SECRET_ACCESS_KEY` | RustFS S3 secret key | (from RustFS) |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./config:/app/config` | Kopia configuration and cache | 1-10 GB (cache) |
| `./logs:/app/logs` | Backup logs | 100 MB |
| Various source mounts | Data to back up (read-only) | N/A |

### Source Mounts (read-only)
Mount directories from other workloads that need backup:
```yaml
volumes:
  - /srv/databases:/sources/databases:ro
  - /srv/gitlab:/sources/gitlab:ro
  - /srv/paperless:/sources/paperless:ro
  - /srv/vault:/sources/vault:ro
  - /srv/authentik:/sources/authentik:ro
  - /srv/mailcow:/sources/mailcow:ro
```

## Resource Estimates

| Resource | Idle | Peak (during backup) |
|----------|------|------|
| CPU | 0.1 cores | 4 cores |
| RAM | 128 MB | 2 GB |

CPU/RAM spike during compression and deduplication of large backups.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| RustFS (S3) | **Required** | S3 backend for storing backup snapshots |
| DNS | Recommended | `backups.lab.kemo.network` |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.62.22
- Needs network access to RustFS at 192.168.62.20:9000
- Source data mounted as read-only bind mounts from host

## Special Considerations

### Repository Setup
Initialize the S3 repository before first backup:
```bash
docker exec kopia kopia repository create s3 \
  --bucket=backups \
  --endpoint=192.168.62.20:9000 \
  --disable-tls-verification \
  --access-key=$AWS_ACCESS_KEY_ID \
  --secret-access-key=$AWS_SECRET_ACCESS_KEY
```

### Backup Policies
- **Databases:** Every 6 hours, keep 7 daily / 4 weekly / 3 monthly
- **Configuration:** Daily, keep 30 daily / 12 weekly / 6 monthly
- **Media/Documents:** Daily, keep 7 daily / 4 weekly / 12 monthly
- **Compression:** Use `zstd` for best ratio/speed balance

### Complementary to Databasus
- Databasus handles database-level logical backups (pg_dump, mysqldump)
- Kopia handles filesystem-level backups of everything else
- Kopia can also back up the Databasus dump directory for off-site redundancy

### Server Mode
Run Kopia in server mode for web UI access and scheduled snapshots:
```bash
kopia server start --address=0.0.0.0:51515 --server-control-password=CONTROL_PASSWORD
```

### Encryption
All backups are encrypted at rest with the repository password. **Back up the repository password separately** — losing it means losing all backups.

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.kopia.rule=Host(`backups.lab.kemo.network`)"
  - "traefik.http.routers.kopia.tls=true"
  - "traefik.http.routers.kopia.tls.certresolver=step-ca"
  - "traefik.http.services.kopia.loadbalancer.server.port=51515"
  - "traefik.http.services.kopia.loadbalancer.server.scheme=https"
```
