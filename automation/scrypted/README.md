# Scrypted - Smart Home Camera Management

Scrypted is a camera management platform focused on low-latency video streaming and AI-based object detection (motion, person, vehicle). It bridges IP cameras to HomeKit Secure Video, Google Home, and Home Assistant with hardware-accelerated transcoding.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set WATCHTOWER_HTTP_API_TOKEN

# Create volume directory
mkdir -p ./volume

docker compose up -d

# Complete initial setup at:
# https://192.168.62.61:10443
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `WATCHTOWER_HTTP_API_TOKEN` | Auth token for the Watchtower auto-update sidecar |
| `SCRYPTED_NVR_VOLUME` | NVR recording storage path (uncomment for NVR features) |

Most configuration is done through the web UI: adding cameras, configuring plugins, and setting up integrations.

## Access

| URL | Purpose |
|-----|---------|
| `https://scrypted.lab.kemo.network` | Web UI (via Traefik file provider) |
| `https://192.168.62.61:10443` | Direct access (self-signed cert) |

**Static IP:** 192.168.62.61 (assigned at the host level, not Docker)

## Dependencies

- **DNS** -- hostname resolution
- **Traefik** -- routes via file provider (host networking, not Docker labels)
- **Home Assistant** (optional) -- camera integration via HomeKit Bridge or HACS plugin
- **MQTT** (optional) -- event publishing to shared Mosquitto broker

Scrypted uses **host networking** for ONVIF/mDNS camera discovery.

## Maintenance

```bash
# View logs
docker compose logs -f scrypted

# Scrypted auto-updates via the bundled Watchtower sidecar (hourly checks)
# To manually update:
docker compose pull && docker compose up -d

# GPU passthrough for hardware transcoding:
# /dev/dri is mounted by default for Intel/AMD
# For NVIDIA: use ghcr.io/koush/scrypted:nvidia image with runtime: nvidia

# NVR storage: plan for 10-20 GB/day per 1080p camera recording 24/7
```

Pass `/dev/dri` for Intel/AMD GPU acceleration. For USB devices (Coral TPU), uncomment the `devices` section. The Watchtower sidecar is scoped to only update the Scrypted container and will not affect other services.
