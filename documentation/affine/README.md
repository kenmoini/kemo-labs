# AFFiNE - Knowledge Base and Wiki

AFFiNE is an open-source knowledge base that combines docs, whiteboards, and database-like tables in a single workspace. It supports real-time collaboration, markdown editing, and a block-based editor similar to Notion.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set DB_PASSWORD, REDIS_PASSWORD

# Ensure shared PostgreSQL has 'affine' database with pgvector extension
# Ensure shared Valkey is running

docker compose up -d
# Migration container runs first, then the main server starts
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DB_PASSWORD` | PostgreSQL password for the affine user |
| `DATABASE_URL` | Full PostgreSQL connection string |
| `REDIS_SERVER_HOST` | Valkey host (`192.168.42.15`) |
| `REDIS_SERVER_DATABASE` | Valkey DB index (`2`) |
| `AFFINE_SERVER_EXTERNAL_URL` | Public URL (`https://affine.lab.kemo.dev`) |

## Access

| URL | Purpose |
|-----|---------|
| `https://affine.lab.kemo.dev` | AFFiNE workspace |

**Static IP:** 192.168.42.51

## Dependencies

- **Shared PostgreSQL** -- `affine` database with **pgvector extension** (hard requirement)
- **Shared Valkey** -- DB 2 for caching and pub/sub
- **Traefik** -- reverse proxy with WebSocket support for real-time collaboration

## Maintenance

```bash
# View logs
docker compose logs -f affine

# Update image
docker compose pull && docker compose up -d
# Migration container runs automatically on update

# Back up data:
# 1. PostgreSQL 'affine' database
# 2. affine-storage volume (uploaded files)

# Verify pgvector extension:
# docker exec shared-postgresql psql -U postgres -d affine -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

The migration container must complete successfully before the main server starts. Do not change database credentials or `AFFINE_SERVER_EXTERNAL_URL` after initial data has been written.
