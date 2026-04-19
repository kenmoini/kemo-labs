# Dropbox - File Sharing (NGINX + Copyparty)

## Overview

A dual-container file sharing solution: NGINX serves files for fast static downloads, while Copyparty provides a web-based file manager with upload, search, and media playback. Both mount the same data directory, giving two complementary interfaces to the same files.

## Container Images

| Container | Image | Purpose |
|-----------|-------|---------|
| NGINX | `nginx:1.27-alpine` | Static file serving / downloads |
| Copyparty | `ghcr.io/9001/copyparty:latest` | Upload, file management, search, media player |

## Static IP & DNS

- **IP:** 192.168.42.23
- **DNS:** `files.lab.kemo.dev` (NGINX), `upload.lab.kemo.dev` (Copyparty)

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 80 | TCP/HTTP | NGINX | Static file serving |
| 3923 | TCP/HTTP | Copyparty | Web UI with upload |

## Environment Variables

### Copyparty
| Variable | Description | Example |
|----------|-------------|---------|
| `NO_ACODE` | Disable audio codec (saves RAM) | `1` |
| `NO_THUMB` | Disable thumbnail generation | `0` |

Copyparty is primarily configured via command-line arguments rather than env vars.

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./data:/srv/files` | Shared file storage (both containers) | 10-500+ GB |
| `./nginx.conf:/etc/nginx/conf.d/default.conf:ro` | NGINX site config | < 1 KB |
| `./copyparty-db:/var/lib/copyparty` | Copyparty database (search index, metadata) | 100 MB - 1 GB |

### NGINX Configuration
```nginx
server {
    listen 80;
    server_name files.lab.kemo.dev;
    root /srv/files;
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

## Resource Estimates

| Container | CPU (idle) | CPU (peak) | RAM (idle) | RAM (peak) |
|-----------|-----------|-----------|-----------|-----------|
| NGINX | 0.05 cores | 0.5 cores | 16 MB | 128 MB |
| Copyparty | 0.1 cores | 1 core | 64 MB | 512 MB |
| **Total** | **0.15 cores** | **1.5 cores** | **80 MB** | **640 MB** |

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| DNS | Recommended | Two DNS names for the two interfaces |
| Traefik | Recommended | TLS and routing by hostname |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.42.23
- Both containers share the same IP via the same compose network
- Traefik routes by hostname:
  - `files.lab.kemo.dev` → NGINX port 80
  - `upload.lab.kemo.dev` → Copyparty port 3923

## Special Considerations

### File Permissions
Both containers must agree on file ownership. Use a shared UID/GID:
```yaml
# Both containers
user: "1000:1000"
```

### Copyparty Features
- **Upload:** Drag-and-drop web uploads with resume support
- **Search:** Full-text search with SQLite FTS index
- **Media:** Built-in audio/video player, image gallery
- **Markdown:** Renders .md files as HTML
- **Accounts:** Built-in auth with per-folder permissions

### Copyparty Command
```yaml
command: >
  --i 0.0.0.0 -p 3923
  -a admin:${COPYPARTY_PASSWORD}:rwmd:/srv/files
  --urlbase /
```

### Upload Size Limits
Configure Traefik to allow large uploads for Copyparty:
```yaml
- "traefik.http.middlewares.upload-size.buffering.maxRequestBodyBytes=10737418240"  # 10 GB
```

## Traefik Labels

```yaml
labels:
  # NGINX (downloads)
  - "traefik.http.routers.files.rule=Host(`files.lab.kemo.dev`)"
  - "traefik.http.routers.files.tls=true"
  - "traefik.http.routers.files.tls.certresolver=step-ca"
  - "traefik.http.services.files.loadbalancer.server.port=80"
  # Copyparty (uploads/management)
  - "traefik.http.routers.upload.rule=Host(`upload.lab.kemo.dev`)"
  - "traefik.http.routers.upload.tls=true"
  - "traefik.http.routers.upload.tls.certresolver=step-ca"
  - "traefik.http.services.upload.loadbalancer.server.port=3923"
```
