# Home Assistant - Planning

## Overview

Home Assistant is an open-source home automation platform that puts local control and privacy first. It serves as the central hub for smart home device management, automations, dashboards, and integrations with hundreds of IoT devices and services. Home Assistant connects to the shared MQTT broker for device communication (Zigbee2MQTT, Tasmota devices, ESPHome, etc.).

- **Documentation:** https://www.home-assistant.io/docs/
- **Docker Installation:** https://www.home-assistant.io/installation/linux#docker-compose
- **Source:** https://github.com/home-assistant/core

## Container Image

```
ghcr.io/home-assistant/home-assistant:2026.3.2
```

Alternative registry: `homeassistant/home-assistant:2026.3.2` (Docker Hub)

The `ghcr.io` image is preferred as it is the canonical source. Pin to a specific version tag (e.g., `2026.3.2`) rather than `stable` or `latest` to ensure reproducible deployments. Update deliberately.

## Network Configuration

Home Assistant **requires host networking** for proper device discovery (mDNS, SSDP, UPnP, HomeKit). This is non-negotiable for full functionality.

| Setting | Value |
|---|---|
| Network Mode | `host` |
| Static IP | `192.168.62.60` (configured on the host interface/macvlan, not in Docker) |
| DNS Name | `home-assistant.lab.kemo.dev` |

Since host networking is used, the static IP `192.168.62.60` must be assigned at the host level (e.g., via a macvlan interface or a secondary IP on the bridge interface). Podman's `network_mode: host` shares the host's entire network stack.

### Ports (Host Network)

When using `network_mode: host`, all ports are exposed directly on the host. Key ports used by Home Assistant:

| Port | Protocol | Purpose |
|---|---|---|
| 8123 | TCP | Web UI / API |
| 5353 | UDP | mDNS (device discovery) |
| 1900 | UDP | SSDP/UPnP discovery |
| 21064 | TCP | HomeKit Bridge (if enabled) |
| 51827 | TCP | HomeKit Controller (if enabled) |

### Traefik Integration

Since Home Assistant runs on host networking with a static IP, Traefik should route to it via the static IP:

```
URL: https://home-assistant.lab.kemo.dev
Backend: http://192.168.62.60:8123
```

Home Assistant requires the `trusted_proxies` configuration in `configuration.yaml` to accept proxied connections:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.62.0/23
```

## Environment Variables

| Variable | Value | Description |
|---|---|---|
| `TZ` | `America/New_York` | Timezone (adjust as needed) |
| `DISABLE_JEMALLOC` | (unset) | Only set if memory issues arise |

Home Assistant configuration is primarily done via `configuration.yaml` inside the config volume, not environment variables.

## Storage / Volumes

| Host Path | Container Path | Purpose |
|---|---|---|
| `./config` | `/config` | Main configuration directory (YAML configs, database, automations, scripts, blueprints) |
| `/etc/localtime` | `/etc/localtime:ro` | Sync container time with host |
| `/run/dbus` | `/run/dbus:ro` | D-Bus access for Bluetooth and other host services |

### Storage Estimates

- **Config volume:** 500MB - 2GB typical (grows with database history)
- **SQLite database:** Can grow to several GB over time with recorder history
  - Consider offloading to an external PostgreSQL/MariaDB for large installations
- **Backups:** Home Assistant creates internal backups; plan for 1-5GB backup storage

## Resource Estimates

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 1 core | 2 cores |
| Memory | 512MB | 1-2GB |
| Storage | 1GB | 5-10GB |

Resource usage scales with the number of integrations, entities, and automations. A typical home setup with 50-200 entities will use ~500MB-1GB RAM.

## Dependencies

### MQTT Broker (Shared)

Home Assistant connects to the shared MQTT broker (Mosquitto) from `databases/{shared}`:

```yaml
# In Home Assistant configuration.yaml
mqtt:
  broker: <mqtt-broker-ip>
  port: 1883
  username: homeassistant
  password: <secret>
```

The MQTT integration is configured through the Home Assistant UI or `configuration.yaml`. It is used for:
- Zigbee2MQTT device integration
- Tasmota device communication
- ESPHome devices (optional, can also use native API)
- Custom sensor data ingestion

### Other Potential Dependencies

- **MariaDB/PostgreSQL** (optional): For the recorder component if SQLite performance is insufficient
- **InfluxDB** (optional): For long-term statistics storage
- **Scrypted** (`192.168.62.61`): Camera/NVR integration via HomeKit or direct plugin

## Special Considerations

### Device Access

For Zigbee/Z-Wave USB sticks or other hardware, device passthrough is required:

```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0   # Zigbee coordinator
  - /dev/ttyACM0:/dev/ttyACM0   # Z-Wave controller
```

If using Zigbee2MQTT as a separate service (recommended), the USB stick is passed to that container instead, and Home Assistant communicates via MQTT.

### Bluetooth

For Bluetooth device support, pass the D-Bus socket:

```yaml
volumes:
  - /run/dbus:/run/dbus:ro
```

The host must have BlueZ installed (`dnf install bluez`).

### Privileged Mode

While not strictly required, some integrations (Bluetooth, USB discovery) work more reliably with:

```yaml
privileged: true
```

Prefer passing specific devices and capabilities instead when possible.

### Security

- Home Assistant should be behind Traefik with TLS (StepCA ACME)
- Enable authentication (enabled by default on first setup)
- Configure `trusted_proxies` for Traefik reverse proxy
- Consider enabling MFA (TOTP) for admin accounts
- The `configuration.yaml` may contain secrets; use `secrets.yaml` for sensitive values

### Backup Strategy

Home Assistant has built-in backup functionality accessible from the UI. Backups include:
- Configuration files
- Automations, scripts, scenes
- Database (optional, can be large)
- Custom integrations

Store backups on a separate volume or sync to external storage.

## Startup Order

1. Shared MQTT broker must be running
2. (Optional) External database must be running if configured
3. Home Assistant container starts
4. Initial setup wizard runs on first boot at `http://192.168.62.60:8123`

## Docker Compose Skeleton

```yaml
services:
  home-assistant:
    image: ghcr.io/home-assistant/home-assistant:2026.3.2
    container_name: home-assistant
    restart: unless-stopped
    network_mode: host
    privileged: false
    environment:
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    # devices:
    #   - /dev/ttyUSB0:/dev/ttyUSB0
    #   - /dev/ttyACM0:/dev/ttyACM0
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```
