# Kopia - Backup Solution

Kopia is a fast, encrypted backup tool with deduplication. It backs up homelab data (configs, databases, media) to the RustFS S3 object store and provides a web UI for managing snapshots, policies, and restores.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set KOPIA_REPOSITORY_PASSWORD, S3_ACCESS_KEY, S3_SECRET_KEY,
#   KOPIA_SERVER_PASSWORD

# Create directories
mkdir -p ./config ./cache ./logs

docker compose up -d

# Initialize the S3 repository (first run only)
docker exec kopia kopia repository create s3 \
  --bucket=backups \
  --endpoint=192.168.42.20:9000 \
  --disable-tls-verification \
  --access-key=$S3_ACCESS_KEY \
  --secret-access-key=$S3_SECRET_KEY
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `KOPIA_REPOSITORY_PASSWORD` | Repository encryption password |
| `S3_ACCESS_KEY` | RustFS S3 access key |
| `S3_SECRET_KEY` | RustFS S3 secret key |
| `KOPIA_SERVER_USER` | Web UI username (default: `admin`) |
| `KOPIA_SERVER_PASSWORD` | Web UI password |

Source directories to back up are mounted read-only in docker-compose.yml.

## Access

| URL | Purpose |
|-----|---------|
| `https://backups.lab.kemo.dev` | Kopia web UI |

**Static IP:** 192.168.42.22

## Dependencies

- **RustFS (S3)** -- S3 backend for storing backup snapshots (must be running)
- **DNS** -- hostname resolution

## Maintenance

```bash
# View logs
docker compose logs -f kopia

# List snapshots
docker exec kopia kopia snapshot list

# Create a manual snapshot
docker exec kopia kopia snapshot create /sources/databases

# Restore files
docker exec kopia kopia restore <snapshot-id> /tmp/restore/

# Verify repository integrity
docker exec kopia kopia repository validate-provider

# Update image
docker compose pull && docker compose up -d
```

All backups are encrypted with the repository password. Back up this password separately -- losing it means losing all backups. Kopia complements Databasus: Databasus handles database dumps, Kopia handles filesystem backups.
