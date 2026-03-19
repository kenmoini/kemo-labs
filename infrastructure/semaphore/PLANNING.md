# Semaphore UI - Ansible Automation Platform

## Overview

Semaphore UI is a modern, open-source alternative to Ansible AWX/Tower that provides a web-based interface for running Ansible playbooks, managing inventories, and scheduling automation tasks. In this homelab, Semaphore manages Ansible playbooks for configuring the Fedora host, provisioning VMs, and maintaining other infrastructure components.

Website: https://semaphoreui.com

## Container Image

- **Image:** `semaphoreui/semaphore`
- **Registry:** Docker Hub (official)

## Static IP

- `192.168.62.25`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | Web UI |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SEMAPHORE_DB_DIALECT` | Database type | `postgres` |
| `SEMAPHORE_DB_HOST` | PostgreSQL host | `192.168.62.16` |
| `SEMAPHORE_DB_PORT` | PostgreSQL port | `5432` |
| `SEMAPHORE_DB_USER` | Database user | `semaphore` |
| `SEMAPHORE_DB_PASS` | Database password | `changeme` |
| `SEMAPHORE_DB` | Database name | `semaphore` |
| `SEMAPHORE_ADMIN_NAME` | Admin display name | `Admin` |
| `SEMAPHORE_ADMIN_EMAIL` | Admin email | `admin@lab.kemo.network` |
| `SEMAPHORE_ADMIN` | Admin username | `admin` |
| `SEMAPHORE_ADMIN_PASSWORD` | Admin password | `changeme` |
| `SEMAPHORE_ACCESS_KEY_ENCRYPTION` | Encryption key for stored credentials | (random 32+ char string) |
| `SEMAPHORE_LDAP_ACTIVATED` | Enable/disable LDAP | `no` |
| `TZ` | Timezone | `America/New_York` |

## Storage / Volume Requirements

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./data/` | `/etc/semaphore` | Semaphore configuration and state |
| `~/.ssh/` | `/home/semaphore/.ssh` (read-only) | SSH keys for Ansible connections |
| Ansible configs (optional) | `/home/semaphore/playbooks` | Pre-loaded playbook repositories |

## Resource Estimates

| Resource | Estimate |
|----------|----------|
| CPU | 0.1 - 0.5 core |
| RAM | 128 - 256 MB |
| Disk | Minimal (config only, playbooks fetched from Git) |

## Dependencies

| Dependency | Reason |
|------------|--------|
| Shared PostgreSQL (192.168.62.16) | Database backend -- requires `semaphore` database and user |
| DNS | Hostname resolution for `semaphore.lab.kemo.network` |
| Traefik | Reverse proxy with TLS termination |

## Network Configuration

- Static IP `192.168.62.25` on the homelab macvlan network.
- Exposed through Traefik as `semaphore.lab.kemo.network`.
- Requires outbound network access to Git repositories and target hosts for Ansible.

## Traefik Integration

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.semaphore.rule=Host(`semaphore.lab.kemo.network`)"
  - "traefik.http.routers.semaphore.entrypoints=websecure"
  - "traefik.http.routers.semaphore.tls.certresolver=stepca"
  - "traefik.http.services.semaphore.loadbalancer.server.port=3000"
```

## Special Considerations

1. **Database provisioning:** The shared PostgreSQL init script (`databases/shared/init-scripts/postgres-init.sh`) must include a `semaphore` database and user before first launch.
2. **SSH key access:** Mount the host SSH keys read-only so Semaphore can connect to managed hosts without copying keys into the container.
3. **Access key encryption:** The `SEMAPHORE_ACCESS_KEY_ENCRYPTION` value encrypts stored credentials (SSH keys, passwords) in the database. Generate a strong random string and do not change it after initial setup, or stored credentials become unreadable.
4. **Git integration:** Semaphore clones playbook repositories at run time. Ensure the container has network access to your Git server (e.g., GitLab at another homelab IP).
5. **Ansible collections:** If playbooks require additional Ansible collections, they are installed automatically at task run time, or you can pre-install them by extending the image.
