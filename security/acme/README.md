# StepCA - ACME Certificate Server

Smallstep's step-ca provides an internal ACME server for automated TLS certificate issuance. Traefik requests certificates from StepCA via the ACME protocol for all `*.lab.kemo.dev` services. Uses an intermediate CA certificate issued by PikaPKI.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set DOCKER_STEPCA_INIT_PASSWORD, DOCKER_STEPCA_INIT_DNS_NAMES

# Place the PikaPKI intermediate CA cert + key in the data volume
# (follow PikaPKI setup first)

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `DOCKER_STEPCA_INIT_NAME` | CA display name |
| `DOCKER_STEPCA_INIT_DNS_NAMES` | DNS SANs for the CA server |
| `DOCKER_STEPCA_INIT_ACME` | Enable ACME provisioner (`true`) |
| `DOCKER_STEPCA_INIT_PASSWORD` | CA password (used during initialization) |

After init, customize `./data/config/ca.json` for certificate duration, allowed SANs, and provisioner settings.

## Access

| URL | Purpose |
|-----|---------|
| `https://acme.lab.kemo.dev:9000` | CA server and ACME endpoint |
| ACME directory: `https://acme.lab.kemo.dev:9000/acme/acme/directory` | |

**Static IP:** 192.168.62.6

## Dependencies

- **PikaPKI** -- intermediate CA cert and key must be issued before StepCA can start
- **DNS** -- recommended for `acme.lab.kemo.dev` resolution

## Maintenance

```bash
# View logs
docker compose logs -f step-ca

# Check CA health
docker exec step-ca step ca health --ca-url https://localhost:9000 --root /home/step/certs/root_ca.crt

# Back up CA data (keys, config, database)
docker run --rm -v step-data:/data -v /path/to/backup:/backup alpine tar czf /backup/step-data.tar.gz /data

# Update image - pin to specific version, test before upgrading
docker compose pull && docker compose up -d
```

The `./data` volume contains CA private keys and the certificate database. Back it up securely.
