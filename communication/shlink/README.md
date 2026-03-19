# Shlink - URL Shortener

Shlink is a self-hosted URL shortener with REST API, visit tracking/analytics, QR code generation, and tag-based organization. Consists of the Shlink server (API + redirect engine) and a web management client.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set SHLINK_DB_PASSWORD

# Ensure shared PostgreSQL has 'shlink' database created

docker compose up -d

# Generate an API key (required for web client)
docker exec shlink shlink api-key:generate
# Copy the key into .env as SHLINK_API_KEY, then restart shlink-web
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DEFAULT_DOMAIN` | Short URL domain (`s.lab.kemo.network`) |
| `SHLINK_DB_PASSWORD` | PostgreSQL password |
| `SHLINK_API_KEY` | API key for the web client (generated after first start) |
| `GEOLITE_LICENSE_KEY` | Optional MaxMind key for IP geolocation analytics |
| `VALIDATE_URLS` | Verify target URLs are reachable before creating (default: `true`) |

## Access

| URL | Purpose |
|-----|---------|
| `https://s.lab.kemo.network` | Short URL redirects and API |
| `https://shlink.lab.kemo.network` | Web management UI |

**Static IP:** 192.168.62.81

## Dependencies

- **Shared PostgreSQL** -- `shlink` database
- **Traefik** -- TLS termination for both server and web client
- **Shared Valkey** (optional) -- Redis caching for improved performance

## Maintenance

```bash
# View logs
docker compose logs -f shlink shlink-web

# Update images
docker compose pull && docker compose up -d

# Generate additional API keys
docker exec shlink shlink api-key:generate

# Import short URLs from CSV
docker exec shlink shlink short-url:import csv < urls.csv

# Health check
curl https://s.lab.kemo.network/rest/health

# Back up: PostgreSQL 'shlink' database (all data is in the DB)
```

Shlink is extremely lightweight (128-512 MB RAM). The API key must be generated after first start and configured in the web client. For GeoIP analytics, register for a free MaxMind GeoLite2 license key.
