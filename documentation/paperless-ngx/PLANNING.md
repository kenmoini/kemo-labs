# Paperless-NGX - Document Management System

## Overview

Paperless-NGX is a document management system that transforms physical documents into a searchable online archive. It performs OCR on uploaded documents, indexes their content, and provides a web interface for organizing, tagging, and searching documents. In this homelab, Paperless-NGX serves as the primary document management and archival system.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| Paperless-NGX | `ghcr.io/paperless-ngx/paperless-ngx` | `latest` |

Single container runs the web server, consumer (file watcher), task queue worker, and scheduler.

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8000 | TCP | HTTP web UI and REST API |

Traefik will proxy `paperless.lab.kemo.dev` to port 8000 with TLS via StepCA ACME.

## Environment Variables

### Core Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `PAPERLESS_URL` | Public-facing URL | `https://paperless.lab.kemo.dev` |
| `PAPERLESS_SECRET_KEY` | Django secret key | (generate long random string) |
| `PAPERLESS_TIME_ZONE` | Container timezone | `America/New_York` |
| `PAPERLESS_ADMIN_USER` | Initial superuser name | `admin` |
| `PAPERLESS_ADMIN_PASSWORD` | Initial superuser password | (set on first run) |
| `PAPERLESS_ADMIN_MAIL` | Initial superuser email | `admin@lab.kemo.dev` |

### Database Configuration (Shared PostgreSQL)

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `PAPERLESS_DBHOST` | PostgreSQL host | `shared-pgsql` |
| `PAPERLESS_DBPORT` | PostgreSQL port | `5432` |
| `PAPERLESS_DBNAME` | Database name | `paperless` |
| `PAPERLESS_DBUSER` | Database user | `paperless` |
| `PAPERLESS_DBPASS` | Database password | (generate secure value) |
| `PAPERLESS_DBENGINE` | Database engine | `postgresql` |

### Redis/Valkey Configuration (Shared Valkey)

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `PAPERLESS_REDIS` | Full Redis connection URL | `redis://:password@shared-valkey:6379/3` |

Use DB index 3 (or another unused index) to avoid collision with Netbox (0, 1) and AFFiNE (2).

### OCR Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PAPERLESS_OCR_LANGUAGE` | Primary OCR language | `eng` |
| `PAPERLESS_OCR_LANGUAGES` | Additional OCR language packs | `deu fra spa` |
| `PAPERLESS_OCR_MODE` | OCR behavior | `skip` (skip if text layer exists) |
| `PAPERLESS_OCR_CLEAN` | Clean up OCR input | `clean` |
| `PAPERLESS_OCR_DESKEW` | Deskew pages before OCR | `true` |
| `PAPERLESS_OCR_ROTATE_PAGES` | Auto-rotate pages | `true` |
| `PAPERLESS_OCR_OUTPUT_TYPE` | Output format | `pdfa` (PDF/A archival format) |

### Consumer Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PAPERLESS_CONSUMER_POLLING` | Polling interval in seconds | `60` |
| `PAPERLESS_CONSUMER_RECURSIVE` | Watch subdirectories | `true` |
| `PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS` | Use subdirectory names as tags | `true` |

### User/Permission Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `USERMAP_UID` | Host UID for file ownership | `1000` |
| `USERMAP_GID` | Host GID for file ownership | `1000` |

### Optional Features

| Variable | Description | Default |
|----------|-------------|---------|
| `PAPERLESS_ENABLE_HTTP_REMOTE_USER` | Enable SSO via reverse proxy header | `false` |
| `PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME` | Header name for remote user | `HTTP_REMOTE_USER` |
| `PAPERLESS_TIKA_ENABLED` | Enable Apache Tika for Office docs | `false` |
| `PAPERLESS_TIKA_ENDPOINT` | Tika server URL | `http://tika:9998` |
| `PAPERLESS_TIKA_GOTENBERG_ENDPOINT` | Gotenberg server URL | `http://gotenberg:3000` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `paperless-data` | `/usr/src/paperless/data` | Application data, search index | 1-5 GB |
| `paperless-media` | `/usr/src/paperless/media` | Stored documents (originals + archive) | 10-100+ GB |
| `paperless-consume` | `/usr/src/paperless/consume` | Consumption directory (inbox) | 1-5 GB (transient) |
| `paperless-export` | `/usr/src/paperless/export` | Export directory for backups | 10-50 GB |

**Storage Note**: The media volume stores both original documents and OCR-processed archive versions. For a document-heavy household, plan for 50+ GB. The consumption directory is transient -- files are moved to media after processing.

## Resource Estimates

| Service | CPU | Memory | Notes |
|---------|-----|--------|-------|
| Paperless-NGX | 2-4 cores | 2-4 GB | OCR processing is CPU-intensive; spikes during document ingestion |
| **Total** | **2-4 cores** | **2-4 GB** | Burst-heavy workload |

OCR processing (Tesseract) is the primary resource consumer. During batch imports, CPU usage will spike significantly. At idle (serving web UI), resource usage is minimal.

## Dependencies

### Shared Services

| Service | Purpose | Details |
|---------|---------|---------|
| Shared PostgreSQL | Primary database | Database: `paperless`, User: `paperless`. PostgreSQL 13+ required. |
| Shared Valkey | Task queue (Celery broker) and result backend | Uses DB index 3. Redis/Valkey 6+ required. |
| Traefik | Reverse proxy + TLS | Routes `paperless.lab.kemo.dev` with StepCA ACME certificate |

### Optional Companion Services

| Service | Purpose | Image |
|---------|---------|-------|
| Apache Tika | Office document parsing (DOCX, XLSX, etc.) | `ghcr.io/paperless-ngx/tika:latest` |
| Gotenberg | Document-to-PDF conversion | `docker.io/gotenberg/gotenberg:8` |
| Paperless-AI | AI-powered classification and tagging | See `documentation/paperless-ai/` |

### Integration Dependencies

- **Paperless-AI** (192.168.42.54) connects to Paperless-NGX via its REST API. An API token must be generated within Paperless-NGX for Paperless-AI to use.

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.42.53` |
| DNS Zone | `lab.kemo.dev` |
| FQDN | `paperless.lab.kemo.dev` |
| Container Network | `lab-network` (macvlan/bridge) |
| Subnet | `192.168.42.0/23` |

### Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.paperless.rule=Host(`paperless.lab.kemo.dev`)"
  - "traefik.http.routers.paperless.entrypoints=websecure"
  - "traefik.http.routers.paperless.tls=true"
  - "traefik.http.routers.paperless.tls.certresolver=step-ca"
  - "traefik.http.services.paperless.loadbalancer.server.port=8000"
```

## Special Considerations

1. **OCR Resource Usage**: Tesseract OCR is CPU-intensive. During bulk document ingestion, expect sustained high CPU usage. Consider setting `PAPERLESS_TASK_WORKERS` to limit concurrent OCR jobs (default is number of CPU cores).

2. **Consumption Directory**: The consume directory is where documents are dropped for automatic processing. It can be exposed via SMB/NFS for network scanning directly into Paperless. Ensure `USERMAP_UID`/`USERMAP_GID` match the host user for proper file permissions.

3. **File Permissions**: The container runs as a configurable UID/GID. Set `USERMAP_UID` and `USERMAP_GID` to match the host user who owns the volume directories. This is critical for the consumption directory.

4. **API Token for Paperless-AI**: After initial setup, create an API token in the Paperless-NGX admin panel (Settings > API Tokens). This token is needed by Paperless-AI for automated document classification.

5. **Tika + Gotenberg**: For processing Office documents (DOCX, XLSX, PPTX, etc.), enable Tika and Gotenberg. These add approximately 1 GB memory overhead but significantly expand supported file formats.

6. **Backup Strategy**: Use the built-in `document_exporter` management command to create full backups to the export directory. Back up both the PostgreSQL `paperless` database and the media volume. The export directory contains a portable backup format.

7. **PAPERLESS_URL**: Must be set to the externally accessible URL (`https://paperless.lab.kemo.dev`) for correct link generation in emails, API responses, and the web UI.

8. **PDF/A Archival**: The default OCR output type `pdfa` creates PDF/A compliant documents for long-term archival. This is the recommended setting.

9. **Shared Valkey DB Index**: Paperless uses Redis/Valkey as a Celery broker. The `PAPERLESS_REDIS` URL must include the DB index (e.g., `/3`) to avoid key collisions with other services on the shared Valkey instance.

10. **Secret Key**: Like all Django applications, `PAPERLESS_SECRET_KEY` must remain constant after initial deployment. Changing it invalidates sessions and tokens.

11. **Document Retention**: Paperless stores both the original uploaded file and the OCR-processed archive version. This approximately doubles storage requirements per document.
