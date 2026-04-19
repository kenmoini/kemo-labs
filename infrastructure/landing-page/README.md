# Landing Page - Homepage Dashboard

Homepage is a self-hosted application dashboard providing a single-pane-of-glass view of all homelab services, their status, and quick-access links with real-time service widgets.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set PIHOLE_API_KEY, PDNS_AUTH_API_KEY, and other widget API keys

# Configure dashboard layout in ./config/:
#   settings.yaml, services.yaml, bookmarks.yaml, widgets.yaml

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `HOMEPAGE_ALLOWED_HOSTS` | Required: allowed Host headers for the web UI |
| `HOMEPAGE_VAR_PIHOLE_API_KEY` | Pi-hole API key for widget |
| `HOMEPAGE_VAR_PDNS_AUTH_API_KEY` | PowerDNS API key for widget |
| `PUID` / `PGID` | User/group IDs for file permissions |

Dashboard layout is defined in YAML files under `./config/`. Homepage watches for changes and reloads automatically -- no restart needed.

## Access

| URL | Purpose |
|-----|---------|
| `https://home.lab.kemo.dev` | Homepage dashboard |

**Static IP:** 192.168.42.14

## Dependencies

- **DNS** -- hostname resolution
- **Traefik** -- reverse proxy for the web UI
- **All other services** -- Homepage displays status widgets for configured services

Deploy Homepage last (or near-last) since its value comes from showing the status of other services.

## Maintenance

```bash
# View logs
docker compose logs -f homepage

# Update image
docker compose pull && docker compose up -d

# Edit dashboard layout (hot-reload, no restart needed)
vi ./config/services.yaml
```

Use `HOMEPAGE_VAR_*` environment variables to inject API keys into config files rather than hardcoding secrets.
