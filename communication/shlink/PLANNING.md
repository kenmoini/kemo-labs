# Shlink - URL Shortener

## Overview

Shlink is a self-hosted URL shortener with a REST API interface. It provides short URL generation, visit tracking/analytics, QR code generation, and tag-based organization. It consists of two components: the Shlink server (API + redirect engine) and an optional web client for management.

- **Project URL:** https://github.com/shlinkio/shlink
- **Documentation:** https://shlink.io/documentation/
- **Docker Hub:** https://hub.docker.com/r/shlinkio/shlink
- **Static IP:** 192.168.42.81
- **DNS Zone:** lab.kemo.dev

## Container Images

| Service | Image | Purpose |
|---------|-------|---------|
| Shlink Server | `shlinkio/shlink:5.0.1` | URL shortener API and redirect engine |
| Shlink Web Client | `shlinkio/shlink-web-client:4.7.0` | Web-based management UI |

## Required Ports

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 8080 | TCP | Shlink Server | HTTP API and redirect endpoint |
| 8081 | TCP | Shlink Web Client | HTTP web management UI |

Both services should sit behind Traefik for TLS termination.

## Environment Variables

### Shlink Server

```bash
# Short domain configuration
DEFAULT_DOMAIN=s.lab.kemo.dev
IS_HTTPS_ENABLED=true

# Database - using shared PostgreSQL
DB_DRIVER=postgres
DB_HOST=postgres.lab.kemo.dev
DB_PORT=5432
DB_NAME=shlink
DB_USER=shlink
DB_PASSWORD=<secure-password>

# Timezone
TZ=America/New_York

# URL validation
AUTO_RESOLVE_TITLES=true
VALIDATE_URLS=true

# Redirect behavior
DEFAULT_SHORT_CODES_LENGTH=5
REDIRECT_STATUS_CODE=302
REDIRECT_APPEND_EXTRA_PATH=false

# Visits tracking
ANONYMIZE_REMOTE_ADDR=true
TRACK_ORPHAN_VISITS=true
DISABLE_TRACKING=false

# GeoLite2 for IP geolocation (optional, requires free license key)
# GEOLITE_LICENSE_KEY=<your-maxmind-license-key>

# API key (generated on first run, or set manually)
# Initial API key can be created via CLI after first start:
#   docker exec shlink shlink api-key:generate

# Task workers
TASK_WORKER_NUM=4
WEB_WORKER_NUM=8

# Redis for caching (optional, improves performance)
# REDIS_SERVERS=redis://redis.lab.kemo.dev:6379

# Robots.txt behavior - disallow indexing of short URLs
ROBOTS_ALLOW_ALL_SHORT_URLS=false

# QR codes
DEFAULT_QR_CODE_SIZE=300
DEFAULT_QR_CODE_FORMAT=png

# Memory limit
MEMORY_LIMIT=512M
```

### Shlink Web Client

```bash
# The web client is a static SPA that connects to Shlink's API
# Configuration is done in the browser UI by adding a server:
#   Server URL: https://s.lab.kemo.dev
#   API Key: <generated-api-key>

# Optional: Pre-configure servers via environment variable
SHLINK_SERVER_URL=https://s.lab.kemo.dev
SHLINK_SERVER_API_KEY=<api-key>
SHLINK_SERVER_NAME="Lab Shlink"
```

## Storage / Volume Requirements

| Volume/Mount | Purpose | Size Estimate |
|--------------|---------|---------------|
| `shlink-data` | GeoLite2 database cache, locks | 100-200MB |

Shlink is primarily stateless -- all persistent data is stored in the PostgreSQL database. The only local storage needed is for the GeoLite2 IP geolocation database (downloaded periodically) and temporary files.

**Total disk:** Less than 1GB

## Resource Estimates

| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| RAM | 128MB | 256-512MB | Very lightweight PHP application |
| CPU | 0.5 cores | 1 core | Minimal CPU usage unless high traffic |
| Disk | 500MB | 1GB | Mostly for GeoLite2 DB |

Shlink is extremely lightweight. On a 128GB+ host, resource usage is negligible.

## Dependencies

- **Database:** Shared PostgreSQL (lab-wide PGSQL instance)
  - Database: `shlink`
  - User: `shlink`
  - Must be created before first start
- **Redis:** Optional but recommended for caching (can use shared Redis if available)
- **Traefik:** For TLS termination and routing
- **StepCA:** TLS certificates via Traefik ACME integration
- **DNS:** A record for the short URL domain

## Network Configuration

### Traefik Integration

Shlink should be fully behind Traefik. Both the server and web client are HTTP services.

#### Shlink Server (API + Redirects)

```yaml
services:
  shlink:
    image: shlinkio/shlink:5.0.1
    container_name: shlink
    restart: unless-stopped
    environment:
      # ... (see environment variables above)
    volumes:
      - shlink-data:/etc/shlink/data
    networks:
      - traefik
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.shlink.rule=Host(`s.lab.kemo.dev`)"
      - "traefik.http.routers.shlink.entrypoints=websecure"
      - "traefik.http.routers.shlink.tls=true"
      - "traefik.http.routers.shlink.tls.certresolver=stepca"
      - "traefik.http.services.shlink.loadbalancer.server.port=8080"
```

#### Shlink Web Client

```yaml
  shlink-web:
    image: shlinkio/shlink-web-client:4.7.0
    container_name: shlink-web
    restart: unless-stopped
    environment:
      SHLINK_SERVER_URL: "https://s.lab.kemo.dev"
      SHLINK_SERVER_NAME: "Lab Shlink"
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.shlink-web.rule=Host(`shlink.lab.kemo.dev`)"
      - "traefik.http.routers.shlink-web.entrypoints=websecure"
      - "traefik.http.routers.shlink-web.tls=true"
      - "traefik.http.routers.shlink-web.tls.certresolver=stepca"
      - "traefik.http.services.shlink-web.loadbalancer.server.port=8080"
```

### Static IP

The static IP 192.168.42.81 is assigned for DNS purposes. Since Shlink is fully behind Traefik, the container itself does not need the static IP directly -- Traefik handles routing based on hostname. The static IP is for the DNS A record pointing to the host/Traefik instance if Shlink gets its own dedicated IP, or it can share the Traefik LB IP with host-based routing.

If a dedicated IP is desired (e.g., for a short domain that should resolve to its own IP):

```yaml
networks:
  macvlan:
    external: true

services:
  shlink:
    networks:
      macvlan:
        ipv4_address: 192.168.42.81
      traefik:
```

## DNS Requirements

```
; Short URL domain - points to Traefik LB or dedicated IP
s.lab.kemo.dev.             IN A     192.168.42.81

; Web client management UI
shlink.lab.kemo.dev.        IN A     192.168.42.81
```

The short URL domain (`s.lab.kemo.dev`) should be as short as possible. Consider using a shorter domain if available for external use.

## Special Considerations

### 1. Database Initialization

The Shlink database schema is created automatically on first start. Ensure the PostgreSQL database and user exist before starting:

```sql
CREATE DATABASE shlink;
CREATE USER shlink WITH PASSWORD '<secure-password>';
GRANT ALL PRIVILEGES ON DATABASE shlink TO shlink;
ALTER DATABASE shlink OWNER TO shlink;
```

### 2. API Key Generation

After first start, generate an API key for the web client and integrations:

```bash
docker exec shlink shlink api-key:generate
```

This key is needed to configure the Shlink Web Client.

### 3. GeoLite2 IP Geolocation

For visit analytics with geographic data, a free MaxMind GeoLite2 license key is needed:
1. Register at https://www.maxmind.com/en/geolite2/signup
2. Generate a license key
3. Set `GEOLITE_LICENSE_KEY` in the environment

Without this, visits are still tracked but without geographic information.

### 4. Short Domain Strategy

- Use `s.lab.kemo.dev` for internal/lab short URLs
- For external/public use, consider registering a short domain (e.g., `kemo.sh`) and adding it as an additional domain in Shlink
- Multiple domains can be configured with `DEFAULT_DOMAIN` and additional domains via the API

### 5. Redis Caching

If a shared Redis instance is available, connecting Shlink to it improves performance for high-traffic short URLs by caching redirects:

```bash
REDIS_SERVERS=redis://:password@redis.lab.kemo.dev:6379
```

### 6. URL Validation

With `VALIDATE_URLS=true`, Shlink will verify that target URLs are reachable before creating short URLs. This prevents creating short links to dead URLs but adds latency to creation. Set to `false` for internal URLs that may not be publicly reachable.

### 7. Import from Other Services

Shlink supports importing short URLs from other services:
```bash
docker exec shlink shlink short-url:import csv < urls.csv
```

### 8. Webhooks and Integrations

Shlink can notify external services when short URLs are visited:
```bash
# Create a webhook via the API
POST /rest/v3/webhooks
```

### 9. Backup Strategy

- **Database:** Back up the `shlink` PostgreSQL database (part of shared PGSQL backup strategy)
- **GeoLite2 cache:** Not critical, re-downloaded on restart
- **API keys:** Stored in database, backed up with DB

### 10. Health Check

Shlink exposes a health endpoint:
```
GET https://s.lab.kemo.dev/rest/health
```

Use this for Traefik health checks and monitoring.
