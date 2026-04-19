# GitLab CE - Source Code Management and CI/CD

GitLab Community Edition provides self-hosted Git repository management, CI/CD pipelines, issue tracking, and project management. The heaviest single workload in the homelab, using shared PostgreSQL and Valkey instead of bundled instances.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set GITLAB_ROOT_PASSWORD, GITLAB_DB_PASSWORD

# Ensure shared PostgreSQL has 'gitlab' database with pg_trgm and btree_gist extensions
# Ensure shared Valkey is running

docker compose up -d
# First boot takes 3-5 minutes for migrations
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `GITLAB_ROOT_PASSWORD` | Initial root password (first boot only) |
| `GITLAB_DB_PASSWORD` | PostgreSQL password for the gitlab user |
| `TZ` | Timezone |

GitLab is configured via `GITLAB_OMNIBUS_CONFIG` in docker-compose.yml (inline Ruby). Key settings: external PostgreSQL, external Valkey (DB 5), SMTP via Mailcow, SSO via Authentik.

## Access

| URL | Purpose |
|-----|---------|
| `https://gitlab.lab.kemo.dev` | Web UI |
| `192.168.42.40:22` | SSH for Git operations (direct, not proxied) |

**Static IP:** 192.168.42.40

## Dependencies

- **Shared PostgreSQL** -- `gitlab` database with `pg_trgm` and `btree_gist` extensions
- **Shared Valkey** -- DB 5 for caching and Sidekiq queues
- **DNS** -- `gitlab.lab.kemo.dev`
- **Authentik** (optional) -- SSO via OIDC
- **Mailcow** (optional) -- SMTP notifications

## Maintenance

```bash
# View logs
docker compose logs -f gitlab

# GitLab backup (built-in)
docker exec gitlab gitlab-backup create

# Schedule backups via cron:
# 0 2 * * * docker exec gitlab gitlab-backup create

# Update image (pin to specific version, test first)
docker compose pull && docker compose up -d

# Check status
docker exec gitlab gitlab-ctl status
```

GitLab uses 4-10 GB RAM. Memory is tuned via Puma workers and Sidekiq concurrency in the omnibus config. The initial root password is only used on first boot; if not set, check `/etc/gitlab/initial_root_password`.
