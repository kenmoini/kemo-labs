# IT Tools - Developer Utility Suite

## Overview

IT Tools is a collection of handy developer utilities accessible via a web interface: encoders/decoders, converters, generators, network tools, and more. Fully client-side — no backend processing, completely stateless.

## Container Image

- **Image:** `corentinth/it-tools:latest`
- **Tag policy:** Latest is fine (stateless app, no data at risk)

## Static IP & DNS

- **IP:** 192.168.62.43
- **DNS:** `tools.lab.kemo.network`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP/HTTP | Web UI |

## Environment Variables

None required. IT Tools is a static web application.

## Storage / Volumes

None required. Completely stateless — all processing happens in the browser.

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 0.02 cores | 0.1 cores |
| RAM | 16 MB | 64 MB |

Extremely lightweight — it's just an NGINX container serving static files.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| DNS | Recommended | `tools.lab.kemo.network` |
| Traefik | Recommended | TLS termination |

## Network Configuration

- macvlan/ipvlan with static IP 192.168.62.43
- Single HTTP port behind Traefik

## Special Considerations

### Available Tools Include
- Hash generators (MD5, SHA, bcrypt)
- Base64/URL/HTML encoders
- UUID/ULID generators
- JWT decoder
- JSON/YAML/TOML converters
- Cron expression parser
- SQL formatter
- Color converter
- Network tools (CIDR calculator, IPv4/IPv6)
- And many more

### Authentication
Consider protecting with Authentik forward auth if you don't want it publicly accessible on the LAN.

## Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.it-tools.rule=Host(`tools.lab.kemo.network`)"
  - "traefik.http.routers.it-tools.tls=true"
  - "traefik.http.routers.it-tools.tls.certresolver=step-ca"
  - "traefik.http.services.it-tools.loadbalancer.server.port=80"
```
