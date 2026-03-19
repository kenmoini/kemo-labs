# WUD - What's Up Docker

WUD monitors Docker containers for available image updates and sends notifications via Ntfy when new versions are detected. It provides a web dashboard for reviewing update status across all running containers.

## Quick Start

```bash
# Copy and configure environment variables
cp .env.example .env
# Edit .env: adjust Ntfy URL/topic and watcher schedule as needed

# Create persistent storage directory
mkdir -p ./data/store

# Start WUD
docker compose up -d
```

## Configuration

| Variable | Purpose | Default |
|----------|---------|---------|
| `TZ` | Timezone | `America/New_York` |
| `WUD_WATCHER_LOCAL_CRON` | Update check schedule (cron) | `0 */6 * * *` |
| `WUD_WATCHER_LOCAL_WATCHBYDEFAULT` | Monitor all containers | `true` |
| `WUD_TRIGGER_NTFY_HOMELAB_URL` | Ntfy server URL | `http://192.168.62.82` |
| `WUD_TRIGGER_NTFY_HOMELAB_TOPIC` | Ntfy notification topic | `wud` |
| `WUD_TRIGGER_NTFY_HOMELAB_PRIORITY` | Notification priority (0-5) | `3` |

### Per-Container Labels

Add labels to individual containers to control WUD behavior:

- `wud.watch=true/false` -- opt in or out of monitoring
- `wud.tag.include=<regex>` -- only match tags matching this pattern
- `wud.tag.exclude=<regex>` -- skip tags matching this pattern
- `wud.watch.digest=true` -- track digest changes for mutable tags (e.g., `latest`)

## Access

| URL | Purpose |
|-----|---------|
| `https://wud.lab.kemo.network` | WUD web dashboard |

**Static IP:** 192.168.62.9

## Dependencies

- **Docker socket** -- mounted read-only for container inspection
- **Traefik** -- reverse proxy with TLS via StepCA
- **DNS** -- `wud.lab.kemo.network` must resolve to Traefik (192.168.62.10)
- **Ntfy** (192.168.62.82) -- notification delivery target

## Maintenance

```bash
# View logs
docker compose logs -f wud

# Update WUD image
docker compose pull && docker compose up -d

# Check health
curl -s http://192.168.62.9:3000/health

# Restart after config changes
docker compose down && docker compose up -d
```

WUD stores its state in `./data/store/`. Back up this directory to preserve update
history and avoid duplicate notifications after a rebuild.
