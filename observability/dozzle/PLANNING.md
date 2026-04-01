# Dozzle - Real-time Docker Log Viewer

## Overview

Dozzle is a lightweight, real-time log viewer for Docker containers. It provides a web-based UI to tail and search container logs without requiring any log storage backend. It connects directly to the Podman socket and streams logs in real time. Useful as a quick debugging tool alongside the full Grafana/Loki log pipeline.

## Container Images

| Component | Image | Tag |
|-----------|-------|-----|
| Dozzle | `amir20/dozzle` | `v8.12.8` |

> **Note:** Verify this tag against Docker Hub / GitHub releases at deployment time. Pin to a specific version.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 8080 | TCP | Dozzle | Web UI |

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `DOZZLE_LEVEL` | `info` | Log level for Dozzle itself |
| `DOZZLE_TAILSIZE` | `300` | Number of initial log lines to load per container |
| `DOZZLE_NO_ANALYTICS` | `true` | Disable anonymous analytics |
| `DOZZLE_ENABLE_ACTIONS` | `false` | Disable container start/stop/restart actions from UI (safety) |

### Optional Authentication

Dozzle supports simple file-based authentication. To enable:

| Variable | Value | Description |
|----------|-------|-------------|
| `DOZZLE_AUTH_PROVIDER` | `simple` | Enable simple auth |

Requires a `users.yml` file mounted to `/data/users.yml` with bcrypt-hashed passwords.

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | Podman socket (required, read-only) | bind mount |
| `./users.yml` | `/data/users.yml` | Optional: user authentication file | bind mount |

Dozzle is stateless and stores no data on disk. All logs are streamed in real-time from Docker.

## Resource Estimates

| Component | CPU (cores) | Memory (min) | Memory (recommended) |
|-----------|-------------|-------------|---------------------|
| Dozzle | 0.1 | 32MB | 128MB |

Dozzle is extremely lightweight. Memory usage scales slightly with the number of containers being viewed simultaneously.

## Dependencies

- **Podman socket**: Read-only access to `/var/run/docker.sock` is mandatory.
- **Traefik** (infrastructure/traefik): Reverse proxy for HTTPS access.
- **StepCA ACME**: TLS certificates via Traefik.
- **DNS**: `dozzle.lab.kemo.dev` A record pointing to 192.168.62.31.

## Network Configuration

- **Static IP:** `192.168.62.31`
- **Network:** Bridged macvlan or equivalent on `192.168.62.0/23`
- Exposed via Traefik with TLS at `https://dozzle.lab.kemo.dev`

### Traefik Labels

```
traefik.enable=true
traefik.http.routers.dozzle.rule=Host(`dozzle.lab.kemo.dev`)
traefik.http.routers.dozzle.entrypoints=websecure
traefik.http.routers.dozzle.tls=true
traefik.http.routers.dozzle.tls.certresolver=step-ca
traefik.http.services.dozzle.loadbalancer.server.port=8080
```

## Special Considerations

### Docker Socket Access
Dozzle requires read-only access to the Podman socket. Mount as `/var/run/docker.sock:/var/run/docker.sock:ro`. This grants visibility into all containers on the host.

### No Persistent Storage
Dozzle does not store logs. It streams directly from Docker's log driver. If you need persistent log storage and search, use the Grafana Alloy stack with Loki.

### Authentication Recommendation
For a homelab exposed on a LAN, consider enabling Dozzle's simple authentication to prevent unauthorized access to container logs, which may contain sensitive information. Generate password hashes with:
```bash
htpasswd -nbBC 10 "" 'your-password' | cut -d: -f2
```

### Multi-Host Support
Dozzle supports connecting to remote Docker hosts via TCP. For a single-host homelab this is not needed, but it can be configured later if the lab expands to multiple Docker hosts.

### Container Grouping
Dozzle automatically groups containers by Docker Compose project. This works out of the box with standard Compose labels.

### Lightweight Complement to Loki
Dozzle and Loki serve different purposes: Dozzle is for real-time tailing and quick debugging; Loki (via Grafana) is for historical log search and correlation. Running both is a common pattern.
