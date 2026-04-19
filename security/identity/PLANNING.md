# Authentik - Identity Provider (LDAP & OIDC)

## Overview

Authentik is a self-hosted identity provider offering LDAP, OIDC/OAuth2, SAML, and SCIM. It serves as the central authentication and authorization hub for all homelab services that support SSO. Provides user management, group-based access control, multi-factor authentication, and social login.

## Container Images

| Container | Image | Purpose |
|-----------|-------|---------|
| Server | `ghcr.io/goauthentik/server:2025.2.4` | Web UI, API, and auth flows |
| Worker | `ghcr.io/goauthentik/server:2025.2.4` | Background tasks (same image, different command) |

**Tag policy:** Pin to release version (YYYY.M.patch format)

## Static IP & DNS

- **IP:** 192.168.42.8
- **DNS:** `auth.lab.kemo.dev`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | TCP/HTTP | Web UI and API |
| 9443 | TCP/HTTPS | Web UI and API (TLS) |
| 389 | TCP | LDAP (if LDAP outpost is embedded) |
| 636 | TCP | LDAPS |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AUTHENTIK_SECRET_KEY` | Secret key for signing (generate with `openssl rand -hex 50`) | (secret) |
| `AUTHENTIK_POSTGRESQL__HOST` | PostgreSQL host | `192.168.42.15` |
| `AUTHENTIK_POSTGRESQL__PORT` | PostgreSQL port | `5432` |
| `AUTHENTIK_POSTGRESQL__NAME` | Database name | `authentik` |
| `AUTHENTIK_POSTGRESQL__USER` | Database user | `authentik` |
| `AUTHENTIK_POSTGRESQL__PASSWORD` | Database password | (secret) |
| `AUTHENTIK_REDIS__HOST` | Valkey/Redis host | `192.168.42.15` |
| `AUTHENTIK_REDIS__PORT` | Redis port | `6379` |
| `AUTHENTIK_REDIS__DB` | Redis database number | `4` |
| `AUTHENTIK_ERROR_REPORTING__ENABLED` | Disable telemetry | `false` |
| `AUTHENTIK_LOG_LEVEL` | Log level | `info` |
| `AUTHENTIK_EMAIL__HOST` | SMTP host (Mailcow) | `192.168.42.80` |
| `AUTHENTIK_EMAIL__PORT` | SMTP port | `587` |
| `AUTHENTIK_EMAIL__FROM` | Sender address | `auth@lab.kemo.dev` |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./media:/media` | User-uploaded media, icons | 1-5 GB |
| `./templates:/templates` | Custom email/flow templates | < 10 MB |

## Resource Estimates

| Container | CPU (idle) | CPU (peak) | RAM (idle) | RAM (peak) |
|-----------|-----------|-----------|-----------|-----------|
| Server | 0.5 cores | 2 cores | 512 MB | 1.5 GB |
| Worker | 0.2 cores | 1 core | 256 MB | 1 GB |
| **Total** | **0.7 cores** | **3 cores** | **768 MB** | **2.5 GB** |

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| Shared PostgreSQL | **Required** | `authentik` database on 192.168.42.15 |
| Shared Valkey | **Required** | DB 4 for caching, sessions, task queue |
| DNS | Recommended | `auth.lab.kemo.dev` |
| Mailcow (SMTP) | Optional | For email notifications, password resets |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.42.8
- Server container exposes 9000 (HTTP) and 9443 (HTTPS)
- LDAP ports 389/636 exposed directly for LDAP clients
- Worker container needs no port exposure (connects to PostgreSQL and Valkey)

## Special Considerations

### Initial Setup
1. First boot: navigate to `https://auth.lab.kemo.dev/if/flow/initial-setup/`
2. Create the initial admin (akadmin) account
3. Configure tenants, flows, and providers

### Services to Integrate via OIDC
- Grafana
- GitLab
- Vault
- Netbox
- Paperless NGX
- n8n
- Open WebUI
- Homepage
- Portainer (if added)

### LDAP Outpost
Authentik can run an embedded LDAP outpost for services that only support LDAP:
- Deploy via the Authentik admin UI as an "Embedded Outpost"
- Binds to ports 389/636 on the Authentik container
- Useful for legacy services or SSH PAM integration

### Valkey DB Index Allocation
Using DB 4 for Authentik (DB 0-3 reserved for Netbox, Affine, Paperless per docs agent allocation).

### PostgreSQL Database Init
The shared databases init script must create:
```sql
CREATE USER authentik WITH PASSWORD '${AUTHENTIK_DB_PASSWORD}';
CREATE DATABASE authentik OWNER authentik;
```

### Backup Considerations
- PostgreSQL database (via Databasus)
- `/media` volume for uploaded assets
- Secret key (`AUTHENTIK_SECRET_KEY`) — losing it invalidates all sessions and tokens

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.authentik.rule=Host(`auth.lab.kemo.dev`)"
  - "traefik.http.routers.authentik.tls=true"
  - "traefik.http.routers.authentik.tls.certresolver=stepca"
  - "traefik.http.services.authentik.loadbalancer.server.port=9000"
```

### Forward Auth Middleware
Authentik can protect services that don't natively support SSO via Traefik forward auth:
```yaml
# On Traefik
- "traefik.http.middlewares.authentik.forwardauth.address=http://192.168.42.8:9000/outpost.goauthentik.io/auth/traefik"
- "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
- "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"
```
