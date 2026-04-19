# Code Server - Browser-Based VS Code IDE

Code Server runs VS Code in the browser, providing a consistent development environment accessible from any device. Persists workspace, extensions, and settings across sessions.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set PASSWORD, SUDO_PASSWORD

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `PASSWORD` | Login password for the web UI |
| `SUDO_PASSWORD` | Password for sudo in the terminal |
| `DEFAULT_WORKSPACE` | Default workspace path (default: `/home/coder/workspace`) |
| `TZ` | Timezone |

## Access

| URL | Purpose |
|-----|---------|
| `https://code.lab.kemo.dev` | VS Code in the browser |

**Static IP:** 192.168.42.42

## Dependencies

- **DNS** -- `code.lab.kemo.dev`
- **Traefik** -- reverse proxy with WebSocket support (required for terminal and editor)
- **Authentik** (optional) -- SSO protection via forward auth

## Maintenance

```bash
# View logs
docker compose logs -f code-server

# Update image (pin to specific version)
docker compose pull && docker compose up -d

# Install additional development tools via terminal:
# sudo apt-get update && sudo apt-get install -y golang nodejs python3

# Back up workspace and settings
# Volumes: code-server-config, code-server-workspace, code-server-extensions
```

Resource usage depends on extensions loaded and language servers running (256 MB - 2 GB RAM). For Git access, mount `.gitconfig` and `.ssh` keys into the container. Authentication can be layered: built-in password plus Authentik forward auth.
