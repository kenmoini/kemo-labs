# AFFiNE - Knowledge Base & Wiki

## Overview

AFFiNE is an open-source knowledge base and wiki platform that combines docs, whiteboards, and database-like tables in a single workspace. It supports real-time collaboration, markdown editing, and a block-based editor similar to Notion. In this homelab, AFFiNE will serve as the primary knowledge management and documentation platform.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| AFFiNE Server | `ghcr.io/toeverything/affine` | `stable` |
| AFFiNE Migration | `ghcr.io/toeverything/affine` | `stable` (same image, runs migration script) |

The migration container runs `node ./scripts/self-host-predeploy.js` and exits after completion. It must run successfully before the main server starts.

**Note**: AFFiNE's official compose uses `pgvector/pgvector:pg16` for PostgreSQL because it requires the pgvector extension. The shared PostgreSQL instance must have the pgvector extension installed, or a dedicated PostgreSQL container with pgvector must be used.

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3010 | TCP | HTTP web UI and API |

Traefik will proxy `affine.lab.kemo.dev` to port 3010 with TLS via StepCA ACME.

## Environment Variables

### Core Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `AFFINE_REVISION` | Release channel | `stable` |
| `PORT` | Server listen port | `3010` |
| `AFFINE_SERVER_HTTPS` | Whether external access is HTTPS | `true` |
| `AFFINE_SERVER_HOST` | Public hostname | `affine.lab.kemo.dev` |
| `AFFINE_SERVER_EXTERNAL_URL` | Full external URL (alternative to host+https) | `https://affine.lab.kemo.dev` |
| `AFFINE_INDEXER_ENABLED` | Enable search indexer | `false` (can enable later) |

### Database Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `DATABASE_URL` | Full PostgreSQL connection string | `postgresql://affine:<password>@shared-pgsql:5432/affine` |
| `DB_USERNAME` | PostgreSQL username | `affine` |
| `DB_PASSWORD` | PostgreSQL password | (generate secure value) |
| `DB_DATABASE` | PostgreSQL database name | `affine` |

### Redis Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `REDIS_SERVER_HOST` | Valkey/Redis hostname | `shared-valkey` |
| `REDIS_SERVER_PORT` | Valkey/Redis port | `6379` |
| `REDIS_SERVER_PASSWORD` | Valkey/Redis password | (if configured) |
| `REDIS_SERVER_DATABASE` | Valkey/Redis DB index | `2` (avoid collision with other services) |

### Storage Configuration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `UPLOAD_LOCATION` | Path for uploaded blobs/files | `/data/affine/storage` |
| `CONFIG_LOCATION` | Path for custom config files | `/data/affine/config` |
| `DB_DATA_LOCATION` | Path for PG data (only if dedicated PG) | `/data/affine/postgres` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `affine-storage` | `/root/.affine/storage` | Uploaded files, images, blobs | 5-20 GB |
| `affine-config` | `/root/.affine/config` | Custom configuration files | <100 MB |

Database storage is handled by the shared PostgreSQL instance (with pgvector).

## Resource Estimates

| Service | CPU | Memory | Notes |
|---------|-----|--------|-------|
| AFFiNE Server | 1-2 cores | 1-2 GB | Node.js application, scales with users |
| AFFiNE Migration | 0.5 core | 512 MB | Runs once at startup, then exits |
| **Total (steady state)** | **1-2 cores** | **1-2 GB** | |

## Dependencies

### Shared Services

| Service | Purpose | Details |
|---------|---------|---------|
| Shared PostgreSQL | Primary database | Database: `affine`, User: `affine`. **Requires pgvector extension.** PostgreSQL 16+ recommended. |
| Shared Valkey | Caching and pub/sub | Uses a dedicated DB index (e.g., 2) to avoid collision. |
| Traefik | Reverse proxy + TLS | Routes `affine.lab.kemo.dev` with StepCA ACME certificate |

### Critical Note: pgvector Requirement

AFFiNE requires the `pgvector` PostgreSQL extension for vector search functionality. Options:

1. **Preferred**: Install the pgvector extension in the shared PostgreSQL instance (if using `postgres:16+`, install `postgresql-16-pgvector` package).
2. **Alternative**: Run a dedicated `pgvector/pgvector:pg16` container for AFFiNE only.

### Optional Integrations

- **Keycloak** - OAuth 2.0 SSO (AFFiNE supports OAuth configuration)
- **SMTP** - Email notifications and invitations

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.42.51` |
| DNS Zone | `lab.kemo.dev` |
| FQDN | `affine.lab.kemo.dev` |
| Container Network | `lab-network` (macvlan/bridge) |
| Subnet | `192.168.42.0/23` |

### Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.affine.rule=Host(`affine.lab.kemo.dev`)"
  - "traefik.http.routers.affine.entrypoints=websecure"
  - "traefik.http.routers.affine.tls=true"
  - "traefik.http.routers.affine.tls.certresolver=step-ca"
  - "traefik.http.services.affine.loadbalancer.server.port=3010"
```

## Special Considerations

1. **Migration Container**: The `affine_migration` container must complete successfully before the main server starts. It runs database migrations via `node ./scripts/self-host-predeploy.js`. Use `condition: service_completed_successfully` in compose depends_on.

2. **pgvector Extension**: This is a hard requirement. Without pgvector in PostgreSQL, AFFiNE will fail to start. Verify with `SELECT * FROM pg_extension WHERE extname = 'vector';` after setup.

3. **Data Persistence Warning**: Per AFFiNE docs, most `.env` values (especially database credentials and locations) should not be changed after initial data has been written. Changing them may corrupt or orphan data.

4. **AFFINE_SERVER_EXTERNAL_URL**: Must be set correctly for WebSocket connections and link generation. Since Traefik handles TLS, set this to `https://affine.lab.kemo.dev`.

5. **Container User**: AFFiNE runs as root inside the container by default (writes to `/root/.affine/`). Volume permissions should accommodate this.

6. **WebSocket Support**: AFFiNE uses WebSockets for real-time collaboration. Ensure Traefik is configured to pass WebSocket upgrades (typically automatic with default Traefik config).

7. **Shared Valkey DB Index**: Use a dedicated DB index (e.g., 2) for AFFiNE to avoid key collisions with Netbox (which uses 0 and 1) and other services.

8. **Backup Strategy**: Back up the PostgreSQL `affine` database and the `affine-storage` volume (uploaded files). The config volume can be recreated from configuration.

9. **Health Checks**: The official compose relies on PostgreSQL and Redis health checks before starting the server. Ensure the shared services expose health check endpoints or use network-based checks.

10. **Indexer**: The `AFFINE_INDEXER_ENABLED` flag controls the search indexer. It can be disabled initially for simpler deployment and enabled later when search performance matters.
