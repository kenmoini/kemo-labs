# Paperless-NGX - Document Management System

Paperless-NGX transforms physical documents into a searchable online archive. It performs OCR on uploaded documents, indexes their content, and provides a web interface for organizing, tagging, and searching. Includes Tika and Gotenberg for Office document support.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set PAPERLESS_SECRET_KEY, PAPERLESS_ADMIN_PASSWORD,
#   PAPERLESS_DBPASS, REDIS_PASSWORD

# Ensure shared PostgreSQL has 'paperless' database created
# Ensure shared Valkey is running

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `PAPERLESS_SECRET_KEY` | Django secret key (must remain constant) |
| `PAPERLESS_ADMIN_USER` | Initial admin username (default: `admin`) |
| `PAPERLESS_ADMIN_PASSWORD` | Initial admin password |
| `PAPERLESS_DBPASS` | PostgreSQL password |
| `PAPERLESS_REDIS` | Full Redis URL with DB index (e.g., `redis://:pass@192.168.42.15:6379/3`) |
| `PAPERLESS_OCR_LANGUAGE` | Primary OCR language (default: `eng`) |
| `USERMAP_UID` / `USERMAP_GID` | File ownership UID/GID (default: `1000`) |

## Access

| URL | Purpose |
|-----|---------|
| `https://paperless.lab.kemo.dev` | Web UI and REST API |

**Static IP:** 192.168.42.53

## Dependencies

- **Shared PostgreSQL** -- `paperless` database (PostgreSQL 13+)
- **Shared Valkey** -- DB 3 for Celery task queue
- **Traefik** -- reverse proxy with TLS
- **Tika + Gotenberg** -- co-deployed for Office document support

## Maintenance

```bash
# View logs
docker compose logs -f paperless-ngx

# Update images
docker compose pull && docker compose up -d

# Export documents for backup
docker exec paperless-ngx document_exporter /usr/src/paperless/export/

# Back up data:
# 1. PostgreSQL 'paperless' database
# 2. paperless-media volume (originals + archive versions)
# 3. paperless-data volume (search index)

# Create API token for Paperless-AI: Settings > API Tokens in admin panel
```

OCR processing is CPU-intensive during document ingestion. The consume directory (`paperless-consume`) can be exposed via SMB/NFS for network scanning. Media volume stores both original and OCR-processed versions, roughly doubling storage per document.
