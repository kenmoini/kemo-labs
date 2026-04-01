# Shared Databases Stack

Consolidates all shared database engines into a single deployment: MariaDB, PostgreSQL (with pgvector), Valkey (Redis-compatible), Mosquitto (MQTT), phpMyAdmin, and Databasus (automated backups). Downstream services connect by IP rather than joining this compose network.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set all database passwords (MARIADB_ROOT_PASSWORD,
#   POSTGRES_PASSWORD, VALKEY_PASSWORD, per-service passwords)

# Ensure init scripts exist in ./init-scripts/

docker compose up -d
```

## Configuration

Key environment variables (see `.env.example` for full list):

| Variable | Purpose |
|----------|---------|
| `MARIADB_ROOT_PASSWORD` | MariaDB root password |
| `POSTGRES_PASSWORD` | PostgreSQL superuser password |
| `VALKEY_PASSWORD` | Valkey authentication password |
| `PG_*_PASSWORD` | Per-service PostgreSQL passwords (authentik, netbox, paperless, n8n, etc.) |
| `DATABASUS_CRON_SCHEDULE` | Backup schedule (default: `0 2 * * *`) |

Init scripts in `./init-scripts/` run on first boot to create databases and users for downstream services.

## Access

| Address | Purpose |
|---------|---------|
| `192.168.62.15:3306` | MariaDB |
| `192.168.62.16:5432` | PostgreSQL |
| `192.168.62.17:6379` | Valkey (Redis-compatible) |
| `192.168.62.18:1883` | Mosquitto MQTT |
| `https://phpmyadmin.lab.kemo.dev` | phpMyAdmin web UI |

## Dependencies

- **DNS** -- for hostname resolution and Traefik routing
- **Traefik** -- reverse proxy for phpMyAdmin

This is a foundational service. Most application workloads depend on it.

## Maintenance

```bash
# View logs
docker compose logs -f mariadb postgresql

# Connect to MariaDB
docker exec -it shared-mariadb mysql -u root -p

# Connect to PostgreSQL
docker exec -it shared-postgresql psql -U postgres

# Add a new database after initial deployment
docker exec -i shared-postgresql psql -U postgres < new-db.sql

# Databasus runs automated backups to /srv/backups/databases/
# Restore a backup:
docker exec -i shared-mariadb mysql -u root -p"$PASS" dbname < backup.sql
docker exec -i shared-postgresql psql -U postgres dbname < backup.sql

# Update images
docker compose pull && docker compose up -d
```
