# Postiz - Social Media Management

Postiz is an open-source social media scheduling and management platform. It supports composing, scheduling, and publishing posts across X/Twitter, LinkedIn, Reddit, Facebook, Instagram, YouTube, TikTok, Mastodon, Discord, and more, with AI-powered content generation.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set JWT_SECRET, POSTIZ_DB_PASSWORD, TEMPORAL_DB_PASSWORD,
#   and social media API keys as needed

# Create Temporal dynamic config
mkdir -p ./dynamicconfig

# Ensure shared PostgreSQL has 'postiz' database created

docker compose up -d
# Temporal stack starts first, then Postiz (allow 1-2 minutes)
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `JWT_SECRET` | JWT signing secret (long random string) |
| `DATABASE_URL` | PostgreSQL connection string for Postiz |
| `REDIS_URL` | Valkey URL with DB index (e.g., `redis://192.168.62.15:6379/6`) |
| `TEMPORAL_DB_PASSWORD` | Password for Temporal's dedicated PostgreSQL |
| Social media `*_API_KEY` / `*_CLIENT_ID` vars | Per-platform API credentials |

## Access

| URL | Purpose |
|-----|---------|
| `https://postiz.lab.kemo.network` | Social media management UI |

**Static IP:** 192.168.62.72

## Dependencies

- **Shared PostgreSQL** -- `postiz` database
- **Shared Valkey** -- DB 6 for job queue and caching
- **Temporal** -- co-deployed workflow engine (with its own PostgreSQL + Elasticsearch)
- **Traefik** -- reverse proxy with TLS

This is a complex stack with 6 containers: Postiz, Temporal, Temporal PostgreSQL, Elasticsearch, Temporal UI, and Temporal Admin Tools.

## Maintenance

```bash
# View logs
docker compose logs -f postiz temporal

# Update images (pin to specific versions)
docker compose pull && docker compose up -d

# Back up:
# 1. PostgreSQL 'postiz' database (shared instance)
# 2. Temporal PostgreSQL (co-deployed, temporal-pg-data volume)
# 3. postiz-uploads volume (media files)
# 4. Social media API keys (store securely)

# Set DISABLE_REGISTRATION=true after creating initial admin
```

Social media OAuth callbacks must point to `https://postiz.lab.kemo.network/api/auth/<platform>/callback`. For AI content generation, point to the local Ollama instance or OpenAI-compatible API.
