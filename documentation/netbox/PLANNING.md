# Netbox - Network Documentation & IPAM

## Overview

Netbox is a comprehensive network documentation and IP Address Management (IPAM) tool. It provides a centralized source of truth for network infrastructure including IP addresses, VLANs, racks, devices, cables, circuits, and more. In this homelab, Netbox will serve as the primary infrastructure documentation and IPAM system.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| Netbox (web + API) | `docker.io/netboxcommunity/netbox` | `v4.5-4.0.2` |
| Netbox Worker | `docker.io/netboxcommunity/netbox` | `v4.5-4.0.2` (same image, different entrypoint) |

The worker runs `rqworker` for background task processing (webhooks, reports, scripts).

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | TCP | HTTP web UI and REST/GraphQL API |

Traefik will proxy `netbox.lab.kemo.dev` to port 8080 with TLS via StepCA ACME.

## Environment Variables

### Netbox Application

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `DB_HOST` | PostgreSQL host | `shared-pgsql` (shared instance) |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_NAME` | Database name | `netbox` |
| `DB_USER` | Database user | `netbox` |
| `DB_PASSWORD` | Database password | (generate secure value) |
| `REDIS_HOST` | Valkey/Redis host for task queue | `shared-valkey` (shared instance) |
| `REDIS_PORT` | Valkey/Redis port | `6379` |
| `REDIS_PASSWORD` | Valkey/Redis password | (generate secure value) |
| `REDIS_DATABASE` | Redis DB index for tasks | `0` |
| `REDIS_SSL` | Use TLS for Redis | `false` |
| `REDIS_CACHE_HOST` | Valkey/Redis host for caching | `shared-valkey` (shared instance) |
| `REDIS_CACHE_PORT` | Valkey/Redis port for caching | `6379` |
| `REDIS_CACHE_PASSWORD` | Valkey/Redis cache password | (generate secure value) |
| `REDIS_CACHE_DATABASE` | Redis DB index for cache | `1` |
| `REDIS_CACHE_SSL` | Use TLS for Redis cache | `false` |
| `SECRET_KEY` | Django secret key | (generate long random string) |
| `API_TOKEN_PEPPER_1` | API token hashing pepper | (generate random string) |
| `CORS_ORIGIN_ALLOW_ALL` | Allow all CORS origins | `True` |
| `GRAPHQL_ENABLED` | Enable GraphQL API | `true` |
| `WEBHOOKS_ENABLED` | Enable outgoing webhooks | `true` |
| `METRICS_ENABLED` | Enable Prometheus metrics | `true` |
| `MEDIA_ROOT` | Media file storage path | `/opt/netbox/netbox/media` |
| `SKIP_SUPERUSER` | Skip superuser creation on init | `false` (create on first run) |
| `SUPERUSER_NAME` | Initial admin username | `admin` |
| `SUPERUSER_EMAIL` | Initial admin email | `admin@lab.kemo.dev` |
| `SUPERUSER_PASSWORD` | Initial admin password | (set on first run) |
| `GRANIAN_WORKERS` | Number of ASGI workers | `4` |
| `GRANIAN_BACKPRESSURE` | Worker backpressure limit | `4` |
| `RELEASE_CHECK_URL` | URL to check for new releases | `https://api.github.com/repos/netbox-community/netbox/releases` |

### OIDC/SSO (optional, for Keycloak integration)

| Variable | Description |
|----------|-------------|
| `REMOTE_AUTH_BACKEND` | `social_core.backends.open_id_connect.OpenIdConnectAuth` |
| `SOCIAL_AUTH_OIDC_OIDC_ENDPOINT` | Keycloak OIDC endpoint URL |
| `SOCIAL_AUTH_OIDC_KEY` | OIDC client ID |
| `SOCIAL_AUTH_OIDC_SECRET` | OIDC client secret |
| `SOCIAL_AUTH_OIDC_SCOPE` | `openid profile email roles` |
| `LOGOUT_REDIRECT_URL` | Post-logout redirect URL |

### Email (optional)

| Variable | Description | Default |
|----------|-------------|---------|
| `EMAIL_SERVER` | SMTP server | `localhost` |
| `EMAIL_PORT` | SMTP port | `25` |
| `EMAIL_FROM` | Sender address | `netbox@lab.kemo.dev` |
| `EMAIL_USE_TLS` | Use STARTTLS | `false` |
| `EMAIL_USE_SSL` | Use implicit TLS | `false` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `netbox-media-files` | `/opt/netbox/netbox/media` | Uploaded images and attachments | 1-5 GB |
| `netbox-reports-files` | `/opt/netbox/netbox/reports` | Custom report scripts | <100 MB |
| `netbox-scripts-files` | `/opt/netbox/netbox/scripts` | Custom scripts | <100 MB |

Database storage is handled by the shared PostgreSQL instance.

## Resource Estimates

| Service | CPU | Memory | Notes |
|---------|-----|--------|-------|
| Netbox Web | 1-2 cores | 1-2 GB | Scales with concurrent users |
| Netbox Worker | 0.5-1 core | 512 MB - 1 GB | Background tasks, webhooks |
| **Total** | **1.5-3 cores** | **1.5-3 GB** | |

## Dependencies

### Shared Services

| Service | Purpose | Details |
|---------|---------|---------|
| Shared PostgreSQL | Primary database | Database: `netbox`, User: `netbox`. Requires PostgreSQL 13+. |
| Shared Valkey | Task queue + caching | Uses DB index 0 for tasks, DB index 1 for cache. Requires Redis/Valkey 6+. |
| Traefik | Reverse proxy + TLS | Routes `netbox.lab.kemo.dev` with StepCA ACME certificate |

### Optional Integrations

- **Keycloak** - SSO via OIDC for centralized authentication
- **SMTP/Mailcow** - Email notifications for change alerts

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.42.50` |
| DNS Zone | `lab.kemo.dev` |
| FQDN | `netbox.lab.kemo.dev` |
| Container Network | `lab-network` (macvlan/bridge) |
| Subnet | `192.168.42.0/23` |

### Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.netbox.rule=Host(`netbox.lab.kemo.dev`)"
  - "traefik.http.routers.netbox.entrypoints=websecure"
  - "traefik.http.routers.netbox.tls=true"
  - "traefik.http.routers.netbox.tls.certresolver=stepca"
  - "traefik.http.services.netbox.loadbalancer.server.port=8080"
```

## Special Considerations

1. **User/Group**: The Netbox container runs as `netbox:root` (non-root user). Ensure volume permissions are set accordingly.

2. **Health Check**: The web container uses `curl -f http://localhost:8080/login/` with a 90-second start period to allow for initial database migrations.

3. **Worker Dependency**: The worker container depends on the web container being healthy before starting, since the web container runs migrations on startup.

4. **Secret Key Persistence**: The `SECRET_KEY` must remain the same across container restarts. Changing it will invalidate all existing sessions and tokens.

5. **API Token Pepper**: `API_TOKEN_PEPPER_1` is used for hashing API tokens. Once set and tokens are created, it must not be changed or all API tokens will be invalidated.

6. **Database Migrations**: Migrations run automatically when the web container starts. Ensure the shared PostgreSQL is available and the `netbox` database and user are pre-created.

7. **Shared Database Isolation**: When using shared PostgreSQL, each service gets its own database. Ensure the `netbox` database is created with appropriate ownership before first start.

8. **Valkey DB Index Separation**: Netbox uses DB index 0 for task queues and DB index 1 for caching. Ensure these do not collide with other services sharing the same Valkey instance.

9. **Configuration Files**: Netbox supports additional configuration via Python files mounted to `/etc/netbox/config/`. This can be used for advanced customization beyond environment variables.

10. **Backup Strategy**: Back up the PostgreSQL `netbox` database and the `netbox-media-files` volume. Reports and scripts volumes should be version-controlled separately.
