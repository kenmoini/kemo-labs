# Renovate - Dependency Update Bot

Renovate automatically creates merge requests in GitLab when dependencies have updates available. It runs as a scheduled batch job (not a long-running service) that scans configured repositories on each invocation.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set RENOVATE_TOKEN (GitLab personal access token)

# Place the root CA certificate for GitLab HTTPS trust
mkdir -p ./ca-certs
cp /path/to/root-ca.crt ./ca-certs/root-ca.crt

# Create config.js
# Edit ./config.js with platform and discovery settings

# Run once manually
docker compose run --rm renovate
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `RENOVATE_TOKEN` | GitLab personal access token (scopes: api, read/write_repository) |
| `RENOVATE_ENDPOINT` | GitLab API URL (`https://gitlab.lab.kemo.network/api/v4`) |
| `RENOVATE_AUTODISCOVER` | Auto-discover all repos (default: `true`) |
| `LOG_LEVEL` | Logging verbosity (default: `info`) |
| `NODE_EXTRA_CA_CERTS` | Path to root CA cert for internal TLS trust |

## Access

Renovate has no web UI. It creates merge requests directly in GitLab.

## Dependencies

- **GitLab** -- must be running and accessible
- **DNS** -- must resolve `gitlab.lab.kemo.network`

## Maintenance

```bash
# Schedule via host crontab or systemd timer:
# */30 * * * * cd /path/to/development/renovate && docker compose run --rm renovate

# View run output
docker compose logs renovate

# Update image
docker compose pull

# Create a dedicated GitLab 'renovate-bot' user with API access
```

Renovate only consumes resources during active scans (2-4 cores, 1-2 GB RAM). The cache volume (`renovate-cache`) speeds up subsequent runs. Create a dedicated GitLab user and personal access token for the bot.
