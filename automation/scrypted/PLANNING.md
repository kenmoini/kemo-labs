# Scrypted - Planning

## Overview

Scrypted is a smart home camera and device management platform focused on low-latency video streaming and smart detection (motion, person, vehicle, animal). It serves as a bridge between IP cameras and home automation platforms, providing HomeKit Secure Video (HKSV), Google Home, Alexa, and direct Home Assistant integration. Scrypted handles camera restreaming, hardware-accelerated video transcoding, and AI-based object detection.

- **Documentation:** https://docs.scrypted.app/
- **Docker Installation:** https://docs.scrypted.app/install/linux-docker.html
- **Source:** https://github.com/koush/scrypted

## Container Image

```
ghcr.io/koush/scrypted:latest
```

Scrypted does not publish semver-tagged releases; `latest` is the standard stable tag. Variant images are available for hardware acceleration:

| Image | Use Case |
|---|---|
| `ghcr.io/koush/scrypted` | Default (CPU-only transcoding) |
| `ghcr.io/koush/scrypted:nvidia` | NVIDIA GPU acceleration |
| `ghcr.io/koush/scrypted:intel` | Intel Quick Sync Video (QSV) acceleration |
| `ghcr.io/koush/scrypted:lite` | Minimal install without bundled plugins |

For a homelab server, use the default image unless the host has an NVIDIA or Intel GPU available for transcoding.

## Network Configuration

Scrypted **requires host networking** for camera discovery (ONVIF, mDNS) and low-latency video streaming. This is the officially recommended configuration.

| Setting | Value |
|---|---|
| Network Mode | `host` |
| Static IP | `192.168.62.61` (configured on the host interface/macvlan, not in Docker) |
| DNS Name | `scrypted.lab.kemo.dev` |

Since host networking is used, the static IP `192.168.62.61` must be assigned at the host level (e.g., via a macvlan interface or a secondary IP on the bridge interface).

### Ports (Host Network)

With `network_mode: host`, all ports are directly on the host. Key ports:

| Port | Protocol | Purpose |
|---|---|---|
| 10443 | TCP | Scrypted Web UI (HTTPS) |
| 11080 | TCP | Scrypted Web UI (HTTP) |
| 10444 | TCP | Watchtower auto-update webhook |
| 5353 | UDP | mDNS (device/camera discovery) |
| Various | TCP/UDP | RTSP/RTMP restream ports (dynamically assigned per camera) |

### Traefik Integration

Route Traefik to the Scrypted web UI via the static IP:

```
URL: https://scrypted.lab.kemo.dev
Backend: https://192.168.62.61:10443 (or http://192.168.62.61:11080)
```

Scrypted generates its own self-signed certificate on port 10443. When proxying through Traefik, configure the backend as insecureSkipVerify or use the HTTP port (11080).

## Environment Variables

| Variable | Value | Description |
|---|---|---|
| `SCRYPTED_WEBHOOK_UPDATE_AUTHORIZATION` | `Bearer <token>` | Auth token for Watchtower update webhook |
| `SCRYPTED_WEBHOOK_UPDATE` | `http://localhost:10444/v1/update` | Watchtower update endpoint |
| `SCRYPTED_NVR_VOLUME` | `/nvr` | (Optional) NVR recording storage path inside container |
| `SCRYPTED_DOCKER_AVAHI` | `true` | (Optional) Run avahi-daemon inside container for mDNS |

Most Scrypted configuration is done through the web UI, not environment variables.

## Storage / Volumes

| Host Path | Container Path | Purpose |
|---|---|---|
| `./volume` | `/server/volume` | Scrypted database, plugins, and configuration |
| `/mnt/nvr` (optional) | `/nvr` | NVR recording storage (large, dedicated disk recommended) |
| `/var/run/dbus` | `/var/run/dbus` | (Optional) Host Avahi daemon access for mDNS |
| `/var/run/avahi-daemon/socket` | `/var/run/avahi-daemon/socket` | (Optional) Avahi socket for discovery |

### Storage Estimates

- **Configuration volume:** 100MB - 500MB (plugins, database, thumbnails)
- **NVR recordings:** Highly variable; plan for 500GB - 2TB+ depending on:
  - Number of cameras
  - Resolution and frame rate
  - Retention period (7 days, 30 days, etc.)
  - Motion-only vs. continuous recording
- A single 1080p camera recording 24/7 at moderate quality uses approximately 10-20GB/day

## Resource Estimates

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores |
| Memory | 1GB | 2-4GB |
| Storage (config) | 500MB | 1GB |
| Storage (NVR) | 100GB | 500GB-2TB |

Resource usage scales primarily with:
- Number of cameras being managed
- Whether hardware transcoding is available (CPU usage drops dramatically with GPU)
- AI object detection (CPU-intensive without dedicated hardware like Coral TPU)
- Number of concurrent video streams

## Dependencies

### Home Assistant Integration

Scrypted integrates with Home Assistant in two primary ways:

1. **HomeKit Bridge**: Scrypted exposes cameras as HomeKit accessories, and Home Assistant's HomeKit Controller integration discovers them automatically (both on host network, mDNS works natively).

2. **Scrypted NVR Plugin for HA**: A custom integration installable via HACS that provides direct camera feeds, NVR timeline, and detection events in the Home Assistant UI.

### Watchtower (Auto-Updates)

The official Scrypted deployment includes a dedicated Watchtower instance for automatic updates. This is a sidecar container:

```yaml
watchtower:
  image: nickfedor/watchtower
  container_name: scrypted-watchtower
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  ports:
    - 10444:8080
  command: --interval 3600 --cleanup --scope scrypted
```

This Watchtower instance is scoped to only update the Scrypted container (via label `com.centurylinklabs.watchtower.scope=scrypted`). It will not interfere with other containers.

### MQTT (Optional)

Scrypted can optionally publish events to MQTT for integration with other systems. If used, it connects to the shared MQTT broker from `databases/{shared}`.

## Special Considerations

### Device Passthrough

For hardware-accelerated video processing and USB devices, pass the appropriate devices:

```yaml
devices:
  # GPU for hardware-accelerated transcoding
  - /dev/dri:/dev/dri               # Intel/AMD GPU (VA-API, QSV)

  # USB devices
  - /dev/bus/usb:/dev/bus/usb        # All USB devices (Coral TPU, etc.)

  # Google Coral TPU (PCI)
  # - /dev/apex_0:/dev/apex_0
  # - /dev/apex_1:/dev/apex_1

  # AMD GPU
  # - /dev/kfd:/dev/kfd
```

### Hardware Acceleration

For a Fedora host, check available GPU/video hardware:

```bash
# Check for Intel GPU (VA-API)
ls /dev/dri/

# Check for NVIDIA GPU
nvidia-smi

# Check for Coral TPU
lsusb | grep -i google
ls /dev/apex_*
```

If the host has an Intel iGPU or discrete GPU, passing `/dev/dri` is strongly recommended to reduce CPU usage during video transcoding.

### NVIDIA GPU Setup

If using an NVIDIA GPU:
1. Install NVIDIA Container Toolkit on the host
2. Use the `ghcr.io/koush/scrypted:nvidia` image
3. Add `runtime: nvidia` to the compose service

### Logging

Scrypted's default Docker Compose disables Docker logging (`driver: "none"`) because Scrypted has its own in-memory per-device logging accessible from the web UI. This is intentional to reduce disk I/O. Override with `json-file` driver only if you need persistent Docker-level logs for debugging.

### Security

- Scrypted should be behind Traefik with TLS (StepCA ACME)
- Scrypted has built-in authentication (configured during first setup)
- Camera credentials are stored in Scrypted's encrypted database
- The Podman socket is exposed to the Watchtower sidecar only (scoped)

### Avahi / mDNS Discovery

For camera and HomeKit discovery, mDNS must work. With host networking this generally works out of the box. If mDNS issues arise:

1. **Option A (recommended):** Install and run `avahi-daemon` on the Fedora host (`dnf install avahi`), then mount the sockets into the container
2. **Option B:** Set `SCRYPTED_DOCKER_AVAHI=true` to run avahi inside the container (may conflict with host avahi)

### DNS Configuration

The official compose file sets custom DNS servers (1.1.1.1, 8.8.8.8) to avoid issues with local DNS resolvers when Scrypted downloads npm packages. For this homelab, these can be overridden to use the local DNS if it is reliable:

```yaml
dns:
  - 192.168.62.1    # Local DNS
  - 1.1.1.1          # Fallback
```

## Startup Order

1. (Optional) MQTT broker running if MQTT plugin is used
2. Scrypted container starts
3. Scrypted Watchtower sidecar starts
4. Initial setup wizard at `https://192.168.62.61:10443`
5. Add cameras and configure plugins through the web UI
6. Configure Home Assistant integration (HomeKit Bridge or HACS plugin)

## Podman Compose Skeleton

```yaml
services:
  scrypted:
    image: ghcr.io/koush/scrypted
    container_name: scrypted
    restart: unless-stopped
    network_mode: host
    environment:
      - SCRYPTED_WEBHOOK_UPDATE_AUTHORIZATION=Bearer ${WATCHTOWER_HTTP_API_TOKEN}
      - SCRYPTED_WEBHOOK_UPDATE=http://localhost:10444/v1/update
      # - SCRYPTED_NVR_VOLUME=/nvr
    volumes:
      - ./volume:/server/volume
      # - /mnt/nvr:/nvr
    devices:
      - /dev/dri:/dev/dri
      # - /dev/bus/usb:/dev/bus/usb
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      - "com.centurylinklabs.watchtower.scope=scrypted"
    dns:
      - 1.1.1.1
      - 8.8.8.8

  scrypted-watchtower:
    image: nickfedor/watchtower
    container_name: scrypted-watchtower
    restart: unless-stopped
    environment:
      - WATCHTOWER_HTTP_API_TOKEN=${WATCHTOWER_HTTP_API_TOKEN}
      - WATCHTOWER_HTTP_API_UPDATE=true
      - WATCHTOWER_SCOPE=scrypted
      - WATCHTOWER_HTTP_API_PERIODIC_POLLS=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 10444:8080
    command: --interval 3600 --cleanup --scope scrypted
    labels:
      - "com.centurylinklabs.watchtower.scope=scrypted"
    dns:
      - 1.1.1.1
      - 8.8.8.8
```
