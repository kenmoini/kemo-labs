# Network Testing - iPerf3 + OpenSpeedTest

## Overview

This stack provides network performance testing tools for the homelab:

1. **iPerf3** -- Industry-standard network bandwidth measurement tool. Runs as a server that clients connect to for throughput testing between hosts.
2. **OpenSpeedTest** -- Self-hosted HTML5 speed test (similar to speedtest.net) accessible via a web browser. Uses only static HTML/CSS/JS with a web server backend, requiring no plugins or client-side software.

## Docker Images

| Service | Image | Notes |
|---------|-------|-------|
| iPerf3 | `networkstatic/iperf3:latest` | Lightweight iPerf3 server |
| OpenSpeedTest | `openspeedtest/latest:latest` | Official OpenSpeedTest image with Nginx |

## Static IP

- `192.168.62.13` (shared by both services on different ports)

## Required Ports

### iPerf3

| Port | Protocol | Purpose |
|------|----------|---------|
| 5201 | TCP/UDP | iPerf3 server (default port) |

### OpenSpeedTest

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | HTTP speed test interface |
| 3001 | TCP | HTTPS speed test interface |

## Environment Variables

### iPerf3

No environment variables required. Command-line flags are used:

```
iperf3 -s  # run as server
```

### OpenSpeedTest

| Variable | Purpose | Example |
|----------|---------|---------|
| `ENABLE_LETSENCRYPT` | Enable built-in TLS (not needed behind Traefik) | `false` |

## Storage / Volume Requirements

### iPerf3

No persistent storage required. Stateless server.

### OpenSpeedTest

No persistent storage required. The image contains all static assets.

## Resource Estimates

| Service | CPU | RAM |
|---------|-----|-----|
| iPerf3 | 0.5 - 1 core (during active tests) | 32 MB |
| OpenSpeedTest | 0.25 core (during active tests) | 64 MB |
| **Total** | **0.75 - 1.25 core** | **96 MB** |

**Note:** CPU usage spikes during active speed tests. At idle, both services consume negligible resources.

## Dependencies

| Dependency | Reason |
|------------|--------|
| DNS | Hostname resolution for `speedtest.lab.kemo.network` |
| Traefik | Reverse proxy for OpenSpeedTest web UI |

## Network Configuration

- Static IP `192.168.62.13` on the homelab macvlan/ipvlan network.
- iPerf3 (port 5201) must be directly accessible from test clients; it cannot be reverse-proxied.
- OpenSpeedTest web UI is exposed through Traefik as `speedtest.lab.kemo.network`.
- For accurate speed test results, the container should have direct network access without NAT overhead if possible.

## Traefik Integration

OpenSpeedTest through Traefik requires increasing the maximum request body size to at least 35 MB for upload tests. Add Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.speedtest.rule=Host(`speedtest.lab.kemo.network`)"
  - "traefik.http.routers.speedtest.entrypoints=websecure"
  - "traefik.http.routers.speedtest.tls.certresolver=stepca"
  - "traefik.http.services.speedtest.loadbalancer.server.port=3000"
```

**Important:** If using Traefik as reverse proxy, ensure the `buffering` middleware allows large POST bodies (35 MB+) and timeouts are set to 60+ seconds for accurate upload test results.

## Special Considerations

1. **Reverse proxy body size:** OpenSpeedTest requires the reverse proxy to accept POST bodies of at least 35 MB. Traefik's default is typically sufficient, but verify with the `buffering` middleware if upload tests fail or report low speeds.
2. **Reverse proxy timeouts:** Set proxy timeouts to at least 60 seconds. Speed tests perform sustained transfers and can be killed by short timeouts.
3. **iPerf3 direct access:** iPerf3 clients connect directly via `iperf3 -c 192.168.62.13`. There is no web interface for iPerf3 -- it is a CLI tool.
4. **Parallel tests:** iPerf3 in default mode handles one test at a time. Use `--one-off` flag or run multiple instances on different ports if parallel tests are needed.
5. **Network accuracy:** For the most accurate results, avoid running speed tests through the proxy chain. Access OpenSpeedTest directly at `http://192.168.62.13:3000` for baseline measurements, and through Traefik to measure proxied performance.
6. **HTTP/2 and HTTP/3:** OpenSpeedTest supports HTTP/2 and HTTP/3 which can improve speed test accuracy. Traefik supports HTTP/2 natively.
