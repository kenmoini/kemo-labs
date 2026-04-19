# RustFS - S3-Compatible Object Storage

RustFS is a high-performance, S3-compatible object storage system built in Rust. It serves as the primary object storage backend for backups (Kopia), application data, and any workload needing an S3 endpoint.

## Quick Start

```bash
# Copy and edit environment file
cp .env.example .env
# Edit .env: set RUSTFS_ROOT_USER, RUSTFS_ROOT_PASSWORD (min 8 chars)

# Create data directory with correct ownership
mkdir -p ./data
sudo chown -R 10001:10001 ./data

docker compose up -d
```

## Configuration

| Variable | Purpose |
|----------|---------|
| `RUSTFS_ROOT_USER` | Admin username / S3 access key |
| `RUSTFS_ROOT_PASSWORD` | Admin password / S3 secret key (min 8 chars) |

## Access

| URL | Purpose |
|-----|---------|
| `https://s3.lab.kemo.dev` | S3 API endpoint |
| `https://s3-console.lab.kemo.dev` | Web management console |

**Static IP:** 192.168.42.20

## Dependencies

- **Traefik** -- reverse proxy and TLS termination
- **StepCA** -- ACME certificates via Traefik

Kopia (backups) depends on this service as its S3 backend.

## Maintenance

```bash
# View logs
docker compose logs -f rustfs

# Create a bucket using any S3 client
aws --endpoint-url https://s3.lab.kemo.dev s3 mb s3://my-bucket

# Check health
curl -f http://localhost:9000/minio/health/live

# Update image
docker compose pull && docker compose up -d
```

The container runs as UID 10001. All mounted host directories must be owned by `10001:10001`. The data volume should be on fast storage (SSD/NVMe) and sized for all S3 consumers (500 GB+).
