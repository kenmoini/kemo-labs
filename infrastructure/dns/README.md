# DNS - PowerDNS Authoritative + Recursor + Pi-hole

A three-tier DNS stack providing authoritative name resolution for `lab.kemo.network`, recursive resolution for external domains, and network-wide ad blocking. Query flow: Client -> Pi-hole -> Recursor -> Auth (for local zones) or upstream resolvers (for external).

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set PIHOLE_API_PASSWORD, PDNS_AUTH_API_KEY

# Ensure config files exist
# ./pdns-auth/config/pdns.conf
# ./pdns-recursor/config/recursor.conf

docker compose up -d

# Initialize the DNS zone (first run only)
./init-zone.sh
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `PIHOLE_API_PASSWORD` | Pi-hole admin web UI password |
| `PDNS_AUTH_API_KEY` | PowerDNS Auth REST API key |
| `TZ` | Timezone (default: `America/New_York`) |

PowerDNS Auth and Recursor are configured via mounted config files (`pdns.conf`, `recursor.conf`).

## Access

| URL / IP | Purpose |
|----------|---------|
| `https://pihole.lab.kemo.network` | Pi-hole admin dashboard (via Traefik) |
| `192.168.62.4:53` | Pi-hole DNS (set as network DNS server) |
| `192.168.62.2:8081` | PowerDNS Auth API |
| `192.168.62.3:8082` | PowerDNS Recursor API |

## Dependencies

**None** -- DNS is the foundational service. It must be deployed first before other services can resolve hostnames.

## Maintenance

```bash
# View logs
docker compose logs -f

# Update Pi-hole
docker compose pull pihole && docker compose up -d pihole

# Add a DNS record via PowerDNS API
curl -X PATCH http://192.168.62.2:8081/api/v1/servers/localhost/zones/lab.kemo.network. \
  -H "X-API-Key: $PDNS_AUTH_API_KEY" \
  -d '{"rrsets": [{"name": "new.lab.kemo.network.", "type": "A", "ttl": 300, "changetype": "REPLACE", "records": [{"content": "192.168.62.x", "disabled": false}]}]}'

# Back up Pi-hole config
cp -r ./pihole/etc-pihole/ /path/to/backup/

# Back up PowerDNS database
cp ./pdns-auth/data/pdns.sqlite3 /path/to/backup/
```
