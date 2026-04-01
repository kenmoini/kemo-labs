# n8n - Workflow Automation Platform

n8n is a visual workflow automation platform with 400+ integrations, custom code nodes, webhooks, scheduling, and AI agent workflows. It is the self-hosted alternative to Zapier/Make, serving as the central automation hub for the homelab.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set DB_POSTGRESDB_PASSWORD, N8N_ENCRYPTION_KEY (generate and save securely)

# Ensure shared PostgreSQL has 'n8n' database created

docker compose up -d

# First user to access creates the owner account
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DB_POSTGRESDB_PASSWORD` | PostgreSQL password |
| `N8N_ENCRYPTION_KEY` | Encrypts stored credentials (MUST be backed up) |
| `WEBHOOK_URL` | External webhook URL (`https://n8n.lab.kemo.dev/`) |
| `N8N_AI_ENABLED` | Enable built-in AI features (default: `true`) |
| `EXECUTIONS_DATA_MAX_AGE` | Execution data retention in hours (default: `168`) |
| `GENERIC_TIMEZONE` | Timezone for scheduled workflows |

## Access

| URL | Purpose |
|-----|---------|
| `https://n8n.lab.kemo.dev` | Workflow editor and webhook receiver |

**Static IP:** 192.168.62.71

## Dependencies

- **Shared PostgreSQL** -- `n8n` database
- **Traefik** -- reverse proxy with TLS
- **Open WebUI / Ollama** (optional) -- for AI workflow nodes

## Maintenance

```bash
# View logs
docker compose logs -f n8n

# Update image (pin to specific version)
docker compose pull && docker compose up -d

# Back up:
# 1. PostgreSQL 'n8n' database (workflow definitions, credentials)
# 2. N8N_ENCRYPTION_KEY (losing it = all stored credentials unrecoverable)
# 3. n8n-data volume (binary execution data)

# Prometheus metrics at /metrics (enabled by default)
# Health check at /healthz

# Export workflows via API for version-controlled backup
```

The `N8N_ENCRYPTION_KEY` encrypts all stored credentials. It must be backed up securely -- losing it means all credentials are irrecoverable. Execution data is pruned after 7 days by default.
