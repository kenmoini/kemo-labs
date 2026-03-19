# Postiz - Planning

## Overview

Postiz is an open-source social media management and scheduling platform. It allows composing, scheduling, and publishing posts across multiple social media platforms from a single interface. It supports AI-powered content generation, analytics, team collaboration, and integrations with platforms including X/Twitter, LinkedIn, Reddit, Facebook, Instagram, YouTube, TikTok, Mastodon, Discord, and more.

**Purpose in this homelab:** Centralized social media management tool for scheduling and publishing content across multiple platforms, with AI-assisted content creation powered by the local Ollama/OpenAI API integration.

## Docker Images

| Service | Image | Tag |
|---------|-------|-----|
| Postiz | `ghcr.io/gitroomhq/postiz-app` | `v2.20.2` |
| Temporal | `temporalio/auto-setup` | `1.28.1` |
| Temporal UI | `temporalio/ui` | `2.34.0` |
| Temporal Admin Tools | `temporalio/admin-tools` | `1.28.1-tctl-1.18.4-cli-1.4.1` |
| Elasticsearch (for Temporal) | `elasticsearch` | `7.17.27` |

- Postiz requires a Temporal workflow engine for background job scheduling and execution.
- Temporal in turn requires its own PostgreSQL database and Elasticsearch instance.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 5000 | TCP | Postiz | Web UI and API (internal container port) |
| 7233 | TCP | Temporal | Temporal gRPC API (internal only) |
| 8080 | TCP | Temporal UI | Temporal dashboard (optional, internal only) |
| 9200 | TCP | Elasticsearch | Temporal search backend (internal only) |

- Only Postiz port 5000 needs to be exposed through Traefik.
- Temporal, Temporal UI, and Elasticsearch are internal-only services.

## Environment Variables

### Postiz (Main Application)

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `MAIN_URL` | Public-facing URL | `https://postiz.lab.kemo.network` |
| `FRONTEND_URL` | Public-facing frontend URL | `https://postiz.lab.kemo.network` |
| `NEXT_PUBLIC_BACKEND_URL` | Public API URL | `https://postiz.lab.kemo.network/api` |
| `BACKEND_INTERNAL_URL` | Internal backend URL | `http://localhost:3000` |
| `JWT_SECRET` | JWT signing secret | (generated secret, long random string) |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postiz:<password>@shared-postgres:5432/postiz` |
| `REDIS_URL` | Valkey/Redis connection string | `redis://shared-valkey:6379/0` |
| `TEMPORAL_ADDRESS` | Temporal server address | `temporal:7233` |
| `IS_GENERAL` | Required flag | `true` |
| `DISABLE_REGISTRATION` | Disable public signups after setup | `true` |
| `STORAGE_PROVIDER` | File storage backend | `local` |
| `UPLOAD_DIRECTORY` | Upload directory path | `/uploads` |
| `NEXT_PUBLIC_UPLOAD_DIRECTORY` | Public upload path | `/uploads` |
| `API_LIMIT` | Public API rate limit (per hour) | `30` |
| `NX_ADD_PLUGINS` | Developer setting | `false` |

### Social Media API Keys (configure per-platform as needed)

| Variable | Description |
|----------|-------------|
| `X_API_KEY` / `X_API_SECRET` | X/Twitter API credentials |
| `LINKEDIN_CLIENT_ID` / `LINKEDIN_CLIENT_SECRET` | LinkedIn OAuth |
| `REDDIT_CLIENT_ID` / `REDDIT_CLIENT_SECRET` | Reddit OAuth |
| `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET` | Facebook/Meta App |
| `YOUTUBE_CLIENT_ID` / `YOUTUBE_CLIENT_SECRET` | YouTube OAuth |
| `TIKTOK_CLIENT_ID` / `TIKTOK_CLIENT_SECRET` | TikTok OAuth |
| `MASTODON_URL` / `MASTODON_CLIENT_ID` / `MASTODON_CLIENT_SECRET` | Mastodon instance |
| `DISCORD_CLIENT_ID` / `DISCORD_CLIENT_SECRET` / `DISCORD_BOT_TOKEN_ID` | Discord Bot |
| `SLACK_ID` / `SLACK_SECRET` / `SLACK_SIGNING_SECRET` | Slack App |
| `THREADS_APP_ID` / `THREADS_APP_SECRET` | Threads/Meta |
| `PINTEREST_CLIENT_ID` / `PINTEREST_CLIENT_SECRET` | Pinterest |
| `DRIBBBLE_CLIENT_ID` / `DRIBBBLE_CLIENT_SECRET` | Dribbble |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | GitHub |

### Optional Settings

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `OPENAI_API_KEY` | OpenAI API key for AI content generation | (secret, or point to local Ollama-compatible API) |
| `RESEND_API_KEY` | Email service for user activation | (optional) |
| `EMAIL_FROM_ADDRESS` | From address for emails | (optional) |

### OAuth/SSO Integration

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `POSTIZ_GENERIC_OAUTH` | Enable generic OAuth | `true` |
| `POSTIZ_OAUTH_URL` | OAuth provider base URL | `https://auth.lab.kemo.network` |
| `POSTIZ_OAUTH_AUTH_URL` | Authorization endpoint | `https://auth.lab.kemo.network/application/o/authorize` |
| `POSTIZ_OAUTH_TOKEN_URL` | Token endpoint | `https://auth.lab.kemo.network/application/o/token` |
| `POSTIZ_OAUTH_USERINFO_URL` | UserInfo endpoint | `https://auth.lab.kemo.network/application/o/userinfo` |
| `POSTIZ_OAUTH_CLIENT_ID` | OAuth client ID | (from identity provider) |
| `POSTIZ_OAUTH_CLIENT_SECRET` | OAuth client secret | (secret) |

### Temporal Environment

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `DB` | Temporal DB type | `postgres12` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_USER` | Temporal DB user | `temporal` |
| `POSTGRES_PWD` | Temporal DB password | (secret) |
| `POSTGRES_SEEDS` | PostgreSQL host | `temporal-postgresql` |
| `ENABLE_ES` | Enable Elasticsearch | `true` |
| `ES_SEEDS` | Elasticsearch host | `temporal-elasticsearch` |
| `ES_VERSION` | Elasticsearch version | `v7` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `postiz-config` | `/config/` | Postiz configuration | 100 MB |
| `postiz-uploads` | `/uploads/` | Media uploads (images, videos) | 5-50 GB |
| `temporal-es-data` | `/var/lib/elasticsearch/data` | Temporal Elasticsearch data | 1-5 GB |
| `temporal-pg-data` | `/var/lib/postgresql/data` | Temporal PostgreSQL data | 500 MB - 2 GB |

- Upload storage will grow based on social media content volume.
- Temporal requires its own PostgreSQL instance (separate from the shared homelab PGSQL) plus Elasticsearch for workflow search/visibility.

## Resource Estimates

| Service | CPU | RAM |
|---------|-----|-----|
| Postiz | 1-2 cores | 512 MB - 1 GB |
| Temporal | 1-2 cores | 512 MB - 1 GB |
| Temporal PostgreSQL | 0.5 core | 256-512 MB |
| Elasticsearch | 1-2 cores | 512 MB - 1 GB (Java heap: 256 MB) |
| **Total Stack** | **4-6 cores** | **2-3.5 GB** |

- Elasticsearch is the heaviest component; its Java heap is configured via `ES_JAVA_OPTS=-Xms256m -Xmx256m` for the Temporal use case.
- The Postiz stack is moderately resource-intensive due to the Temporal dependency.

## Dependencies

| Dependency | Type | Required | Notes |
|------------|------|----------|-------|
| PostgreSQL (shared) | Shared database | Yes | Postiz application database |
| Valkey/Redis (shared) | Shared cache/queue | Yes | Postiz job queue and caching |
| Temporal | Co-deployed service | Yes | Background job scheduling engine |
| Temporal PostgreSQL | Co-deployed database | Yes | Temporal's own PostgreSQL (separate from shared) |
| Elasticsearch | Co-deployed service | Yes | Temporal workflow visibility/search |
| Traefik | Reverse proxy | Yes | TLS termination via StepCA ACME |
| StepCA | TLS certificates | Yes | ACME provider for Traefik |

### Shared PostgreSQL Setup

A dedicated database and user must be created on the shared PostgreSQL instance for Postiz:

```sql
CREATE USER postiz WITH PASSWORD '<secure-password>';
CREATE DATABASE postiz OWNER postiz;
GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;
```

### Shared Valkey/Redis

Postiz connects to the shared Valkey instance. Use a dedicated database index (e.g., `/0` or `/2`) to avoid key collisions with other services:

```
REDIS_URL=redis://shared-valkey:6379/0
```

### Temporal's Own PostgreSQL

Temporal requires its own dedicated PostgreSQL instance. This is separate from the shared homelab PostgreSQL because Temporal manages its own schema migrations and has specific version requirements. This PostgreSQL instance is co-deployed within the Postiz compose stack.

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.62.72` |
| DNS Name | `postiz.lab.kemo.network` |
| Docker Network | Shared macvlan/bridge with static IP assignment |
| Traefik Labels | Route `postiz.lab.kemo.network` to container port 5000 |

### Traefik Integration

- HTTPS entrypoint with TLS certificate from StepCA ACME.
- Traefik labels on the Postiz container for automatic service discovery.
- `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` must all use the HTTPS public URL.

### Internal Networks

The Postiz compose stack requires two internal networks:

1. **postiz-network**: Connects Postiz to the shared PostgreSQL and Valkey services.
2. **temporal-network**: Connects Temporal server, its PostgreSQL, Elasticsearch, and the Postiz app.

Additionally, the compose stack needs access to the shared database network to reach the shared PostgreSQL and Valkey instances.

## Special Considerations

### Temporal Complexity

Postiz depends on Temporal for reliable background job execution (scheduling posts, processing media, etc.). The Temporal stack adds significant complexity:

- 4 additional containers (Temporal server, Temporal PostgreSQL, Elasticsearch, optionally Temporal UI and admin tools).
- Temporal UI (port 8080) is optional but useful for debugging workflow issues. Consider exposing it through Traefik at `temporal.lab.kemo.network` for admin access.
- Temporal admin-tools container is optional and only needed for maintenance/debugging.

### Dynamic Config for Temporal

Temporal requires a dynamic config file. The upstream docker-compose mounts `./dynamicconfig` into the Temporal container. Create a minimal config:

```yaml
# dynamicconfig/development-sql.yaml
limit.maxIDLength:
  - value: 255
    constraints: {}
system.forceSearchAttributesCacheRefreshOnRead:
  - value: true
    constraints: {}
```

### Social Media API Callbacks

Most social media platform integrations require OAuth callback URLs. These must point to the public HTTPS URL:

- Callback URL pattern: `https://postiz.lab.kemo.network/api/auth/<platform>/callback`
- Each platform's developer portal must have this callback URL registered.
- This means the Postiz instance must be reachable from the internet for OAuth flows (or use a tunnel/proxy for initial setup).

### AI Content Generation

- Postiz supports OpenAI-compatible APIs for AI-powered content generation.
- Can potentially point `OPENAI_API_KEY` and a custom base URL to the local Ollama instance (via Open WebUI's OpenAI-compatible API) for private AI content generation.

### Security

- Set `DISABLE_REGISTRATION=true` after creating the initial admin account.
- Store all social media API keys securely; they grant posting access to connected accounts.
- `JWT_SECRET` must be a long, random string and should be backed up.
- Consider enabling generic OAuth SSO via `POSTIZ_GENERIC_OAUTH` for centralized identity management.

### Backup Strategy

- Database: Back up the `postiz` database on the shared PostgreSQL instance.
- Temporal database: Back up the co-deployed Temporal PostgreSQL instance.
- Uploads: Back up the `/uploads` volume (media files).
- Social media API keys: Securely store all API credentials externally.
