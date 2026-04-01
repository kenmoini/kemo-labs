# S3 Object Store - RustFS

## Overview

RustFS is a high-performance, S3-compatible object storage system built in Rust. It serves as the primary object storage backend for the homelab, providing S3-compatible APIs for backups (Kopia), general file storage, application data, and any workload that needs an S3 endpoint. Licensed under Apache 2.0.

## Container Image

- **Image:** `rustfs/rustfs:1.0.0-alpha.88`
- **Alternative:** `rustfs/rustfs:latest`
- **Architectures:** linux/amd64, linux/arm64
- **Note:** Container runs as non-root user `rustfs` (UID `10001`). Host directories mounted with `-v` must be owned by UID 10001.

## Required Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | TCP | S3 API endpoint |
| 9001 | TCP | Web console (management UI) |

## Environment Variables

| Variable | Description | Default/Example |
|----------|-------------|-----------------|
| `RUSTFS_ROOT_USER` | Admin username (S3 access key) | `rustfsadmin` |
| `RUSTFS_ROOT_PASSWORD` | Admin password (S3 secret key) | Must be set, min 8 chars |
| `RUSTFS_BROWSER` | Enable/disable web console | `on` |
| `RUSTFS_VOLUMES` | Data directory path(s) | `/data` |

## Storage / Volume Requirements

| Mount Point | Purpose | Size Estimate | Notes |
|-------------|---------|---------------|-------|
| `/data` | Object data storage | 500GB+ (depends on usage) | Primary data volume. Must be owned by UID 10001. Use fast storage (SSD/NVMe) for performance. |
| `/logs` | Application logs | 1-5GB | Must be owned by UID 10001 |

### Storage Considerations

- **Erasure coding:** Single-node mode stores data directly. For production durability, ensure the underlying filesystem has redundancy (ZFS mirror, RAID, etc.).
- **Permissions:** Run `chown -R 10001:10001 data logs` on host directories before first start.
- **Capacity planning:** Size the data volume for all S3 consumers -- Kopia backups, application uploads, container image layers if used as a backing store, etc.
- **Filesystem:** XFS or ext4 recommended. ZFS with appropriate recordsize (128K-1M) works well for object storage.

## Resource Estimates

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2 cores |
| Memory | 512MB | 2GB |
| Disk (data) | 100GB | 500GB-2TB |
| Disk (logs) | 1GB | 5GB |

RustFS is built in Rust and is lightweight compared to Java-based alternatives. Memory usage scales with concurrent connections and object sizes.

## Dependencies

| Dependency | Type | Details |
|------------|------|---------|
| Traefik | Routing/TLS | Reverse proxy for HTTPS access to S3 API and console |
| StepCA | TLS | ACME certificates via Traefik |
| Podman network (macvlan) | Network | Static IP assignment |

No other storage workloads depend on this being up first, but Kopia (backups) requires this service as its S3 backend.

## Network Configuration

| Setting | Value |
|---------|-------|
| Static IP | `192.168.62.20` |
| DNS (S3 API) | `s3.lab.kemo.dev` |
| DNS (Console) | `s3-console.lab.kemo.dev` |
| Network | macvlan on 192.168.62.0/23 |

### Traefik Labels

- Route `s3.lab.kemo.dev` to port 9000 (S3 API)
- Route `s3-console.lab.kemo.dev` to port 9001 (Web UI)
- TLS via StepCA ACME resolver

## Special Considerations

1. **UID mapping:** The container uses UID 10001. All mounted host directories must be chowned to 10001:10001 before the first run or the container will fail with permission denied errors.

2. **S3 path-style vs virtual-hosted:** RustFS supports both. For homelab use, path-style (`s3.lab.kemo.dev/bucket/key`) is simpler and avoids wildcard DNS requirements.

3. **Bucket lifecycle:** Create dedicated buckets for each consumer (e.g., `kopia-backups`, `app-data`, `media`) to keep data organized and enable per-bucket policies.

4. **Backup strategy:** The S3 store itself should be backed up or replicated. Consider periodic snapshots of the underlying data volume to an external target.

5. **Client compatibility:** RustFS is S3-compatible. Use standard S3 clients (aws-cli, mc, s3cmd, any S3 SDK) to interact with it. The `mc` (MinIO Client) or `aws` CLI can be used for bucket creation and management.

6. **TLS for S3 API:** When Kopia and other internal services connect, they will use `https://s3.lab.kemo.dev` via Traefik. Ensure internal clients trust the StepCA root CA.

7. **Alpha status:** RustFS is currently at 1.0.0-alpha. Monitor releases and test upgrades carefully. Data format stability is not yet guaranteed across major versions.
