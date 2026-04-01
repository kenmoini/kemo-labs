# Landing Page - Homepage Dashboard

## Overview

Homepage is a modern, self-hosted application dashboard that serves as the central landing page for the homelab. It provides a single-pane-of-glass view of all services, their status, and quick-access links. Homepage supports service widgets that can display real-time data from integrated services (Pi-hole stats, Traefik routes, UPS status via PeaNUT, etc.).

## Container Image

- **Image:** `ghcr.io/gethomepage/homepage:latest`
- **Registry:** GitHub Container Registry (official)

## Static IP

- `192.168.62.14`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | Web UI |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `HOMEPAGE_ALLOWED_HOSTS` | Required: allowed Host headers | `home.lab.kemo.dev,192.168.62.14:3000` |
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone | `America/New_York` |

### Secret Injection

Homepage supports environment-based secret injection in config files:

- Variables prefixed with `HOMEPAGE_VAR_` have their values substituted for `{{HOMEPAGE_VAR_XXX}}` in config files.
- Variables prefixed with `HOMEPAGE_FILE_` point to files whose contents replace `{{HOMEPAGE_FILE_XXX}}` in config files.

This allows API keys and passwords to be kept out of config files.

## Storage / Volume Requirements

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./config/` | `/app/config` | Configuration YAML files |
| `/var/run/docker.sock` | `/var/run/docker.sock` (read-only) | Docker integration (optional) |

### Configuration Files

The `./config/` directory contains YAML files that define the dashboard layout:

| File | Purpose |
|------|---------|
| `settings.yaml` | Global settings (title, theme, layout, providers) |
| `bookmarks.yaml` | Bookmark links organized by category |
| `services.yaml` | Service cards with status widgets |
| `widgets.yaml` | Information widgets (datetime, search, resources) |
| `docker.yaml` | Docker provider config (if using Docker integration) |
| `custom.css` | Custom CSS overrides (optional) |
| `custom.js` | Custom JavaScript (optional) |

## Resource Estimates

| Resource | Estimate |
|----------|----------|
| CPU | 0.1 - 0.25 core |
| RAM | 64 - 128 MB |
| Disk | Minimal (config files only, < 1 MB) |

## Dependencies

| Dependency | Reason |
|------------|--------|
| DNS | Hostname resolution for `home.lab.kemo.dev` |
| Traefik | Reverse proxy for the web UI |
| All other services | Homepage displays status widgets for configured services |

## Network Configuration

- Static IP `192.168.62.14` on the homelab macvlan/ipvlan network.
- Exposed through Traefik as `home.lab.kemo.dev`.
- Podman socket access (read-only) enables automatic discovery and status display of Docker containers.
- Homepage needs network access to all services it monitors (for widget API calls).

## Traefik Integration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.homepage.rule=Host(`home.lab.kemo.dev`)"
  - "traefik.http.routers.homepage.entrypoints=websecure"
  - "traefik.http.routers.homepage.tls.certresolver=stepca"
  - "traefik.http.services.homepage.loadbalancer.server.port=3000"
```

## Service Widget Examples

Homepage can display real-time data from other homelab services. Example `services.yaml` entries:

```yaml
- Infrastructure:
    - Traefik:
        icon: traefik.svg
        href: https://traefik.lab.kemo.dev
        widget:
          type: traefik
          url: http://192.168.62.10:8080

    - Pi-hole:
        icon: pi-hole.svg
        href: https://pihole.lab.kemo.dev
        widget:
          type: pihole
          url: http://192.168.62.4
          key: "{{HOMEPAGE_VAR_PIHOLE_API_KEY}}"

    - PeaNUT:
        icon: peanut.svg
        href: https://peanut.lab.kemo.dev
        widget:
          type: peanut
          url: http://192.168.62.12:8081
```

## Special Considerations

1. **HOMEPAGE_ALLOWED_HOSTS:** This is a required environment variable. It must include the hostname(s) used to access Homepage, including the Traefik subdomain.
2. **Podman socket security:** Mounting the Podman socket gives Homepage read access to all container metadata. Consider using a Podman socket proxy for reduced attack surface.
3. **Widget API keys:** Many service widgets require API keys. Use the `HOMEPAGE_VAR_*` / `HOMEPAGE_FILE_*` mechanism to inject these securely rather than hardcoding them in `services.yaml`.
4. **Config hot-reload:** Homepage watches its config directory for changes and reloads automatically. No container restart needed when editing YAML files.
5. **Theme and layout:** Homepage supports light/dark themes and multiple layout modes (columns, rows). Configure in `settings.yaml`.
6. **Service ordering:** Services appear in `services.yaml` in the order defined. Group related services under category headers for a clean layout.
7. **Deployment order:** Homepage should be deployed last (or near-last) since its value comes from displaying the status of all other services that should already be running.
