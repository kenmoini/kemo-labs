# StepCA - ACME Server

## Overview

Smallstep's `step-ca` provides an internal ACME server for automated TLS certificate issuance. Traefik will request certificates from StepCA via the ACME protocol for all `*.lab.kemo.network` services. StepCA uses an intermediate CA certificate issued by PikaPKI (the root of trust).

## Container Image

- **Image:** `smallstep/step-ca:0.28.3`
- **Tag policy:** Pin to minor version, update quarterly

## Static IP & DNS

- **IP:** 192.168.62.6
- **DNS:** `acme.lab.kemo.network`

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | TCP/HTTPS | CA server (ACME endpoint) |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DOCKER_STEPCA_INIT_NAME` | CA name | `Homelab CA` |
| `DOCKER_STEPCA_INIT_DNS_NAMES` | DNS SANs for the CA | `acme.lab.kemo.network,192.168.62.6` |
| `DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT` | Enable remote management | `true` |
| `DOCKER_STEPCA_INIT_ACME` | Enable ACME provisioner | `true` |
| `DOCKER_STEPCA_INIT_PASSWORD` | CA password (for init only) | (secret) |

## Storage / Volumes

| Mount | Purpose | Size Estimate |
|-------|---------|---------------|
| `./data:/home/step` | CA config, keys, certificates, database | 500 MB |

The `step` directory contains:
- `config/ca.json` - CA configuration
- `certs/` - CA certificates (intermediate + root)
- `secrets/` - Private keys (encrypted)
- `db/` - Badger database for certificate tracking

## Resource Estimates

| Resource | Idle | Peak |
|----------|------|------|
| CPU | 0.1 cores | 0.5 cores |
| RAM | 64 MB | 256 MB |

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| PikaPKI | **Required (bootstrap)** | Intermediate CA cert + key must be issued by PikaPKI before StepCA starts |
| DNS | Recommended | For `acme.lab.kemo.network` resolution |

## Network Configuration

- Runs on macvlan/ipvlan network with static IP 192.168.62.6
- Traefik connects to port 9000 for ACME challenges
- All services that need TLS will trust StepCA's root CA (PikaPKI root)

## Special Considerations

### Bootstrap Process
1. Deploy PikaPKI first and generate a root CA
2. Issue an intermediate CA certificate from PikaPKI for StepCA
3. Configure StepCA with the intermediate cert + key
4. Configure the ACME provisioner in `ca.json`
5. Distribute PikaPKI root CA to all clients/services that need to trust the chain

### ca.json Configuration
After initial bootstrap, customize `ca.json`:
- Set ACME provisioner with appropriate certificate duration (e.g., 90 days)
- Configure certificate renewal window
- Set allowed SANs to `*.lab.kemo.network` and the IP range
- Enable the admin provisioner for management via `step` CLI

### Traefik Integration
Traefik needs:
- `LEGO_CA_CERTIFICATES` pointing to PikaPKI root CA cert (for trusting StepCA)
- ACME `caServer` set to `https://acme.lab.kemo.network:9000/acme/acme/directory`
- Certificate resolver configured with `tlsChallenge` or `httpChallenge`

### Certificate Chain of Trust
```
PikaPKI Root CA
  └── StepCA Intermediate CA
        └── Service certificates (issued via ACME)
```

## Traefik Labels

StepCA itself can be behind Traefik for the web UI, but the ACME endpoint should also be directly accessible on port 9000 for reliability:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.step-ca.rule=Host(`acme.lab.kemo.network`)"
  - "traefik.http.routers.step-ca.tls=true"
  - "traefik.http.routers.step-ca.tls.certresolver=step-ca"
  - "traefik.http.services.step-ca.loadbalancer.server.port=9000"
  - "traefik.http.services.step-ca.loadbalancer.server.scheme=https"
```
