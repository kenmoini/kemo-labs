# Talos Kubernetes Cluster

A 6-node Kubernetes cluster (3 control plane + 3 worker) running Talos Linux on KVM/libvirt VMs. Talos provides an immutable, API-driven Kubernetes distribution. This is the sole KVM workload in the homelab -- all other services run as Docker containers.

## Quick Start

```bash
# 1. Download Talos image
./download-talos.sh

# 2. Create VMs (3 control plane + 3 workers)
./create-vms.sh

# 3. Generate Talos configs
./generate-configs.sh

# 4. Apply configs to each node
./apply-configs.sh

# 5. Bootstrap the cluster
./bootstrap.sh

# 6. Verify
kubectl get nodes -o wide
```

## Configuration

Node inventory:

| Node | IP | Role | vCPU | RAM |
|------|----|------|------|-----|
| talos-cp1 | 192.168.62.100 | Control Plane | 4 | 8 GB |
| talos-cp2 | 192.168.62.101 | Control Plane | 4 | 8 GB |
| talos-cp3 | 192.168.62.102 | Control Plane | 4 | 8 GB |
| talos-w1 | 192.168.62.110 | Worker | 6 | 16 GB |
| talos-w2 | 192.168.62.111 | Worker | 6 | 16 GB |
| talos-w3 | 192.168.62.112 | Worker | 6 | 16 GB |

**API VIP:** 192.168.62.99 (`talos-api.lab.kemo.network`)

Per-node patches are in `./patches/` for static IP, hostname, and VIP configuration.

## Access

| Address | Purpose |
|---------|---------|
| `https://192.168.62.99:6443` | Kubernetes API |
| `talosctl` CLI | Node management (no SSH -- Talos is immutable) |

## Dependencies

- **DNS** -- A records for all nodes and the API VIP
- **Host prerequisites:** `libvirt`, `qemu-kvm`, `virt-install`, bridge interface `br0`
- **Client tools:** `talosctl`, `kubectl`

## Maintenance

```bash
# Check cluster health
talosctl health

# View node logs
talosctl logs -n 192.168.62.100

# Interactive node dashboard
talosctl dashboard -n 192.168.62.100

# Upgrade Talos (rolling, one node at a time)
talosctl upgrade --nodes 192.168.62.100 \
  --image ghcr.io/siderolabs/installer:v1.9.5

# Snapshot VMs before upgrades
virsh snapshot-create-as talos-cp1 pre-upgrade

# Back up cluster secrets
talosctl etcd snapshot /path/to/backup/etcd.snapshot

# Tear down cluster
./destroy-vms.sh
```

Talos has no SSH, no shell, no package manager. All management is via `talosctl`. Worker nodes each have a 100 GB data disk for future distributed storage (Longhorn or Rook-Ceph). Total cluster footprint: 30 vCPU, 72 GB RAM.
