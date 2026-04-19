# Outbound Proxy - Squid

## Overview

Squid serves as a forward (outbound) proxy for the homelab network, providing HTTP/HTTPS caching to reduce bandwidth usage and improve performance, as well as outbound traffic control and logging. Services and hosts on the network can be configured to route their outbound HTTP(S) traffic through this proxy. This is particularly useful for caching package downloads (RPMs, debs, container images) and controlling egress.

## Container Image

- **Image:** `ubuntu/squid:latest`
- **Registry:** Docker Hub (Canonical/Ubuntu official)
- **Alternative:** `sameersbn/squid:3.5.27-2` (well-known community image)

## Static IP

- `192.168.42.11`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 3128 | TCP | HTTP proxy (default Squid port) |
| 3129 | TCP | HTTPS/CONNECT proxy (optional, if configured separately) |

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `TZ` | Timezone | `America/New_York` |

Most Squid configuration is done via the `squid.conf` file rather than environment variables.

## Configuration (`squid.conf`)

Key configuration directives:

```
# Listening port
http_port 3128

# Cache settings
cache_dir ufs /var/spool/squid 10000 16 256
maximum_object_size 1024 MB
cache_mem 512 MB

# Access control
acl localnet src 192.168.42.0/23
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
http_access allow localnet
http_access deny all

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log

# DNS
dns_nameservers 192.168.42.4

# Timeouts
connect_timeout 30 seconds
read_timeout 60 seconds

# Visible hostname
visible_hostname proxy.lab.kemo.dev
```

## Storage / Volume Requirements

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./config/squid.conf` | `/etc/squid/squid.conf` | Squid configuration |
| `./data/cache/` | `/var/spool/squid/` | Cache storage (disk-based) |
| `./data/logs/` | `/var/log/squid/` | Access and cache logs |

### Cache Disk Sizing

Allocate **10 - 50 GB** of disk space for the cache depending on usage patterns. Package repository caching (RPMs, debs, container layers) benefits significantly from larger cache sizes.

## Resource Estimates

| Resource | Estimate |
|----------|----------|
| CPU | 0.5 - 1 core |
| RAM | 512 MB - 1 GB (depends on `cache_mem` setting) |
| Disk | 10 - 50 GB for cache storage |

## Dependencies

| Dependency | Reason |
|------------|--------|
| DNS (Pi-hole / Recursor) | Squid needs DNS resolution for upstream domains |

## Network Configuration

- Static IP `192.168.42.11` on the homelab macvlan/ipvlan network.
- Clients use this proxy by setting `http_proxy=http://192.168.42.11:3128` and `https_proxy=http://192.168.42.11:3128` in their environment.
- Docker containers can be configured to use this proxy via daemon-level proxy settings or per-container environment variables.
- Traefik subdomain: `proxy.lab.kemo.dev` (for Squid cache manager web interface if enabled).

## Special Considerations

1. **HTTPS/TLS interception:** By default, Squid uses CONNECT tunneling for HTTPS (no caching of HTTPS content). If HTTPS caching is desired, SSL-bump must be configured with a trusted CA certificate, which adds complexity. For a homelab, CONNECT tunneling is usually sufficient.
2. **Cache initialization:** On first run, Squid needs to initialize its cache directories. The container entrypoint usually handles this (`squid -z`), but verify it completes before Squid starts serving.
3. **Container image pull caching:** Docker can be configured to use Squid as a registry mirror proxy. This requires additional Squid configuration to handle Docker registry traffic correctly.
4. **ACLs for safety:** Restrict the proxy to the local network. Do not allow arbitrary external access.
5. **Log rotation:** Squid logs can grow large. Configure logrotate or Squid's built-in log rotation (`logfile_rotate`).
6. **DNS configuration:** Point Squid at Pi-hole (192.168.42.4) for DNS resolution so it benefits from local DNS and ad blocking.
7. **No-proxy list:** Services that communicate locally (e.g., within the Podman network) should bypass the proxy. Set `no_proxy=localhost,127.0.0.1,.lab.kemo.dev,192.168.42.0/23` in client configurations.
