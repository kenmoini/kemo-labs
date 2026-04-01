# File Sharing - Nginx + Copyparty

A dual-container file sharing solution: Nginx serves files for fast static downloads, while Copyparty provides a web-based file manager with upload, search, and media playback. Both mount the same data directory.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set COPYPARTY_PASSWORD

# Create data directory
mkdir -p ./data ./copyparty-db

# Ensure nginx.conf exists
# Edit ./nginx.conf as needed

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `COPYPARTY_PASSWORD` | Admin password for Copyparty file manager |

Nginx configuration is in `./nginx.conf`. Copyparty is configured via command-line arguments in docker-compose.yml. Both containers run as UID/GID 1000.

## Access

| URL | Purpose |
|-----|---------|
| `https://files.lab.kemo.dev` | Nginx file browser (downloads) |
| `https://upload.lab.kemo.dev` | Copyparty file manager (uploads, search, media) |

**Static IP:** 192.168.62.23

## Dependencies

- **DNS** -- two DNS names for the two interfaces
- **Traefik** -- TLS termination and hostname-based routing

## Maintenance

```bash
# View logs
docker compose logs -f

# Update images
docker compose pull && docker compose up -d

# Back up shared data
rsync -av ./data/ /path/to/backup/

# Copyparty features: drag-and-drop upload, full-text search,
# built-in audio/video player, markdown rendering
```

The `./data` directory is shared between both containers. Nginx serves files read-only while Copyparty allows read-write access. Traefik is configured to allow uploads up to 10 GB for Copyparty.
