# Home Assistant - Home Automation Platform

Home Assistant is an open-source home automation platform for local control of smart home devices. It serves as the central hub for device management, automations, dashboards, and integrations with hundreds of IoT devices and services via MQTT, Zigbee, Z-Wave, and more.

## Quick Start

```bash
# Create config directory
mkdir -p ./config

docker compose up -d

# Complete initial setup wizard at:
# http://192.168.62.60:8123
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `TZ` | Timezone (default: `America/New_York`) |

Home Assistant is configured primarily via `./config/configuration.yaml`, not environment variables. Key settings to add after setup:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.62.0/23
```

## Access

| URL | Purpose |
|-----|---------|
| `https://home-assistant.lab.kemo.network` | Web UI (via Traefik file provider) |
| `http://192.168.62.60:8123` | Direct access |

**Static IP:** 192.168.62.60 (assigned at the host level, not Docker)

## Dependencies

- **Shared MQTT (Mosquitto)** -- for Zigbee2MQTT, Tasmota, ESPHome device communication
- **DNS** -- hostname resolution
- **Traefik** -- routes via file provider (not Docker labels, since this uses host networking)

Home Assistant uses **host networking** for mDNS/SSDP/UPnP device discovery. The static IP must be assigned on the host interface.

## Maintenance

```bash
# View logs
docker compose logs -f home-assistant

# Update image (pin to specific version)
# Edit docker-compose.yml, then:
docker compose pull && docker compose up -d

# Back up configuration
tar czf ha-backup.tar.gz ./config/

# Home Assistant also has built-in backup via the UI

# For USB device passthrough (Zigbee/Z-Wave sticks):
# Uncomment the 'devices:' section in docker-compose.yml
```

Configure `secrets.yaml` in the config directory for sensitive values. Enable MFA (TOTP) for admin accounts. The MQTT integration is configured through the web UI pointing to the shared Mosquitto broker.
