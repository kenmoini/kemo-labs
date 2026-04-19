# Sonatype Nexus - Container and Package Registry

Nexus Repository Manager serves as a universal proxy and hosted registry for Docker images, npm packages, Maven artifacts, and more. Acts as a pull-through cache to reduce bandwidth and as a private registry for internally built images.

## Quick Start

```bash
# Create data directory
mkdir -p ./data

docker compose up -d

# Wait for startup (Nexus takes 1-2 minutes on first boot)
# Default admin password is in:
docker exec nexus cat /nexus-data/admin.password
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `INSTALL4J_ADD_VM_PARAMS` | JVM heap and memory settings (default: `-Xms2g -Xmx4g`) |
| `NEXUS_SECURITY_RANDOMPASSWORD` | Set to `false` to use known initial password |

Repositories are configured via the web UI after first boot. Set up Docker Hosted, Docker Proxy (pull-through cache for Docker Hub, GHCR, Quay), and Docker Group registries.

## Access

| URL | Purpose |
|-----|---------|
| `https://nexus.lab.kemo.dev` | Nexus Web UI and API |
| `https://registry.lab.kemo.dev` | Docker registry (group, combines hosted + proxy) |

**Static IP:** 192.168.42.21

## Dependencies

- **DNS** -- multiple DNS names for different registry endpoints
- **Traefik** -- TLS termination and hostname-based routing

## Maintenance

```bash
# View logs
docker compose logs -f nexus

# Update image (pin to specific version)
# Edit docker-compose.yml, then:
docker compose pull && docker compose up -d

# Configure Docker daemon to use Nexus as mirror:
# Add to /etc/docker/daemon.json:
# {"registry-mirrors": ["https://registry.lab.kemo.dev"]}

# Set up cleanup policies in the web UI to prevent unbounded cache growth
```

Nexus is JVM-based and requires at least 2 GB heap. The `./data` volume can grow to 50-500 GB as a proxy cache. Change the default admin password immediately after first login.
