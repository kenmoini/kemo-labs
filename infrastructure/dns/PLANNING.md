# DNS - PowerDNS Authoritative + PowerDNS Recursor + Pi-hole

## Overview

The DNS stack provides authoritative name resolution for the `lab.kemo.dev` zone, recursive resolution for all other domains, and network-wide ad blocking. The three components work in a chain:

1. **PowerDNS Authoritative** -- serves the `lab.kemo.dev` zone with all internal records
2. **PowerDNS Recursor** -- forwards `lab.kemo.dev` queries to the Auth server, and all other queries to upstream public DNS resolvers
3. **Pi-hole** -- provides DNS-level ad/tracker blocking using the Recursor as its upstream, and serves as the DNS server advertised to all clients on the network

## Container Images

| Service | Image | Notes |
|---------|-------|-------|
| PowerDNS Authoritative | `powerdns/pdns-auth-49:latest` | Official image; use SQLite or PostgreSQL backend |
| PowerDNS Recursor | `powerdns/pdns-recursor-51:latest` | Official image |
| Pi-hole | `pihole/pihole:latest` | Official Pi-hole v6 image |

## Static IPs

| Service | IP Address |
|---------|-----------|
| PowerDNS Authoritative | `192.168.62.2` |
| PowerDNS Recursor | `192.168.62.3` |
| Pi-hole | `192.168.62.4` |

## Required Ports

### PowerDNS Authoritative (192.168.62.2)

| Port | Protocol | Purpose |
|------|----------|---------|
| 53 | TCP/UDP | DNS queries |
| 8081 | TCP | REST API (optional, for management) |

### PowerDNS Recursor (192.168.62.3)

| Port | Protocol | Purpose |
|------|----------|---------|
| 53 | TCP/UDP | DNS queries |
| 8082 | TCP | REST API / metrics (optional) |

### Pi-hole (192.168.62.4)

| Port | Protocol | Purpose |
|------|----------|---------|
| 53 | TCP/UDP | DNS queries (client-facing) |
| 80 | TCP | Web admin interface (HTTP) |
| 443 | TCP | Web admin interface (HTTPS, self-signed by FTL) |

## Environment Variables

### PowerDNS Authoritative

| Variable | Purpose | Example |
|----------|---------|---------|
| `PDNS_AUTH_API_KEY` | API key for REST API | `<secret>` |
| `PDNS_AUTH_WEBSERVER` | Enable web server | `yes` |
| `PDNS_AUTH_WEBSERVER_ADDRESS` | Listen address for API | `0.0.0.0` |
| `PDNS_AUTH_WEBSERVER_PORT` | API port | `8081` |
| `PDNS_AUTH_WEBSERVER_ALLOW_FROM` | Allowed CIDR for API | `192.168.62.0/23,127.0.0.0/8` |

Configuration is typically passed via a mounted `pdns.conf` file. Key directives:

```
launch=gsqlite3
gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
local-address=0.0.0.0
local-port=53
api=yes
api-key=<secret>
webserver=yes
webserver-address=0.0.0.0
webserver-port=8081
webserver-allow-from=192.168.62.0/23,127.0.0.0/8
```

### PowerDNS Recursor

Configuration via mounted `recursor.conf`:

```
local-address=0.0.0.0
local-port=53
forward-zones=lab.kemo.dev=192.168.62.2
forward-zones-recurse=.=1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4
allow-from=192.168.62.0/23,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12
webserver=yes
webserver-address=0.0.0.0
webserver-port=8082
api-key=<secret>
```

### Pi-hole

| Variable | Purpose | Example |
|----------|---------|---------|
| `TZ` | Timezone | `America/New_York` |
| `FTLCONF_webserver_api_password` | Admin web UI password | `<secret>` |
| `FTLCONF_dns_listeningMode` | DNS listening mode | `all` |
| `FTLCONF_dns_upstreams` | Upstream DNS server(s) | `192.168.62.3` |

## Storage / Volume Requirements

### PowerDNS Authoritative

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./pdns-auth/config/pdns.conf` | `/etc/powerdns/pdns.conf` | Configuration |
| `./pdns-auth/data/` | `/var/lib/powerdns/` | SQLite database |

### PowerDNS Recursor

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./pdns-recursor/config/recursor.conf` | `/etc/powerdns/recursor.conf` | Configuration |

### Pi-hole

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./pihole/etc-pihole/` | `/etc/pihole/` | Pi-hole databases and config |

## Resource Estimates

| Service | CPU | RAM |
|---------|-----|-----|
| PowerDNS Authoritative | 0.25 core | 64 - 128 MB |
| PowerDNS Recursor | 0.25 core | 128 - 256 MB |
| Pi-hole | 0.25 core | 128 - 256 MB |
| **Total** | **0.75 core** | **320 - 640 MB** |

## Dependencies

| Dependency | Reason |
|------------|--------|
| None (foundational) | DNS is a foundational service; other workloads depend on it |

**Note:** DNS must be deployed and functional before most other services can resolve hostnames. It is the first service to bring up.

## Network Configuration

- Each container gets a dedicated static IP on the `192.168.62.0/23` network using a bridged Podman network.
- Pi-hole is advertised as the DNS server to all DHCP clients on the network (set in the DHCP server / router config).
- The query flow is: **Client -> Pi-hole (192.168.62.4) -> Recursor (192.168.62.3) -> Auth (192.168.62.2)** for `lab.kemo.dev` queries, or **Client -> Pi-hole -> Recursor -> upstream** for external queries.
- Pi-hole requires `cap_add: NET_ADMIN` in Docker.

## DNS Zone Records (lab.kemo.dev)

The PowerDNS Authoritative server must be pre-populated with at minimum:

| Record | Type | Value | Notes |
|--------|------|-------|-------|
| `lab.kemo.dev` | SOA | `ns1.lab.kemo.dev admin.lab.kemo.dev ...` | Zone SOA |
| `lab.kemo.dev` | NS | `ns1.lab.kemo.dev` | Nameserver |
| `ns1.lab.kemo.dev` | A | `192.168.62.2` | Auth server |
| `*.lab.kemo.dev` | A | `192.168.62.10` | Wildcard pointing to Traefik |
| `pihole.lab.kemo.dev` | A | `192.168.62.4` | Direct access to Pi-hole |
| `traefik.lab.kemo.dev` | A | `192.168.62.10` | Traefik dashboard |

Additional A records should be added for each service with a dedicated IP that is accessed directly (not through Traefik).

## Special Considerations

1. **Bootstrap problem:** DNS must be the first stack deployed. Other services depend on name resolution. Consider using IPs directly in Traefik/StepCA configs until DNS is fully operational.
2. **Zone initialization:** PowerDNS Auth with SQLite backend requires the schema to be initialized on first run. The official image handles this, but the zone and records must be created via the API or `pdnsutil` after startup.
3. **Pi-hole upstream configuration:** Pi-hole must be configured to use the Recursor (192.168.62.3) as its sole upstream DNS, not any public resolvers directly. This ensures all queries pass through the Recursor's forwarding logic.
4. **DNSSEC:** Consider enabling DNSSEC on the Auth server for the local zone if desired.
5. **Reverse DNS:** Consider adding a PTR zone for `62.168.192.in-addr.arpa` for reverse lookups.
6. **Health monitoring:** PowerDNS Auth and Recursor both expose APIs that can be used for health checks and metrics collection.
7. **Pi-hole cap_add:** The Pi-hole container requires `NET_ADMIN` capability when used with custom networking.
