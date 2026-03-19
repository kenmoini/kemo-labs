#\!/usr/bin/env bash
# Initialize the lab.kemo.network zone in PowerDNS Authoritative
# Run this after the pdns-auth container is up and healthy.
# Usage: ./init-zone.sh [API_KEY]

set -euo pipefail

PDNS_API_KEY="${1:-${PDNS_AUTH_API_KEY:-changeme}}"
PDNS_HOST="http://192.168.62.2:8081"

echo "Creating zone lab.kemo.network..."
curl -s -X POST "${PDNS_HOST}/api/v1/servers/localhost/zones" \
  -H "X-API-Key: ${PDNS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "lab.kemo.network.",
    "kind": "Native",
    "nameservers": ["ns1.lab.kemo.network."],
    "rrsets": [
      {
        "name": "ns1.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.2", "disabled": false}]
      },
      {
        "name": "*.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.10", "disabled": false}]
      },
      {
        "name": "pihole.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.4", "disabled": false}]
      },
      {
        "name": "traefik.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.10", "disabled": false}]
      },
      {
        "name": "proxy.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.11", "disabled": false}]
      },
      {
        "name": "netboot.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.12", "disabled": false}]
      },
      {
        "name": "peanut.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.12", "disabled": false}]
      },
      {
        "name": "speedtest.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.13", "disabled": false}]
      },
      {
        "name": "home.lab.kemo.network.",
        "type": "A",
        "ttl": 3600,
        "records": [{"content": "192.168.62.14", "disabled": false}]
      }
    ]
  }'

echo ""
echo "Zone created. Verifying..."
curl -s "${PDNS_HOST}/api/v1/servers/localhost/zones/lab.kemo.network." \
  -H "X-API-Key: ${PDNS_API_KEY}" | python3 -m json.tool 2>/dev/null || echo "(install python3 for pretty output)"
