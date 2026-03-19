# GitLab CE - Source Code Management & CI/CD

## Overview

GitLab Community Edition provides self-hosted Git repository management, CI/CD pipelines, container registry, issue tracking, and project management. The heaviest single workload in the homelab.

## Docker Image

- **Image:** `gitlab/gitlab-ce:17.10.2-ce.0`
- **Tag policy:** Pin to specific release, update monthly

## Static IP & DNS

- **IP:** 192.168.62.40
- **DNS:** `gitlab.lab.kemo.network`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP/HTTP | Web UI (behind Traefik) |
| 443 | TCP/HTTPS | Web UI (if not behind Traefik) |
| 22 | TCP | SSH for Git operations |
| 5050 | TCP | GitLab Container Registry (optional, have Nexus) |

## Environment Variables (via GITLAB_OMNIBUS_CONFIG)

GitLab uses `GITLAB_OMNIBUS_CONFIG` for inline Ruby configuration:

```ruby
external_url 'https://gitlab.lab.kemo.network'
nginx['listen_port'] = 80
nginx['listen_https'] = false  # TLS terminated by Traefik

# PostgreSQL - use shared instance
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_host'] = '192.168.62.15'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlab'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = ENV['GITLAB_DB_PASSWORD']

# Redis/Valkey - use shared instance
redis['enable'] = false
gitlab_rails['redis_host'] = '192.168.62.15'
gitlab_rails['redis_port'] = 6379
gitlab_rails['redis_database'] = 5

# SMTP via Mailcow
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = '192.168.62.80'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_domain'] = 'lab.kemo.network'

# LDAP/OIDC via Authentik
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']

# Disable bundled services we don't need
prometheus_monitoring['enable'] = false
grafana['enable'] = false
```

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./config:/etc/gitlab` | GitLab configuration | 100 MB |
| `./data:/var/opt/gitlab` | Repositories, uploads, artifacts, LFS | 50-500 GB |
| `./logs:/var/log/gitlab` | GitLab logs | 1-5 GB |

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 2 cores | 8 cores |
| RAM | 4 GB | 10 GB |

GitLab is the single most resource-intensive workload. Puma workers, Sidekiq, and Gitaly all consume significant memory.

### Memory Optimization
```ruby
puma['worker_processes'] = 2
sidekiq['max_concurrency'] = 10
gitaly['configuration'] = { concurrency: [{ rpc: '/gitaly.SmartHTTPService/PostReceivePack', max_per_repo: 3 }] }
```

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| Shared PostgreSQL | **Required** | `gitlab` database with extensions: `pg_trgm`, `btree_gist` |
| Shared Valkey | **Required** | DB 5 for caching, Sidekiq queues |
| DNS | **Required** | `gitlab.lab.kemo.network` |
| Traefik | Recommended | TLS termination |
| Authentik | Optional | SSO via OIDC |
| Mailcow | Optional | SMTP for notifications |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.62.40
- SSH on port 22 must be exposed directly (not through Traefik)
- HTTP on port 80 routed through Traefik with TLS

## Special Considerations

### PostgreSQL Extensions
The shared PostgreSQL init script must:
```sql
CREATE USER gitlab WITH PASSWORD '${GITLAB_DB_PASSWORD}';
CREATE DATABASE gitlab OWNER gitlab;
\c gitlab
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

### Initial Root Password
Set `GITLAB_ROOT_PASSWORD` env var on first boot, or it generates a random one in `/etc/gitlab/initial_root_password`.

### GitLab Runner
For CI/CD, deploy a GitLab Runner container separately (can be added later):
```yaml
gitlab-runner:
  image: gitlab/gitlab-runner:latest
  volumes:
    - ./runner-config:/etc/gitlab-runner
    - /var/run/docker.sock:/var/run/docker.sock
```

### Backup Strategy
- PostgreSQL via Databasus
- Repositories and uploads via `gitlab-backup create` (built-in rake task)
- Schedule via cron: `0 2 * * * docker exec gitlab gitlab-backup create`

### Valkey DB Index
Using DB 5 (after Authentik on DB 4).

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.gitlab.rule=Host(`gitlab.lab.kemo.network`)"
  - "traefik.http.routers.gitlab.tls=true"
  - "traefik.http.routers.gitlab.tls.certresolver=step-ca"
  - "traefik.http.services.gitlab.loadbalancer.server.port=80"
```
