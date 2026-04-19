# Boot and Power Services - Netboot.xyz + NUT + PeaNUT

Provides network PXE boot capabilities via Netboot.xyz, UPS monitoring via NUT (Network UPS Tools), and a web dashboard for UPS status via PeaNUT.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set NUT_API_PASSWORD, UPS_DRIVER, UPS_NAME

# Ensure NUT config files exist in ./nut/config/

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `UPS_NAME` | UPS identifier (default: `homelab-ups`) |
| `UPS_DRIVER` | NUT driver for your UPS model (default: `usbhid-ups`) |
| `NUT_API_USER` | NUT API username (default: `admin`) |
| `NUT_API_PASSWORD` | NUT API password |
| `PUID` / `PGID` | User/group IDs for Netboot.xyz file permissions |

NUT requires configuration files in `./nut/config/` (`ups.conf`, `upsd.conf`, `upsd.users`).

## Access

| URL | Purpose |
|-----|---------|
| `https://netboot.lab.kemo.dev` | Netboot.xyz web configuration UI |
| `https://peanut.lab.kemo.dev` | PeaNUT UPS monitoring dashboard |
| `192.168.42.12:69/udp` | TFTP for PXE boot (direct, not proxied) |

## Dependencies

- **DNS** -- hostname resolution for web UIs
- **Traefik** -- reverse proxy for web UIs
- **DHCP server** -- must set `next-server` to 192.168.42.12 for PXE boot

## Maintenance

```bash
# View logs
docker compose logs -f

# Check UPS status
docker exec nut upsc homelab-ups@localhost

# Update images
docker compose pull && docker compose up -d

# Mirror boot assets locally via the Netboot.xyz web UI for faster PXE boots
```

The NUT container requires USB device passthrough (`/dev/bus/usb`) for UPS communication. Identify your UPS with `lsusb` on the host.
