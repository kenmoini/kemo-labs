# Traefik - Load Balancer and Reverse Proxy

## Overview

Traefik serves as the central ingress point for all homelab services, providing load balancing, reverse proxying, and automatic TLS certificate management. It routes traffic to all other services via `*.lab.kemo.dev` subdomains. Traefik uses both the Docker provider (for automatic service discovery of co-located containers) and the file provider (for routing to services on other hosts or with custom configurations).

## Container Image

- **Image:** `traefik:v3.6`
- **Registry:** Docker Hub (official)

## Static IP

- `192.168.42.10`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP entrypoint (redirects to HTTPS) |
| 443 | TCP | HTTPS entrypoint (primary) |
| 8080 | TCP | Traefik dashboard/API (internal only) |

## Configuration Approach

Traefik uses a **static configuration** file (`traefik.yml`) for core settings and a **dynamic configuration** directory (`/etc/traefik/dynamic/`) via the file provider for route definitions that are not auto-discovered via Docker labels.

### Static Configuration (`traefik.yml`)

Key settings:

- **EntryPoints:**
  - `web` on `:80` -- HTTP, with a redirect-to-HTTPS scheme middleware
  - `websecure` on `:443` -- HTTPS, with TLS and the ACME certificate resolver
- **Providers:**
  - `docker` -- watches the Podman socket for container labels; `exposedByDefault: false` to require explicit opt-in
  - `file` -- watches `/etc/traefik/dynamic/` for YAML route definitions
- **Certificate Resolvers:**
  - `stepca` -- ACME resolver pointing to the internal StepCA server
- **API/Dashboard:**
  - Enabled, exposed behind authentication (not `insecure` mode in production)

### ACME / StepCA Integration

```yaml
certificatesResolvers:
  stepca:
    acme:
      caServer: "https://stepca.lab.kemo.dev:9000/acme/acme/directory"
      email: "admin@lab.kemo.dev"
      storage: "/etc/traefik/acme.json"
      tlsChallenge: {}
```

The StepCA root CA certificate must be available to Traefik. Mount the CA bundle and set the `LEGO_CA_CERTIFICATES` environment variable to its path so the ACME client trusts the internal CA.

### Docker Provider

Services on the same Docker host can be auto-discovered. Each service's `docker-compose.yml` includes Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<service>.rule=Host(`<service>.lab.kemo.dev`)"
  - "traefik.http.routers.<service>.entrypoints=websecure"
  - "traefik.http.routers.<service>.tls.certresolver=stepca"
```

### File Provider

For services not discoverable via Docker labels (e.g., VMs, external hosts), place YAML files in `/etc/traefik/dynamic/`. Traefik watches this directory for changes.

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `LEGO_CA_CERTIFICATES` | Path to StepCA root CA cert for ACME trust | `/etc/traefik/certs/root_ca.crt` |
| `TZ` | Timezone | `America/New_York` |

## Storage / Volume Requirements

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./config/traefik.yml` | `/etc/traefik/traefik.yml` | Static configuration |
| `./config/dynamic/` | `/etc/traefik/dynamic/` | File provider dynamic configs |
| `./data/acme.json` | `/etc/traefik/acme.json` | ACME certificate storage (mode 600) |
| `./certs/root_ca.crt` | `/etc/traefik/certs/root_ca.crt` | StepCA root CA certificate |
| `/var/run/docker.sock` | `/var/run/docker.sock` (read-only) | Docker provider socket |

**Important:** `acme.json` must have file permissions `600` or Traefik will refuse to start.

## Resource Estimates

| Resource | Estimate |
|----------|----------|
| CPU | 0.5 - 1 core |
| RAM | 128 - 256 MB |
| Disk | Minimal (~50 MB for certs and config) |

## Dependencies

| Dependency | Reason |
|------------|--------|
| StepCA | ACME certificate issuance (must be reachable at its CA server URL) |
| DNS (PowerDNS) | Wildcard `*.lab.kemo.dev` must resolve to 192.168.42.10 |
| Podman socket | Required for Docker provider auto-discovery |

## Network Configuration

- Attach to a Podman network with a static IP of `192.168.42.10` using a bridge network, or use host networking with the IP bound on the host.
- All other Podman services that want to be discovered must share a common Podman network with Traefik (e.g., `traefik-net`).
- Wildcard DNS record `*.lab.kemo.dev -> 192.168.42.10` must exist in the PowerDNS authoritative zone.

## Special Considerations

1. **Podman socket security:** Mount the Podman socket read-only (`:ro`). Consider using a Podman socket proxy (e.g., `tecnativa/docker-socket-proxy`) for reduced attack surface.
2. **ACME storage backup:** Back up `acme.json` regularly. Certificate loss means re-issuance from StepCA.
3. **HTTP-to-HTTPS redirect:** Configure a global redirect middleware on the `web` entrypoint so all HTTP traffic is upgraded to HTTPS.
4. **Trusted IPs / Proxy Protocol:** If fronted by another proxy or firewall, configure `forwardedHeaders.trustedIPs` to preserve real client IPs.
5. **Dashboard access:** Protect the dashboard with BasicAuth or ForwardAuth middleware rather than `--api.insecure=true`.
6. **Shared Docker network:** All services that Traefik routes to via the Docker provider must be on the same Docker bridge network as Traefik. Create a dedicated `traefik-net` network.
7. **Rate limiting / middlewares:** Consider adding rate-limiting, IP allowlist, and security headers as global middlewares.
