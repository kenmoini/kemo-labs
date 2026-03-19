# Dozzle - Real-time Docker Log Viewer

Dozzle is a lightweight, real-time log viewer for Docker containers. It streams logs directly from the Podman socket in the browser with no storage backend required. Useful as a quick debugging tool alongside the full Grafana/Loki log pipeline.

## Quick Start

```bash
docker compose up -d
```

No configuration files or persistent storage required. Dozzle is stateless.

## Configuration

| Variable | Purpose |
|----------|---------|
| `DOZZLE_LEVEL` | Log level for Dozzle itself (default: `info`) |
| `DOZZLE_TAILSIZE` | Initial log lines loaded per container (default: `300`) |
| `DOZZLE_NO_ANALYTICS` | Disable analytics (default: `true`) |
| `DOZZLE_ENABLE_ACTIONS` | Allow container start/stop from UI (default: `false`) |

Optional authentication: mount a `users.yml` file with bcrypt-hashed passwords and set `DOZZLE_AUTH_PROVIDER=simple`.

## Access

| URL | Purpose |
|-----|---------|
| `https://dozzle.lab.kemo.network` | Real-time log viewer |

**Static IP:** 192.168.62.31

## Dependencies

- **Podman socket** -- read-only access required (mounted as `/var/run/docker.sock`)
- **Traefik** -- reverse proxy for HTTPS access

## Maintenance

```bash
# View logs
docker compose logs -f dozzle

# Update image
docker compose pull && docker compose up -d

# Generate a password hash for authentication
htpasswd -nbBC 10 "" 'your-password' | cut -d: -f2
```

Dozzle is extremely lightweight (32-128 MB RAM). It does not store logs -- for persistent log storage and search, use the Grafana Alloy stack with Loki. Containers are automatically grouped by Docker Compose project.
