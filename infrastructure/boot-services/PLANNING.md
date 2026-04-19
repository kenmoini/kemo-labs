# Boot and Power Services - Netboot.xyz + NUT + PeaNUT

## Overview

This stack provides network boot capabilities for PXE-booting machines on the network, UPS monitoring for graceful shutdown during power events, and a web UI for UPS status. The three components are:

1. **Netboot.xyz** -- PXE boot server providing iPXE menus for OS installation and live environments over the network via TFTP and HTTP
2. **NUT (Network UPS Tools)** -- Monitors UPS hardware and provides status/alerts to other systems; enables graceful shutdowns on power loss
3. **PeaNUT** -- Modern web UI for NUT, providing a dashboard to view UPS status, battery levels, and power metrics

## Container Images

| Service | Image | Notes |
|---------|-------|-------|
| Netboot.xyz | `ghcr.io/netbootxyz/netbootxyz:latest` | Official image; Alpine-based with nginx, tftp-hpa, node.js webapp |
| NUT | `ghcr.io/networkupstools/upsd:latest` | Official NUT server image |
| PeaNUT | `brandawg93/peanut:latest` | NUT web UI |

## Static IP

- `192.168.42.12` (shared by all three services on different ports)

## Required Ports

### Netboot.xyz

| Port | Protocol | Purpose |
|------|----------|---------|
| 69 | UDP | TFTP (PXE boot file delivery) |
| 3000 | TCP | Web configuration interface |
| 8080 | TCP | Nginx asset server (boot files, ISOs) |

### NUT

| Port | Protocol | Purpose |
|------|----------|---------|
| 3493 | TCP | NUT server (upsd) protocol |

### PeaNUT

| Port | Protocol | Purpose |
|------|----------|---------|
| 8081 | TCP | Web UI |

## Environment Variables

### Netboot.xyz

| Variable | Purpose | Example |
|----------|---------|---------|
| `MENU_VERSION` | Specific boot menu version | `2.0.84` (or unset for latest) |
| `NGINX_PORT` | Internal Nginx port | `80` |
| `WEB_APP_PORT` | Internal webapp port | `3000` |
| `PUID` | User ID for volume permissions | `1000` |
| `PGID` | Group ID for volume permissions | `1000` |
| `TFTPD_OPTS` | TFTP daemon options | `--tftp-single-port` |

### NUT

| Variable | Purpose | Example |
|----------|---------|---------|
| `UPS_NAME` | Name of the UPS | `homelab-ups` |
| `UPS_DRIVER` | UPS driver to use | `usbhid-ups` (or model-specific) |
| `UPS_PORT` | UPS connection port | `auto` |
| `API_USER` | NUT API username | `admin` |
| `API_PASSWORD` | NUT API password | `<secret>` |

NUT is heavily config-file driven. Key files: `ups.conf`, `upsd.conf`, `upsd.users`, `upsmon.conf`.

### PeaNUT

| Variable | Purpose | Example |
|----------|---------|---------|
| `NUT_HOST` | NUT server hostname/IP | `192.168.42.12` |
| `NUT_PORT` | NUT server port | `3493` |
| `WEB_PORT` | PeaNUT web UI port | `8081` |

## Storage / Volume Requirements

### Netboot.xyz

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./netbootxyz/config/` | `/config` | Boot menu configs, boot.cfg |
| `./netbootxyz/assets/` | `/assets` | Downloaded boot assets (ISOs, kernels) |

**Note:** The assets volume can grow very large (tens of GB) if mirroring boot images locally.

### NUT

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./nut/config/` | `/etc/nut/` | NUT configuration files |
| `/dev/bus/usb` | `/dev/bus/usb` | USB device passthrough for UPS |

### PeaNUT

No persistent storage required (stateless web UI).

## Resource Estimates

| Service | CPU | RAM |
|---------|-----|-----|
| Netboot.xyz | 0.25 core | 128 MB |
| NUT | 0.1 core | 32 MB |
| PeaNUT | 0.1 core | 64 MB |
| **Total** | **0.45 core** | **224 MB** |

## Dependencies

| Dependency | Reason |
|------------|--------|
| DNS | Hostname resolution for `netboot.lab.kemo.dev`, `peanut.lab.kemo.dev` |
| Traefik | Reverse proxy for web UIs |
| DHCP server | Must configure `next-server` and `boot-file-name` pointing to 192.168.42.12 for PXE |

## Network Configuration

- Static IP `192.168.42.12` on the homelab macvlan/ipvlan network.
- TFTP (port 69/udp) must be directly accessible from PXE-booting clients; this cannot be reverse-proxied through Traefik.
- Web UIs (netboot.xyz webapp, PeaNUT) are exposed through Traefik as `netboot.lab.kemo.dev` and `peanut.lab.kemo.dev`.
- The DHCP server on the network must be configured with PXE options:
  - `next-server`: `192.168.42.12`
  - `boot-file-name`: `netboot.xyz.kpxe` (BIOS) or `netboot.xyz.efi` (UEFI)

### DHCP PXE Boot Configuration

For BIOS clients:
```
dhcp-match=set:bios,60,PXEClient:Arch:00000
dhcp-boot=tag:bios,netboot.xyz.kpxe,,192.168.42.12
```

For UEFI x86_64 clients:
```
dhcp-match=set:efi64,60,PXEClient:Arch:00007
dhcp-boot=tag:efi64,netboot.xyz.efi,,192.168.42.12
```

For UEFI ARM64 clients:
```
dhcp-match=set:efi64-3,60,PXEClient:Arch:0000B
dhcp-boot=tag:efi64-3,netboot.xyz-arm64.efi,,192.168.42.12
```

## Special Considerations

1. **USB passthrough for NUT:** The NUT container needs access to the UPS USB device. Use `--device /dev/bus/usb` or `privileged: true` (less secure). Identify the UPS USB device with `lsusb` and pass it specifically if possible.
2. **TFTP and firewalls:** TFTP uses UDP and can be problematic with firewalls. Ensure port 69/udp is open and consider using `--tftp-single-port` to avoid ephemeral port issues.
3. **Local asset mirroring:** For faster PXE boots, configure netboot.xyz to mirror assets locally by setting `live_endpoint` in `boot.cfg` to `http://192.168.42.12:8080`. Then download assets via the web UI.
4. **NUT driver selection:** The correct NUT driver depends on the UPS model. Common drivers: `usbhid-ups` (most USB UPS), `snmp-ups` (network UPS), `blazer_usb` (Megatec-protocol UPS).
5. **NUT client on host:** Consider also running `upsmon` on the Docker host itself so the host can initiate a graceful shutdown on low battery, independent of the container.
6. **PeaNUT is read-only:** PeaNUT is a monitoring UI only. UPS commands (shutdown, test) are issued via NUT's `upscmd` or API.
