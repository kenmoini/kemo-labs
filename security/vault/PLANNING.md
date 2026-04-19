# HashiCorp Vault - Secrets Management

## Overview

HashiCorp Vault provides centralized secrets management, encryption as a service, and identity-based access for the homelab. Stores API keys, database credentials, TLS certificates, and other sensitive data with audit logging and fine-grained access control.

## Container Image

- **Image:** `hashicorp/vault:1.19`
- **Tag policy:** Pin to minor version

## Static IP & DNS

- **IP:** 192.168.42.7
- **DNS:** `vault.lab.kemo.dev`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8200 | TCP/HTTPS | API and Web UI |
| 8201 | TCP | Cluster communication (not needed for single-node) |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault address (internal) | `http://0.0.0.0:8200` |
| `VAULT_API_ADDR` | External API address | `https://vault.lab.kemo.dev` |
| `VAULT_LOG_LEVEL` | Log verbosity | `info` |
| `SKIP_SETCAP` | Skip mlock setcap (Docker) | `true` |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./data:/vault/data` | Raft integrated storage | 1-5 GB |
| `./config:/vault/config` | Vault HCL configuration | < 1 MB |
| `./logs:/vault/logs` | Audit logs | 1-10 GB |
| `./tls:/vault/tls` | TLS certificates (from StepCA or PikaPKI) | < 1 MB |

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 0.1 cores | 1 core |
| RAM | 128 MB | 512 MB |

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| PikaPKI / StepCA | Recommended | TLS certificate for Vault API |
| DNS | Recommended | `vault.lab.kemo.dev` resolution |

## Vault Configuration (vault.hcl)

```hcl
ui = true
disable_mlock = true

storage "raft" {
  path = "/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
}

api_addr = "https://vault.lab.kemo.dev:8200"
cluster_addr = "https://vault.lab.kemo.dev:8201"
```

## Network Configuration

- macvlan/ipvlan with static IP 192.168.42.7
- Port 8200 exposed directly AND routed through Traefik
- Vault can also run with TLS disabled behind Traefik (simpler), or with its own TLS certs

## Special Considerations

### Initialization & Unseal
- First start requires `vault operator init` to generate unseal keys and root token
- **Critical:** Back up unseal keys and root token immediately — losing them means losing all secrets
- Consider auto-unseal via transit (requires another Vault) or using a simple unseal script for homelab
- Vault starts sealed after every restart — need a mechanism to unseal

### IPC_LOCK Capability
```yaml
cap_add:
  - IPC_LOCK
```
Required for mlock to prevent secrets from being swapped to disk. Alternatively set `disable_mlock = true` in config (acceptable for homelab).

### Secret Engines to Enable
- `kv-v2` — General key-value secrets
- `database` — Dynamic database credentials (MariaDB, PostgreSQL)
- `pki` — Could supplement StepCA for short-lived certs
- `transit` — Encryption as a service

### Auth Methods
- `userpass` — Simple username/password for humans
- `oidc` — Integrate with Authentik for SSO
- `token` — For service-to-service auth
- `approle` — For automated workloads

### Audit Logging
Enable file audit backend to `/vault/logs/audit.log` for compliance and debugging.

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.vault.rule=Host(`vault.lab.kemo.dev`)"
  - "traefik.http.routers.vault.tls=true"
  - "traefik.http.routers.vault.tls.certresolver=stepca"
  - "traefik.http.services.vault.loadbalancer.server.port=8200"
```
