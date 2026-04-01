# HashiCorp Vault - Secrets Management

Vault provides centralized secrets management, encryption as a service, and identity-based access control for the homelab. Stores API keys, database credentials, TLS certificates, and other sensitive data with audit logging.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set VAULT_ADDR, VAULT_API_ADDR, VAULT_LOG_LEVEL

# Create the Vault HCL config in ./config/vault.hcl

docker compose up -d

# Initialize Vault (first run only)
docker exec vault vault operator init
# SAVE THE UNSEAL KEYS AND ROOT TOKEN IMMEDIATELY

# Unseal Vault (required after every restart)
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `VAULT_ADDR` | Internal Vault address |
| `VAULT_API_ADDR` | External API address |
| `VAULT_LOG_LEVEL` | Log verbosity (`info`, `debug`, etc.) |
| `SKIP_SETCAP` | Skip mlock setcap for Docker (`true`) |

Vault configuration is in `./config/vault.hcl` using Raft integrated storage.

## Access

| URL | Purpose |
|-----|---------|
| `https://vault.lab.kemo.dev` | Web UI and API |

**Static IP:** 192.168.62.7

## Dependencies

- **PikaPKI / StepCA** -- recommended for TLS certificates
- **DNS** -- recommended for `vault.lab.kemo.dev` resolution

## Maintenance

```bash
# View logs
docker compose logs -f vault

# Check seal status
docker exec vault vault status

# Unseal after restart
docker exec vault vault operator unseal <key>

# Enable a secret engine
docker exec vault vault secrets enable -path=kv kv-v2

# Back up Vault data
docker exec vault vault operator raft snapshot save /vault/data/snapshot.snap
```

Vault starts **sealed** after every restart. You must unseal it with 3 of 5 unseal keys. Never lose the unseal keys or root token -- they are irrecoverable.
