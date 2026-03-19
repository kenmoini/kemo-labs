# Network Testing - iPerf3 + OpenSpeedTest

Provides network performance testing tools: iPerf3 for CLI-based bandwidth measurement between hosts, and OpenSpeedTest for browser-based speed testing (similar to speedtest.net).

## Quick Start

```bash
docker compose up -d
```

No configuration files or environment variables are required. Both services are stateless.

## Configuration

| Variable | Purpose |
|----------|---------|
| `ENABLE_LETSENCRYPT` | Set to `false` (TLS handled by Traefik) |

No persistent storage is needed for either service.

## Access

| Address | Purpose |
|---------|---------|
| `https://speedtest.lab.kemo.network` | OpenSpeedTest web UI (via Traefik) |
| `192.168.62.13:5201` | iPerf3 server (connect with `iperf3 -c 192.168.62.13`) |

## Dependencies

- **DNS** -- hostname resolution for `speedtest.lab.kemo.network`
- **Traefik** -- reverse proxy for OpenSpeedTest web UI

## Maintenance

```bash
# View logs
docker compose logs -f

# Update images
docker compose pull && docker compose up -d

# Run a bandwidth test from any client
iperf3 -c 192.168.62.13

# For accurate baseline measurements, access OpenSpeedTest directly at
# http://192.168.62.13:3000 to bypass Traefik overhead
```

CPU usage spikes during active tests but is negligible at idle. iPerf3 handles one test at a time by default.
