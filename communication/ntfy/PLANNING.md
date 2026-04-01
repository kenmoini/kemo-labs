# Ntfy - Self-Hosted Push Notifications

## Overview

Ntfy (pronounced "notify") is a simple HTTP-based pub-sub notification service. It allows sending push notifications to phones and desktops via scripts, APIs, or other services using a simple HTTP PUT/POST request. It supports topics, authentication, attachments, and has native mobile apps for Android and iOS.

- **Project URL:** https://github.com/binwiederhier/ntfy
- **Documentation:** https://docs.ntfy.sh/
- **Docker Hub:** https://hub.docker.com/r/binwiederhier/ntfy
- **Static IP:** 192.168.62.82
- **DNS Zone:** lab.kemo.dev

## Container Image

| Service | Image | Purpose |
|---------|-------|---------|
| Ntfy | `binwiederhier/ntfy:latest` | Push notification server |

## Required Ports

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 80 | TCP | Ntfy | HTTP API and web UI |

Ntfy sits behind Traefik for TLS termination.

## Environment Variables

```bash
# Timezone
TZ=America/New_York

# Ntfy configuration is primarily done via server.yml
# The following are set in server.yml, not as env vars:
# - base-url
# - listen-http
# - behind-proxy
# - cache-file
# - attachment-cache-dir
# - auth-default-access
```

## Storage / Volume Requirements

| Volume/Mount | Purpose | Size Estimate |
|--------------|---------|---------------|
| `ntfy-cache` | SQLite message cache | 50-200MB |
| `ntfy-attachments` | Uploaded file attachments | 100MB-1GB |
| `ntfy-auth` | User database for authentication | <1MB |
| `server.yml` | Server configuration (bind mount) | <1KB |

**Total disk:** Under 2GB for typical homelab usage.

## Resource Estimates

| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| RAM | 32MB | 64MB | Extremely lightweight Go binary |
| CPU | 0.1 cores | 0.25 cores | Minimal CPU, mostly idle |
| Disk | 100MB | 1GB | Cache + attachments |

Ntfy is one of the lightest services in the lab. On a 128GB+ host, resource usage is negligible.

## Dependencies

- **Traefik:** TLS termination and routing
- **StepCA:** TLS certificates via Traefik ACME integration
- **DNS:** A record for `ntfy.lab.kemo.dev`

No database dependency -- ntfy uses an embedded SQLite cache.

## Notification Sources (Consumers)

The following lab services will send notifications to ntfy:

| Service | Purpose |
|---------|---------|
| **Uptime Kuma** | Downtime and recovery alerts |
| **Scrutiny** | Disk health warnings and SMART failures |
| **Grafana** | Metric threshold alerts |
| **WUD (What's Up Docker)** | Container image update notifications |
| **Home Assistant** | Home automation alerts and events |

Each service publishes to its own topic (e.g., `uptime`, `disks`, `grafana`, `docker-updates`, `homeassistant`).

## Network Configuration

### Traefik Integration

```yaml
services:
  ntfy:
    image: binwiederhier/ntfy:latest
    container_name: ntfy
    restart: unless-stopped
    command: serve
    volumes:
      - ntfy-cache:/var/cache/ntfy
      - ntfy-attachments:/var/lib/ntfy/attachments
      - ntfy-auth:/var/lib/ntfy
      - ./server.yml:/etc/ntfy/server.yml:ro
    networks:
      homelab:
        ipv4_address: 192.168.62.82
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ntfy.rule=Host(`ntfy.lab.kemo.dev`)"
      - "traefik.http.routers.ntfy.entrypoints=websecure"
      - "traefik.http.routers.ntfy.tls.certresolver=stepca"
      - "traefik.http.services.ntfy.loadbalancer.server.port=80"
```

### Static IP

```
ntfy.lab.kemo.dev.    IN A    192.168.62.82
```

## Special Considerations

### 1. Authentication

Ntfy supports user-based access control. By default, topics are open. For a homelab, consider setting `auth-default-access: deny-all` and creating users for each publishing service:

```bash
docker exec ntfy ntfy user add --role=admin admin
docker exec ntfy ntfy access admin '*' rw
```

### 2. Mobile App

The ntfy Android app (available on F-Droid and Play Store) and iOS app can connect to the self-hosted instance by entering `https://ntfy.lab.kemo.dev` as the server URL.

### 3. Publishing Notifications

```bash
# Simple notification
curl -d "Disk /dev/sda health warning" https://ntfy.lab.kemo.dev/disks

# With title and priority
curl -H "Title: Server Down" -H "Priority: urgent" \
  -d "web-server is unreachable" https://ntfy.lab.kemo.dev/uptime
```

### 4. Cache Duration

The default message cache is 12 hours. This allows mobile clients to catch up on missed notifications. Adjust `cache-duration` in `server.yml` if needed.

### 5. Attachment Limits

Default attachment settings allow up to 15MB per file. Adjust in `server.yml` if services need to send larger files.

### 6. Backup Strategy

- **Cache DB:** Transient message cache, not critical to back up
- **Auth DB:** Back up `/var/lib/ntfy/user.db` if using authentication
- **Attachments:** Ephemeral by default (auto-deleted after cache duration)

### 7. Health Check

Ntfy exposes a health endpoint:
```
GET https://ntfy.lab.kemo.dev/v1/health
```
