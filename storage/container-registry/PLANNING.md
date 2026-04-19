# Sonatype Nexus - Container & Package Registry

## Overview

Sonatype Nexus Repository Manager serves as a universal proxy and hosted registry for Docker images, npm packages, Maven artifacts, and more. Acts as a pull-through cache to reduce bandwidth and improve reliability, and as a private registry for internally built images.

## Container Image

- **Image:** `sonatype/nexus3:3.78.0`
- **Tag policy:** Pin to minor version

## Static IP & DNS

- **IP:** 192.168.42.21
- **DNS:** `nexus.lab.kemo.dev`, `registry.lab.kemo.dev` (Docker registry)

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8081 | TCP/HTTP | Nexus Web UI and API |
| 8082 | TCP/HTTP | Docker hosted registry |
| 8083 | TCP/HTTP | Docker proxy registry (pull-through cache) |
| 8084 | TCP/HTTP | Docker group registry (combines hosted + proxy) |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `INSTALL4J_ADD_VM_PARAMS` | JVM options | `-Xms2g -Xmx4g -XX:MaxDirectMemorySize=2g` |
| `NEXUS_SECURITY_RANDOMPASSWORD` | Disable random initial password | `false` |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./data:/nexus-data` | All repositories, blobs, config, embedded DB | 50-500 GB |

Nexus stores blob data (container layers, packages) in `/nexus-data/blobs/`. As a proxy cache, storage grows based on what's pulled through it.

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 0.5 cores | 4 cores |
| RAM | 2 GB | 6 GB |

Nexus is JVM-based and memory-hungry. Allocate at least 2 GB heap via `INSTALL4J_ADD_VM_PARAMS`.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| DNS | Recommended | Multiple DNS names for different registry endpoints |
| Traefik | Recommended | TLS termination and routing by hostname |
| StepCA | Recommended | TLS certs for registry endpoints |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.42.21
- Multiple ports for different repository types
- Traefik routes by hostname to different ports:
  - `nexus.lab.kemo.dev` → 8081 (Web UI)
  - `registry.lab.kemo.dev` → 8084 (Docker group)

## Special Considerations

### Repository Configuration (Post-Deploy)
Configure via Web UI after first boot:

1. **Docker Hosted** (port 8082) — Private images built in the lab
2. **Docker Proxy** (port 8083) — Pull-through cache for Docker Hub, GHCR, Quay, etc.
3. **Docker Group** (port 8084) — Combines hosted + all proxies into single endpoint

### Docker Client Configuration
Configure Docker daemon on all hosts to use Nexus as mirror:
```json
{
  "registry-mirrors": ["https://registry.lab.kemo.dev"],
  "insecure-registries": []
}
```

### Proxy Registries to Configure
- Docker Hub (`https://registry-1.docker.io`)
- GitHub Container Registry (`https://ghcr.io`)
- Quay.io (`https://quay.io`)
- Google Container Registry (`https://gcr.io`)

### Cleanup Policies
Configure blob store cleanup tasks to prevent unbounded storage growth:
- Delete unused proxy cache after 30 days
- Compact blob store weekly

### Authentication
- Default admin password is in `/nexus-data/admin.password` on first boot
- Change immediately and create service accounts for CI/CD
- Can integrate with Authentik via LDAP for user auth

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  # Web UI
  - "traefik.http.routers.nexus.rule=Host(`nexus.lab.kemo.dev`)"
  - "traefik.http.routers.nexus.tls=true"
  - "traefik.http.routers.nexus.tls.certresolver=stepca"
  - "traefik.http.services.nexus.loadbalancer.server.port=8081"
  # Docker registry
  - "traefik.http.routers.registry.rule=Host(`registry.lab.kemo.dev`)"
  - "traefik.http.routers.registry.tls=true"
  - "traefik.http.routers.registry.tls.certresolver=stepca"
  - "traefik.http.services.registry.loadbalancer.server.port=8084"
```
