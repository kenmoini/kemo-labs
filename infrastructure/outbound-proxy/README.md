# Outbound Proxy - Squid

Squid provides a forward HTTP/HTTPS proxy for the homelab network, caching package downloads (RPMs, debs, container layers) to reduce bandwidth usage and improve performance.

## Quick Start

```bash
# Ensure Squid config exists
# Edit ./config/squid.conf as needed

# Create data directories
mkdir -p ./data/cache ./data/logs

docker compose up -d
```

## Configuration

Squid is configured via `./config/squid.conf`, not environment variables. Key settings:

| Setting | Purpose |
|---------|---------|
| `http_port 3128` | Proxy listening port |
| `cache_dir` | Disk cache size and location |
| `cache_mem` | In-memory cache size |
| `acl localnet src` | Allowed client networks |
| `dns_nameservers` | DNS servers Squid uses (point to Pi-hole) |

| Env Variable | Purpose |
|-------------|---------|
| `TZ` | Timezone (default: `America/New_York`) |

## Access

| Address | Purpose |
|---------|---------|
| `192.168.42.11:3128` | Proxy endpoint |

Configure clients with: `http_proxy=http://192.168.42.11:3128` and `https_proxy=http://192.168.42.11:3128`.

## Dependencies

- **DNS (Pi-hole / Recursor)** -- Squid needs DNS resolution for upstream domains

## Maintenance

```bash
# View logs
docker compose logs -f squid
tail -f ./data/logs/access.log

# Check cache stats
docker exec squid squidclient mgr:info

# Clear cache
docker compose down
rm -rf ./data/cache/*
docker compose up -d

# Update image
docker compose pull && docker compose up -d
```

Allocate 10-50 GB for the cache directory depending on usage. Configure log rotation to prevent unbounded log growth.
