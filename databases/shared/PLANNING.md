# Shared Databases Stack

## Overview

This stack consolidates all shared database engines into a single Docker Compose deployment at a fixed IP address (`192.168.62.15`). Rather than bundling a database container with every application stack, downstream services connect to these shared instances over the Docker bridge or host network. This reduces memory overhead, simplifies backups, and provides a single point of management for all persistent data stores.

The stack includes:

| Service | Purpose |
|---------|---------|
| **MariaDB** | MySQL-compatible relational DB |
| **PostgreSQL** | Advanced relational DB |
| **Valkey** | Redis-compatible in-memory cache/queue |
| **MQTT (Mosquitto)** | Lightweight message broker for IoT/home automation |
| **phpMyAdmin** | Web UI for MariaDB administration |
| **Databasus** | Automated database backup tool |

---

## Docker Images

| Service | Image | Tag | Notes |
|---------|-------|-----|-------|
| MariaDB | `docker.io/library/mariadb` | `11.7` | Latest stable LTS line |
| PostgreSQL | `docker.io/library/postgres` | `17` | Latest stable major |
| Valkey | `docker.io/valkey/valkey` | `8` | Latest stable, Redis 7+ compatible |
| Mosquitto | `docker.io/library/eclipse-mosquitto` | `2` | v2.x with auth-by-default |
| phpMyAdmin | `docker.io/phpmyadmin/phpmyadmin` | `latest` | Tracks stable releases |
| Databasus | `ghcr.io/databasus/databasus` | `latest` | Ken's own project |

---

## Port Mapping

All services bind to the static IP `192.168.62.15` to avoid port conflicts with other stacks.

| Service | Container Port | Host Binding | Protocol |
|---------|---------------|--------------|----------|
| MariaDB | 3306 | `192.168.62.15:3306` | TCP |
| PostgreSQL | 5432 | `192.168.62.15:5432` | TCP |
| Valkey | 6379 | `192.168.62.15:6379` | TCP |
| Mosquitto (MQTT) | 1883 | `192.168.62.15:1883` | TCP |
| Mosquitto (WebSocket) | 9001 | `192.168.62.15:9001` | TCP |
| phpMyAdmin | 80 | `192.168.62.15:8080` | TCP (fronted by Traefik) |
| Databasus | 8000 | `192.168.62.15:8000` | TCP (web UI, optional) |

Traefik will reverse-proxy phpMyAdmin at `https://phpmyadmin.lab.kemo.network` with StepCA ACME TLS.

---

## Environment Variables

### MariaDB

```env
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
MARIADB_DATABASE=default_db
MARIADB_USER=${MARIADB_USER}
MARIADB_PASSWORD=${MARIADB_PASSWORD}
```

The `MARIADB_DATABASE` / `MARIADB_USER` / `MARIADB_PASSWORD` variables only create one initial database and user on first run. Additional databases are created via init scripts (see Database Initialization below).

### PostgreSQL

```env
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=postgres
```

Like MariaDB, additional databases and roles are created through init scripts.

### Valkey

```env
# No mandatory env vars. Configuration via command flags or valkey.conf.
# To set a password:
#   command: ["valkey-server", "--requirepass", "${VALKEY_PASSWORD}"]
```

Valkey exposes `--requirepass`, `--maxmemory`, and `--appendonly` as key command-line flags.

### Mosquitto

Mosquitto v2 requires explicit authentication. Configuration is file-based, not env-var-based:

```
# mosquitto.conf
listener 1883
listener 9001
protocol websockets
allow_anonymous false
password_file /mosquitto/config/passwd
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
```

A password file is generated with `mosquitto_passwd`.

### phpMyAdmin

```env
PMA_HOST=mariadb
PMA_PORT=3306
PMA_ARBITRARY=0
UPLOAD_LIMIT=256M
```

Set `PMA_HOST` to the MariaDB service name within the compose network.

### Databasus

```env
DATABASUS_CRON_SCHEDULE=0 2 * * *
DATABASUS_RETENTION_DAYS=30
DATABASUS_BACKUP_DIR=/backups

# MariaDB target
DATABASUS_MARIADB_HOST=mariadb
DATABASUS_MARIADB_PORT=3306
DATABASUS_MARIADB_USER=root
DATABASUS_MARIADB_PASSWORD=${MARIADB_ROOT_PASSWORD}

# PostgreSQL target
DATABASUS_PGSQL_HOST=postgresql
DATABASUS_PGSQL_PORT=5432
DATABASUS_PGSQL_USER=${POSTGRES_USER:-postgres}
DATABASUS_PGSQL_PASSWORD=${POSTGRES_PASSWORD}
```

---

## Storage / Volumes

Each engine gets its own named volume to isolate data and simplify independent restores.

| Volume Name | Mount Path (container) | Purpose |
|-------------|----------------------|---------|
| `mariadb_data` | `/var/lib/mysql` | MariaDB data files |
| `mariadb_init` | `/docker-entrypoint-initdb.d` | MariaDB init scripts (bind mount) |
| `postgresql_data` | `/var/lib/postgresql/data` | PostgreSQL data files |
| `postgresql_init` | `/docker-entrypoint-initdb.d` | PostgreSQL init scripts (bind mount) |
| `valkey_data` | `/data` | Valkey AOF/RDB persistence |
| `mosquitto_config` | `/mosquitto/config` | Mosquitto config + passwd (bind mount) |
| `mosquitto_data` | `/mosquitto/data` | Mosquitto persistent sessions |
| `mosquitto_log` | `/mosquitto/log` | Mosquitto log files |
| `databasus_backups` | `/backups` | Backup output directory |

Bind mounts for init scripts and Mosquitto config should point to paths within this stack directory:

```
./init/mariadb/     -> /docker-entrypoint-initdb.d  (MariaDB)
./init/postgresql/  -> /docker-entrypoint-initdb.d  (PostgreSQL)
./config/mosquitto/ -> /mosquitto/config             (Mosquitto)
```

### Disk Space Estimates

| Volume | Estimated Size | Notes |
|--------|---------------|-------|
| `mariadb_data` | 5-20 GB | Depends on GitLab, Mailcow usage |
| `postgresql_data` | 5-30 GB | Authentik, Netbox, Paperless, n8n, Postiz, etc. |
| `valkey_data` | 500 MB - 2 GB | Mostly ephemeral cache/session data |
| `mosquitto_data` | < 100 MB | Retained messages only |
| `databasus_backups` | 20-60 GB | 30-day retention of compressed dumps |

---

## Resource Estimates

| Service | Memory (idle) | Memory (active) | CPU | Notes |
|---------|--------------|-----------------|-----|-------|
| MariaDB | 200-400 MB | 1-4 GB | 1-2 cores | Tune `innodb_buffer_pool_size` |
| PostgreSQL | 200-500 MB | 1-4 GB | 1-2 cores | Tune `shared_buffers`, `work_mem` |
| Valkey | 50-100 MB | 200 MB - 1 GB | 0.5 core | Memory bound by dataset size |
| Mosquitto | 10-20 MB | 30-50 MB | minimal | Very lightweight |
| phpMyAdmin | 50-100 MB | 100-200 MB | minimal | PHP-FPM based, only active during use |
| Databasus | 20-50 MB | 200-500 MB | 0.5 core | Spikes during backup runs |
| **Total (idle)** | **~600 MB** | | | |
| **Total (peak)** | | **~6-10 GB** | **~5-6 cores** | During concurrent load + backup |

On a 128 GB / 32-core host this is well within budget.

---

## Downstream Service Dependencies

### MariaDB Databases

| Database Name | Service | Stack Location |
|---------------|---------|----------------|
| `gitlab` | GitLab | `development/gitlab/` |
| `mailcow` | Mailcow | `communication/mailcow/` |

### PostgreSQL Databases

| Database Name | Service | Stack Location |
|---------------|---------|----------------|
| `authentik` | Authentik | `security/authentik/` (assumed) |
| `netbox` | Netbox | `infrastructure/netbox/` (assumed) |
| `paperless` | Paperless-ngx | `documentation/paperless/` (assumed) |
| `n8n` | n8n | `ai/n8n/` |
| `postiz` | Postiz | `ai/postiz/` |
| `shlink` | Shlink | `communication/shlink/` |
| `affine` | AFFiNE | (if deployed) |

### Valkey (Redis-compatible)

| Usage | Service | Notes |
|-------|---------|-------|
| Cache/session | Authentik | Session backend + cache |
| Cache/queue | GitLab | Sidekiq job queue, Rails cache |
| Cache | Postiz | Queue/cache backend |
| Cache | n8n | Optional execution cache |

### MQTT (Mosquitto)

| Usage | Service | Notes |
|-------|---------|-------|
| IoT messaging | Home Assistant | `automation/home-assistant/` |
| Device events | Scrypted | `automation/scrypted/` |

---

## Network Configuration

### Compose Network

The stack defines a single bridge network. Other stacks connect to these databases by IP (`192.168.62.15`) and port rather than by joining this compose network. This keeps stacks decoupled.

```yaml
networks:
  databases:
    driver: bridge
```

Internal service names (`mariadb`, `postgresql`, `valkey`, `mosquitto`) resolve within this compose network. phpMyAdmin and Databasus use these internal names to reach the database engines without going through the host IP.

### DNS Records

| Record | Value |
|--------|-------|
| `db.lab.kemo.network` | `192.168.62.15` |
| `mariadb.lab.kemo.network` | CNAME to `db.lab.kemo.network` |
| `postgresql.lab.kemo.network` | CNAME to `db.lab.kemo.network` |
| `valkey.lab.kemo.network` | CNAME to `db.lab.kemo.network` |
| `mqtt.lab.kemo.network` | CNAME to `db.lab.kemo.network` |
| `phpmyadmin.lab.kemo.network` | CNAME to `db.lab.kemo.network` (Traefik) |

Downstream services should connect using the CNAME hostnames so that if individual databases are ever split out to separate hosts, only DNS needs to change.

### Firewall

Ports 3306, 5432, 6379, 1883, 9001 must be open on the host for `192.168.62.0/23` traffic. The phpMyAdmin web UI (8080) should only be exposed through Traefik.

---

## Database Initialization Strategy

Both MariaDB and PostgreSQL support automatic execution of scripts placed in `/docker-entrypoint-initdb.d/` on **first run only** (when the data volume is empty).

### MariaDB Init Scripts

Place `.sql` or `.sh` files in `./init/mariadb/`:

```sql
-- init/mariadb/01-create-databases.sql
CREATE DATABASE IF NOT EXISTS gitlab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS mailcow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'gitlab'@'%' IDENTIFIED BY '${MARIADB_GITLAB_PASSWORD}';
GRANT ALL PRIVILEGES ON gitlab.* TO 'gitlab'@'%';

CREATE USER IF NOT EXISTS 'mailcow'@'%' IDENTIFIED BY '${MARIADB_MAILCOW_PASSWORD}';
GRANT ALL PRIVILEGES ON mailcow.* TO 'mailcow'@'%';

FLUSH PRIVILEGES;
```

Note: `.sql` files do not support env var substitution natively. Use a `.sh` wrapper with `mysql` client commands to inject variables:

```bash
#\!/bin/bash
# init/mariadb/01-create-databases.sh
mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS gitlab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'gitlab'@'%' IDENTIFIED BY '${MARIADB_GITLAB_PASSWORD}';
    GRANT ALL PRIVILEGES ON gitlab.* TO 'gitlab'@'%';
    FLUSH PRIVILEGES;
EOSQL
```

### PostgreSQL Init Scripts

Place `.sql` or `.sh` files in `./init/postgresql/`:

```bash
#\!/bin/bash
# init/postgresql/01-create-databases.sh
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE authentik;
    CREATE USER authentik WITH PASSWORD '${PG_AUTHENTIK_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik;

    CREATE DATABASE netbox;
    CREATE USER netbox WITH PASSWORD '${PG_NETBOX_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;

    CREATE DATABASE paperless;
    CREATE USER paperless WITH PASSWORD '${PG_PAPERLESS_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE paperless TO paperless;

    CREATE DATABASE n8n;
    CREATE USER n8n WITH PASSWORD '${PG_N8N_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;

    CREATE DATABASE postiz;
    CREATE USER postiz WITH PASSWORD '${PG_POSTIZ_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;

    CREATE DATABASE shlink;
    CREATE USER shlink WITH PASSWORD '${PG_SHLINK_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE shlink TO shlink;
EOSQL
```

### Adding Databases Later

Init scripts only run on first boot. To add databases after initial deployment:

```bash
# MariaDB
docker exec -i shared-mariadb-1 mysql -u root -p"${MARIADB_ROOT_PASSWORD}" < new-db.sql

# PostgreSQL
docker exec -i shared-postgresql-1 psql -U postgres < new-db.sql
```

Update the init scripts as well so that a future clean deployment picks up all databases.

---

## Backup Considerations (Databasus)

Databasus runs as a sidecar container in this compose stack, connecting to both MariaDB and PostgreSQL over the internal compose network.

### Configuration

- **Schedule**: `0 2 * * *` (daily at 2:00 AM) via cron expression
- **Retention**: 30 days of rolling backups
- **Output**: Compressed SQL dumps written to the `databasus_backups` volume
- **Targets**: All databases in both MariaDB and PostgreSQL

### Backup Volume

The `databasus_backups` volume should be either:
1. A named Docker volume (simple, but harder to access from outside Docker)
2. A bind mount to a host path like `/srv/backups/databases/` (preferred -- easier to integrate with off-host backup tools like Kopia or rsync)

### Restore Workflow

```bash
# MariaDB
docker exec -i shared-mariadb-1 mysql -u root -p"${MARIADB_ROOT_PASSWORD}" database_name < /path/to/backup.sql

# PostgreSQL
docker exec -i shared-postgresql-1 psql -U postgres database_name < /path/to/backup.sql
```

### Off-host Backup Integration

The backup bind mount at `/srv/backups/databases/` can be picked up by a host-level backup tool (Kopia, restic, etc.) for off-site replication. Databasus handles the hot-dump; the host backup tool handles off-site copies.

---

## .env File Template

The stack should use a `.env` file for all secrets. Template:

```env
# MariaDB
MARIADB_ROOT_PASSWORD=changeme
MARIADB_USER=mariadb_admin
MARIADB_PASSWORD=changeme
MARIADB_GITLAB_PASSWORD=changeme
MARIADB_MAILCOW_PASSWORD=changeme

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=changeme
PG_AUTHENTIK_PASSWORD=changeme
PG_NETBOX_PASSWORD=changeme
PG_PAPERLESS_PASSWORD=changeme
PG_N8N_PASSWORD=changeme
PG_POSTIZ_PASSWORD=changeme
PG_SHLINK_PASSWORD=changeme

# Valkey
VALKEY_PASSWORD=changeme

# MQTT
MQTT_USER=homeassistant
MQTT_PASSWORD=changeme

# Databasus
DATABASUS_CRON_SCHEDULE=0 2 * * *
DATABASUS_RETENTION_DAYS=30
```

---

## Startup Order

Use `depends_on` with health checks so that Databasus and phpMyAdmin only start after their target databases are healthy:

1. **MariaDB** and **PostgreSQL** and **Valkey** and **Mosquitto** -- start in parallel, no dependencies
2. **phpMyAdmin** -- depends on MariaDB being healthy
3. **Databasus** -- depends on both MariaDB and PostgreSQL being healthy

Health checks:

- MariaDB: `healthcheck: { test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"], interval: 10s, retries: 5 }`
- PostgreSQL: `healthcheck: { test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"], interval: 10s, retries: 5 }`
- Valkey: `healthcheck: { test: ["CMD", "valkey-cli", "ping"], interval: 10s, retries: 5 }`

---

## Traefik Labels (phpMyAdmin)

phpMyAdmin will be fronted by Traefik for HTTPS via StepCA ACME:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.phpmyadmin.rule=Host(`phpmyadmin.lab.kemo.network`)"
  - "traefik.http.routers.phpmyadmin.entrypoints=websecure"
  - "traefik.http.routers.phpmyadmin.tls.certresolver=stepca"
  - "traefik.http.services.phpmyadmin.loadbalancer.server.port=80"
```

---

## Open Questions

- Should Valkey require a password? If downstream services (Authentik, GitLab) all live on the same trusted network, passwordless may be acceptable -- but password-protected is safer.
- Should Mosquitto use TLS on port 8883, or is plaintext on the private LAN sufficient?
- Does Mailcow bundle its own MariaDB, or should it use the shared instance? (Mailcow's default compose ships its own -- may need to override.)
- Should pgAdmin be added alongside phpMyAdmin for PostgreSQL web management?
