# Semaphore UI - Ansible Automation Platform

Semaphore UI is a modern, open-source alternative to Ansible AWX/Tower providing a web interface for running Ansible playbooks, managing inventories, and scheduling automation tasks against homelab infrastructure.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set DB_PASSWORD, SEMAPHORE_ADMIN_PASSWORD, SEMAPHORE_ACCESS_KEY_ENCRYPTION

# Generate a strong access key encryption value
openssl rand -hex 32

# Ensure the shared PostgreSQL has a semaphore database (see Dependencies below)

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DB_USERNAME` / `DB_PASSWORD` / `DB_DATABASE` | PostgreSQL credentials for shared instance |
| `SEMAPHORE_ADMIN` / `SEMAPHORE_ADMIN_PASSWORD` | Admin account created on first run |
| `SEMAPHORE_ADMIN_EMAIL` | Admin email address |
| `SEMAPHORE_ACCESS_KEY_ENCRYPTION` | Encryption key for stored credentials in the database |
| `SEMAPHORE_LDAP_ACTIVATED` | Enable LDAP authentication (`yes` / `no`) |

SSH keys from the host `~/.ssh/` directory are mounted read-only into the container so Semaphore can connect to managed hosts without copying keys.

## Access

| URL | Purpose |
|-----|---------|
| `https://semaphore.lab.kemo.network` | Semaphore web UI |

**Static IP:** 192.168.62.25

## Dependencies

- **Shared PostgreSQL** (192.168.62.16) -- the `semaphore` database and user must exist before first launch
- **DNS** -- hostname resolution for `semaphore.lab.kemo.network`
- **Traefik** -- reverse proxy with TLS via StepCA ACME

### PostgreSQL Setup

The shared PostgreSQL init script at `databases/shared/init-scripts/postgres-init.sh` must include a `semaphore` database and user. Add the following block to the init script:

```sql
-- Semaphore
CREATE DATABASE semaphore;
CREATE USER semaphore WITH PASSWORD '${PG_SEMAPHORE_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE semaphore TO semaphore;
ALTER DATABASE semaphore OWNER TO semaphore;
```

Also add `PG_SEMAPHORE_PASSWORD` to the shared PostgreSQL `.env` file. If the database already exists from a prior deployment, this step can be skipped.

## Maintenance

```bash
# View logs
docker compose logs -f semaphore

# Update image
docker compose pull && docker compose up -d

# Restart after config changes
docker compose restart semaphore

# Back up Semaphore state (database contains all project/inventory/template config)
# The PostgreSQL database is the primary data store -- back it up via pg_dump
```

## Notes

- The `SEMAPHORE_ACCESS_KEY_ENCRYPTION` value must not change after initial setup, or stored credentials (SSH keys, vault passwords) become unreadable.
- Semaphore clones playbook repositories from Git at task run time. Ensure the container has network access to your Git server.
- Admin credentials are only used on first run to seed the initial user. Changing them in `.env` later has no effect -- use the web UI instead.
