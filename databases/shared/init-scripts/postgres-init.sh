#\!/bin/bash
set -e

# =============================================================================
# PostgreSQL Init Script
# =============================================================================
# Creates databases and users for all downstream services.
# Runs only on first boot (when the data volume is empty).
#
# Image: pgvector/pgvector:pg17 (provides vector, pg_trgm, btree_gist)
# =============================================================================

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    -- =========================================================================
    -- Authentik
    -- =========================================================================
    CREATE DATABASE authentik;
    CREATE USER authentik WITH PASSWORD '${PG_AUTHENTIK_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik;
    ALTER DATABASE authentik OWNER TO authentik;

    -- =========================================================================
    -- GitLab (requires pg_trgm and btree_gist)
    -- =========================================================================
    CREATE DATABASE gitlab;
    CREATE USER gitlab WITH PASSWORD '${PG_GITLAB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;
    ALTER DATABASE gitlab OWNER TO gitlab;

    -- =========================================================================
    -- Netbox
    -- =========================================================================
    CREATE DATABASE netbox;
    CREATE USER netbox WITH PASSWORD '${PG_NETBOX_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
    ALTER DATABASE netbox OWNER TO netbox;

    -- =========================================================================
    -- Paperless-ngx
    -- =========================================================================
    CREATE DATABASE paperless;
    CREATE USER paperless WITH PASSWORD '${PG_PAPERLESS_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE paperless TO paperless;
    ALTER DATABASE paperless OWNER TO paperless;

    -- =========================================================================
    -- n8n
    -- =========================================================================
    CREATE DATABASE n8n;
    CREATE USER n8n WITH PASSWORD '${PG_N8N_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
    ALTER DATABASE n8n OWNER TO n8n;

    -- =========================================================================
    -- Postiz
    -- =========================================================================
    CREATE DATABASE postiz;
    CREATE USER postiz WITH PASSWORD '${PG_POSTIZ_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;
    ALTER DATABASE postiz OWNER TO postiz;

    -- =========================================================================
    -- Shlink
    -- =========================================================================
    CREATE DATABASE shlink;
    CREATE USER shlink WITH PASSWORD '${PG_SHLINK_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE shlink TO shlink;
    ALTER DATABASE shlink OWNER TO shlink;

    -- =========================================================================
    -- AFFiNE (requires pgvector)
    -- =========================================================================
    CREATE DATABASE affine;
    CREATE USER affine WITH PASSWORD '${PG_AFFINE_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE affine TO affine;
    ALTER DATABASE affine OWNER TO affine;

    -- =========================================================================
    -- Semaphore (Ansible UI)
    -- =========================================================================
    CREATE DATABASE semaphore;
    CREATE USER semaphore WITH PASSWORD '${PG_SEMAPHORE_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE semaphore TO semaphore;
    ALTER DATABASE semaphore OWNER TO semaphore;

EOSQL

# =============================================================================
# Enable extensions per database
# Extensions must be created while connected to the target database.
# =============================================================================

# GitLab: pg_trgm and btree_gist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "gitlab" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE EXTENSION IF NOT EXISTS btree_gist;
EOSQL

# AFFiNE: pgvector
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "affine" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS vector;
EOSQL

# Netbox: pg_trgm (used for search)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "netbox" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL

echo "=== PostgreSQL init complete: all databases, users, and extensions created ==="
