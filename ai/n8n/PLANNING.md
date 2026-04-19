# n8n - Planning

## Overview

n8n is a workflow automation platform that allows building complex automations through a visual node-based editor. It supports 400+ integrations, custom JavaScript/Python code nodes, webhooks, scheduling, and AI agent workflows. It is the open-source, self-hostable alternative to Zapier/Make.

**Purpose in this homelab:** Central automation hub for connecting services, processing webhooks, scheduling tasks, orchestrating AI workflows (connecting to Ollama/Open WebUI), monitoring alerts, and general home/lab automation.

## Container Images

| Service | Image | Tag |
|---------|-------|-----|
| n8n | `ghcr.io/n8n-io/n8n` | `2.13.1` |

- n8n publishes to both Docker Hub (`n8nio/n8n`) and GHCR (`ghcr.io/n8n-io/n8n`). Prefer GHCR for consistency.
- Pin to a specific version tag rather than `latest` for stability.

## Required Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 5678 | TCP | n8n | Web UI and webhook receiver |

- Traefik will reverse-proxy to n8n on port 5678.
- Webhooks are received on the same port as the UI.

## Environment Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `DB_TYPE` | Database backend type | `postgresdb` |
| `DB_POSTGRESDB_HOST` | PostgreSQL host | `shared-postgres` (or IP of shared PGSQL) |
| `DB_POSTGRESDB_PORT` | PostgreSQL port | `5432` |
| `DB_POSTGRESDB_DATABASE` | Database name | `n8n` |
| `DB_POSTGRESDB_USER` | Database user | `n8n` |
| `DB_POSTGRESDB_PASSWORD` | Database password | (secret) |
| `N8N_HOST` | Hostname for n8n | `n8n.lab.kemo.dev` |
| `N8N_PORT` | Port n8n listens on | `5678` |
| `N8N_PROTOCOL` | Protocol for generated URLs | `https` |
| `WEBHOOK_URL` | External webhook URL | `https://n8n.lab.kemo.dev/` |
| `N8N_ENCRYPTION_KEY` | Key for encrypting credentials stored in DB | (generated secret) |
| `N8N_USER_FOLDER` | User data folder inside container | `/home/node/.n8n` |
| `N8N_DIAGNOSTICS_ENABLED` | Disable telemetry | `false` |
| `N8N_METRICS` | Enable Prometheus metrics endpoint | `true` |
| `GENERIC_TIMEZONE` | Timezone for scheduled workflows | `America/New_York` |
| `TZ` | Container timezone | `America/New_York` |
| `N8N_RUNNERS_MODE` | Task runner mode (optional) | `internal` |

### Optional AI Integration Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `N8N_AI_ENABLED` | Enable built-in AI features | `true` |

## Storage / Volume Requirements

| Volume | Container Path | Purpose | Estimated Size |
|--------|---------------|---------|----------------|
| `n8n-data` | `/home/node/.n8n` | Local file storage, binary data, logs | 1-10 GB |

- Workflow definitions and credentials are stored in PostgreSQL (shared instance).
- The local volume stores file uploads, binary execution data, and local config.
- Binary data from workflow executions can grow quickly depending on workload; consider configuring execution data pruning.

## Resource Estimates

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2-4 cores |
| RAM | 512 MB | 1-2 GB |

- Resource usage scales with the number and complexity of concurrent workflow executions.
- Workflows that process large files or run AI inference chains will temporarily spike CPU/RAM usage.
- The n8n task runner (for JavaScript/Python code execution) can be resource-intensive for complex scripts.

## Dependencies

| Dependency | Type | Required | Notes |
|------------|------|----------|-------|
| PostgreSQL | Shared database | Yes | Shared PGSQL instance from `databases/{shared}` |
| Traefik | Reverse proxy | Yes | TLS termination via StepCA ACME |
| StepCA | TLS certificates | Yes | ACME provider for Traefik |
| Open WebUI / Ollama | Optional integration | No | For AI workflow nodes |

### Shared PostgreSQL Setup

A dedicated database and user must be created on the shared PostgreSQL instance:

```sql
CREATE USER n8n WITH PASSWORD '<secure-password>';
CREATE DATABASE n8n OWNER n8n;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
```

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.42.71` |
| DNS Name | `n8n.lab.kemo.dev` |
| Container Network | Shared bridge to homelab-lab with static IP assignment |
| Traefik Labels | Route `n8n.lab.kemo.dev` to container port 5678 |

### Traefik Integration

- HTTPS entrypoint with TLS certificate from StepCA ACME.
- Traefik labels on the n8n container for automatic service discovery.
- Webhook URL must match the external HTTPS URL so that callback URLs work correctly.

### Cross-Service Communication

- n8n needs network access to the shared PostgreSQL instance.
- n8n may need access to other services on the lab network for automation (e.g., Ollama API at `192.168.42.70:11434`, Home Assistant, email servers, etc.).
- Ensure the Podman network configuration allows n8n to reach other service IPs in the `192.168.42.0/23` range.

## Special Considerations

### Encryption Key

- `N8N_ENCRYPTION_KEY` encrypts all stored credentials in the database. This key MUST be backed up securely -- losing it means all stored credentials become unrecoverable.
- Generate once and store in a secrets manager or vault.

### Webhook Security

- n8n exposes webhooks on its main port. Traefik handles TLS but consider additional webhook authentication at the n8n workflow level.
- Set `WEBHOOK_URL` to `https://n8n.lab.kemo.dev/` so generated webhook URLs are correct.

### Execution Data Retention

- By default, n8n keeps all execution data indefinitely. Configure pruning to avoid unbounded database growth:
  - `EXECUTIONS_DATA_PRUNE=true`
  - `EXECUTIONS_DATA_MAX_AGE=168` (hours, e.g., 7 days)

### User Management

- n8n supports email-based user accounts with an owner account created on first launch.
- LDAP and SAML SSO are available in the enterprise/community edition for integration with identity providers.

### Monitoring

- Enable `N8N_METRICS=true` to expose a Prometheus-compatible `/metrics` endpoint for integration with observability stack.
- Health check endpoint: `GET /healthz` returns 200 when n8n is ready.

### Backup Strategy

- Database: Back up the `n8n` database on the shared PostgreSQL instance.
- Encryption key: Securely store `N8N_ENCRYPTION_KEY` separately.
- Volume: Back up `/home/node/.n8n` for binary execution data if needed.
- Workflows can also be exported via the n8n API or CLI for version-controlled backup.
