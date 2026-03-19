# Draw.io - Diagramming Tool

Draw.io (diagrams.net) is a self-hosted diagramming application for creating flowcharts, network diagrams, UML diagrams, and architecture diagrams. Runs entirely in the browser with no external cloud dependencies.

## Quick Start

```bash
docker compose up -d
```

No configuration files, persistent storage, or database required. Draw.io is completely stateless.

## Configuration

| Variable | Purpose |
|----------|---------|
| `DRAWIO_SELF_CONTAINED` | Run without external dependencies (set to `1`) |
| `DRAWIO_BASE_URL` | Base URL for the application |
| `LETS_ENCRYPT_ENABLED` | Disable built-in TLS (set to `false`, Traefik handles it) |

All diagram data is stored client-side (browser) or saved to external storage (Git, downloaded files). No server-side data to back up.

## Access

| URL | Purpose |
|-----|---------|
| `https://drawio.lab.kemo.network` | Diagramming application |

**Static IP:** 192.168.62.52

## Dependencies

- **Traefik** -- reverse proxy with TLS termination

No database or cache dependencies. This is the simplest workload in the documentation stack.

## Maintenance

```bash
# View logs
docker compose logs -f drawio

# Update image
docker compose pull && docker compose up -d

# No backups needed -- Draw.io is stateless
# Users save diagrams locally or to Git
```

Draw.io runs on Tomcat/Java with a 1 GB memory limit. It has no built-in authentication -- protect with Traefik middleware (Authentik forward auth or BasicAuth) if needed. Optionally integrate with GitLab via `DRAWIO_GITLAB_*` environment variables.
