# Renovate - Dependency Update Bot

## Overview

Renovate automatically creates merge requests in GitLab when dependencies have updates available. Runs as a scheduled container (not a long-running service) that scans configured repositories on each run.

## Container Image

- **Image:** `renovate/renovate:39-full`
- **Tag policy:** Pin to major version with `-full` suffix (includes all language managers)

## Static IP & DNS

- **IP:** 192.168.62.41 (only needed if running as persistent service)
- **DNS:** `renovate.lab.kemo.dev` (optional, for logs UI)

## Required Ports

None — Renovate is a batch job, not a web service. Optionally expose a web dashboard if using Renovate Server mode.

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `RENOVATE_PLATFORM` | Platform type | `gitlab` |
| `RENOVATE_ENDPOINT` | GitLab API URL | `https://gitlab.lab.kemo.dev/api/v4` |
| `RENOVATE_TOKEN` | GitLab personal access token | (secret) |
| `RENOVATE_GIT_AUTHOR` | Git commit author | `Renovate Bot <renovate@lab.kemo.dev>` |
| `RENOVATE_AUTODISCOVER` | Auto-discover all repos | `true` |
| `RENOVATE_AUTODISCOVER_FILTER` | Filter repos | `*/*` |
| `LOG_LEVEL` | Logging verbosity | `info` |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./config:/usr/src/app/config` | Renovate config (config.js) | < 1 KB |
| `./cache:/tmp/renovate` | Package manager cache | 1-5 GB |

## Resource Estimates

| Resource | Idle (between runs) | Peak (during scan) |
|----------|------|------|
| CPU | 0 cores | 2-4 cores |
| RAM | 0 MB | 1-2 GB |

Only consumes resources when actively scanning repos.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| GitLab | **Required** | Platform to scan and create MRs |
| DNS | Recommended | Must resolve `gitlab.lab.kemo.dev` |

## Network Configuration

- Needs network access to GitLab API
- Needs outbound access to check upstream package registries (npm, Docker Hub, etc.)
- Can route through Squid outbound proxy

## Special Considerations

### Scheduling
Run as a cron-scheduled container rather than long-running:
```yaml
# Option 1: Docker restart policy with cron
restart: unless-stopped
# Trigger via host crontab or systemd timer:
# */30 * * * * docker compose -f /path/to/docker-compose.yml run --rm renovate

# Option 2: Use labels with Ofelia or similar Docker cron
```

### config.js
```javascript
module.exports = {
  platform: 'gitlab',
  endpoint: 'https://gitlab.lab.kemo.dev/api/v4',
  gitAuthor: 'Renovate Bot <renovate@lab.kemo.dev>',
  autodiscover: true,
  autodiscoverFilter: ['*/*'],
  onboarding: true,
  // Trust internal CA
  hostRules: [
    {
      matchHost: 'gitlab.lab.kemo.dev',
      insecureRegistry: false,
    },
  ],
};
```

### Internal CA Trust
Renovate needs to trust StepCA/PikaPKI root CA to talk to GitLab over HTTPS:
```yaml
volumes:
  - ./ca-certs/root-ca.crt:/usr/local/share/ca-certificates/homelab-root.crt:ro
environment:
  - NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/homelab-root.crt
```

### GitLab Token
Create a GitLab personal access token with `api`, `read_user`, `read_repository`, `write_repository` scopes for a dedicated `renovate-bot` user.
