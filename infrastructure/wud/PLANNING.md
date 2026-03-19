# WUD (What's Up Docker) - Container Update Monitor

## Overview

WUD monitors running Docker containers for available image updates by comparing local image tags against remote registry tags. It provides a web UI dashboard showing update status and can send notifications when updates are detected. WUD supports semver-aware tag comparison, digest tracking for mutable tags (e.g., `latest`), and per-container label-based configuration.

## Docker Image

- **Image:** `getwud/wud`
- **Registry:** Docker Hub
- **Source:** https://github.com/getwud/wud

## Static IP

- `192.168.62.9`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | Web UI and REST API (default, configurable via `WUD_SERVER_PORT`) |

## Environment Variables

### Server

| Variable | Purpose | Default |
|----------|---------|---------|
| `WUD_SERVER_PORT` | HTTP listener port | `3000` |
| `WUD_SERVER_ENABLED` | Enable/disable REST API | `true` |

### Watcher

| Variable | Purpose | Default |
|----------|---------|---------|
| `WUD_WATCHER_LOCAL_SOCKET` | Docker socket path | `/var/run/docker.sock` |
| `WUD_WATCHER_LOCAL_CRON` | Check schedule (cron expression) | `0 * * * *` (every hour) |
| `WUD_WATCHER_LOCAL_WATCHBYDEFAULT` | Monitor all containers by default | `true` |
| `WUD_WATCHER_LOCAL_WATCHALL` | Monitor all containers regardless of status | `false` |
| `WUD_WATCHER_LOCAL_WATCHEVENTS` | Monitor Docker events for changes | `true` |

### Ntfy Trigger

| Variable | Purpose | Default |
|----------|---------|---------|
| `WUD_TRIGGER_NTFY_HOMELAB_URL` | Ntfy server URL | `https://ntfy.sh` |
| `WUD_TRIGGER_NTFY_HOMELAB_TOPIC` | Ntfy topic name (required) | |
| `WUD_TRIGGER_NTFY_HOMELAB_PRIORITY` | Message priority (0-5) | |

### Common Trigger Options

| Variable | Purpose | Default |
|----------|---------|---------|
| `WUD_TRIGGER_NTFY_HOMELAB_MODE` | `simple` (per container) or `batch` (all at once) | `simple` |
| `WUD_TRIGGER_NTFY_HOMELAB_ONCE` | Only notify once per update (no repeats) | `true` |
| `WUD_TRIGGER_NTFY_HOMELAB_THRESHOLD` | Minimum change level: `all`, `major`, `minor`, `patch` | `all` |

### General

| Variable | Purpose | Default |
|----------|---------|---------|
| `TZ` | Timezone | `America/New_York` |

## Storage / Volume Requirements

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `/var/run/docker.sock` | `/var/run/docker.sock` (read-only) | Docker socket for container inspection |
| `./data/store` | `/store` | Persistent state (tracked image versions, update history) |

## Resource Estimates

| Resource | Estimate |
|----------|----------|
| CPU | 0.1 - 0.25 core |
| RAM | 64 - 128 MB |
| Disk | Minimal (~10 MB for state store) |

## Dependencies

| Dependency | Reason |
|------------|--------|
| Docker socket | Required to enumerate and inspect containers |
| Traefik | Reverse proxy and TLS termination for the web UI |
| DNS (PowerDNS) | `wud.lab.kemo.network` must resolve to 192.168.62.10 (Traefik) |
| Ntfy (192.168.62.82) | Push notification target for update alerts |

## Network Configuration

- Attach to the external `homelab` macvlan network with static IP `192.168.62.9`.
- Traefik routes `wud.lab.kemo.network` to port 3000 via Docker label discovery.
- WUD does not need to expose ports directly; Traefik handles ingress.

## Special Considerations

1. **Docker socket security:** Mount the Docker socket read-only (`:ro`). WUD only reads container metadata and does not start/stop containers unless an auto-update trigger is configured.
2. **Registry rate limits:** WUD queries Docker Hub and other registries to check for updates. The default hourly cron is reasonable, but digest watching increases API calls significantly. Consider adjusting the cron schedule or disabling digest watching for Hub-hosted images to avoid rate limits.
3. **Per-container labels:** Fine-tune monitoring with labels on each container: `wud.watch=true/false`, `wud.tag.include=<regex>`, `wud.tag.exclude=<regex>`, `wud.watch.digest=true/false`.
4. **Secret management:** WUD supports `__FILE` suffix on any env var to read secrets from mounted files instead of inline values.
5. **Persistent store:** Mount `/store` to retain state across restarts. Without it, WUD re-evaluates all containers on startup and may re-trigger notifications.
6. **Ntfy integration:** The Ntfy trigger sends notifications to the local Ntfy instance at `192.168.62.82`. Create a dedicated topic for WUD alerts.
