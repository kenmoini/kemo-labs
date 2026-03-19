# IT Tools - Developer Utility Suite

IT Tools is a collection of handy developer utilities accessible via a web interface: encoders/decoders, converters, generators, network tools, and more. Fully client-side with no backend processing -- completely stateless.

## Quick Start

```bash
docker compose up -d
```

No configuration, environment variables, or persistent storage required.

## Configuration

None. IT Tools is a static web application served by Nginx.

## Access

| URL | Purpose |
|-----|---------|
| `https://tools.lab.kemo.network` | Developer utility suite |

**Static IP:** 192.168.62.43

## Dependencies

- **DNS** -- `tools.lab.kemo.network`
- **Traefik** -- TLS termination

## Maintenance

```bash
# View logs
docker compose logs -f it-tools

# Update image
docker compose pull && docker compose up -d
```

Extremely lightweight (16-64 MB RAM). Available tools include: hash generators (MD5, SHA, bcrypt), Base64/URL encoders, UUID generators, JWT decoder, JSON/YAML converters, cron expression parser, CIDR calculator, and many more. All processing happens in the browser.
