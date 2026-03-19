# Netbox - Network Documentation and IPAM

Netbox is a comprehensive network documentation and IP Address Management (IPAM) tool. It provides a centralized source of truth for IP addresses, VLANs, racks, devices, cables, and circuits. Runs with a web server, background worker, and housekeeping container.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set DB_PASSWORD, SECRET_KEY, SUPERUSER_PASSWORD, REDIS_PASSWORD

# Ensure shared PostgreSQL has 'netbox' database created
# Ensure shared Valkey is running

docker compose up -d
# First boot runs database migrations (allow 1-2 minutes)
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DB_PASSWORD` | PostgreSQL password |
| `SECRET_KEY` | Django secret key (must remain constant) |
| `SUPERUSER_NAME` | Initial admin username (default: `admin`) |
| `SUPERUSER_PASSWORD` | Initial admin password |
| `REDIS_PASSWORD` | Valkey/Redis password |
| `REDIS_DATABASE` | Task queue DB index (default: `0`) |
| `REDIS_CACHE_DATABASE` | Cache DB index (default: `1`) |

## Access

| URL | Purpose |
|-----|---------|
| `https://netbox.lab.kemo.network` | Web UI and REST/GraphQL API |

**Static IP:** 192.168.62.50

## Dependencies

- **Shared PostgreSQL** -- `netbox` database (PostgreSQL 13+)
- **Shared Valkey** -- DB 0 for tasks, DB 1 for cache
- **Traefik** -- reverse proxy with TLS

## Maintenance

```bash
# View logs
docker compose logs -f netbox netbox-worker

# Update image (pin to specific version)
docker compose pull && docker compose up -d

# Back up data:
# 1. PostgreSQL 'netbox' database (via Databasus)
# 2. netbox-media-files volume (uploaded attachments)

# REST API available at /api/ with token authentication
# GraphQL API available at /graphql/
```

The `SECRET_KEY` and `API_TOKEN_PEPPER_1` must never change after initial deployment -- doing so invalidates all sessions and API tokens respectively.
