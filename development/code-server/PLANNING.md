# Code Server - Browser-Based IDE

## Overview

Code Server runs VS Code in the browser, providing a consistent development environment accessible from any device. Persists workspace, extensions, and settings across sessions.

## Docker Image

- **Image:** `codercom/code-server:4.99.4`
- **Tag policy:** Pin to patch version

## Static IP & DNS

- **IP:** 192.168.62.42
- **DNS:** `code.lab.kemo.network`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | TCP/HTTP | VS Code Web UI |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PASSWORD` | Login password (or use `--auth none` behind Authentik) | (secret) |
| `HASHED_PASSWORD` | bcrypt hashed password (alternative) | (secret) |
| `SUDO_PASSWORD` | Password for sudo in terminal | (secret) |
| `DEFAULT_WORKSPACE` | Default workspace path | `/home/coder/workspace` |
| `PUID` | User ID | `1000` |
| `PGID` | Group ID | `1000` |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./config:/home/coder/.config` | VS Code settings, keybindings | 100 MB |
| `./workspace:/home/coder/workspace` | Project files | 10-50 GB |
| `./extensions:/home/coder/.local/share/code-server/extensions` | Installed extensions | 1-5 GB |

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 0.2 cores | 2 cores |
| RAM | 256 MB | 2 GB |

Depends on extensions loaded and language servers running.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| DNS | Recommended | `code.lab.kemo.network` |
| Traefik | Recommended | TLS + WebSocket support |
| Authentik | Optional | SSO protection via forward auth |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.62.42
- WebSocket support required in Traefik for terminal and editor

## Special Considerations

### Traefik WebSocket Support
Code Server requires WebSocket passthrough. Traefik handles this automatically, but ensure no middleware strips upgrade headers.

### Authentication Options
1. **Built-in password** — Simple, via `PASSWORD` env var
2. **Authentik forward auth** — Remove built-in auth (`--auth none`), protect with Traefik + Authentik middleware
3. Both can be layered for defense in depth

### Git Configuration
Mount git config and SSH keys for repo access:
```yaml
volumes:
  - ~/.gitconfig:/home/coder/.gitconfig:ro
  - ~/.ssh:/home/coder/.ssh:ro
```

### Development Tools
The base image is Debian-based. Install additional tools via a custom Dockerfile or entrypoint script:
```dockerfile
FROM codercom/code-server:4.99.4
RUN sudo apt-get update && sudo apt-get install -y \
    golang nodejs npm python3 python3-pip \
    && sudo rm -rf /var/lib/apt/lists/*
```

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.code.rule=Host(`code.lab.kemo.network`)"
  - "traefik.http.routers.code.tls=true"
  - "traefik.http.routers.code.tls.certresolver=step-ca"
  - "traefik.http.services.code.loadbalancer.server.port=8080"
```
