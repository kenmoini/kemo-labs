# Authentik - Identity Provider

Authentik is a self-hosted identity provider offering LDAP, OIDC/OAuth2, SAML, and SCIM. It serves as the central authentication hub for all homelab services that support SSO, providing user management, group-based access control, and multi-factor authentication.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set AUTHENTIK_SECRET_KEY (openssl rand -hex 50),
#   AUTHENTIK_POSTGRESQL__PASSWORD, database connection details

# Ensure shared PostgreSQL has the 'authentik' database created
# Ensure shared Valkey is running

docker compose up -d

# Complete initial setup at:
# https://auth.lab.kemo.dev/if/flow/initial-setup/
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `AUTHENTIK_SECRET_KEY` | Secret key for signing (generate with `openssl rand -hex 50`) |
| `AUTHENTIK_POSTGRESQL__HOST` | PostgreSQL host (`192.168.42.15`) |
| `AUTHENTIK_POSTGRESQL__PASSWORD` | Database password |
| `AUTHENTIK_REDIS__HOST` | Valkey/Redis host (`192.168.42.15`) |
| `AUTHENTIK_REDIS__DB` | Redis DB index (`4`) |
| `AUTHENTIK_EMAIL__HOST` | SMTP host for email notifications |

## Access

| URL | Purpose |
|-----|---------|
| `https://auth.lab.kemo.dev` | Web UI, admin panel, and auth flows |
| `192.168.42.8:389` | LDAP (if embedded outpost enabled) |
| `192.168.42.8:636` | LDAPS |

**Static IP:** 192.168.42.8

## Dependencies

- **Shared PostgreSQL** -- `authentik` database on 192.168.42.15
- **Shared Valkey** -- DB 4 for caching, sessions, and task queue
- **DNS** -- `auth.lab.kemo.dev`
- **Mailcow** (optional) -- SMTP for email notifications and password resets

## Maintenance

```bash
# View logs
docker compose logs -f server worker

# Update images (pin to version, test before upgrading)
docker compose pull && docker compose up -d

# Back up Authentik
# 1. PostgreSQL 'authentik' database (via Databasus)
# 2. Media volume (uploaded assets)
# 3. AUTHENTIK_SECRET_KEY (losing it invalidates all sessions)
```

The first user to visit the initial setup URL becomes the admin (`akadmin`). Configure OIDC providers for GitLab, Grafana, Vault, Netbox, and other services after initial setup.
