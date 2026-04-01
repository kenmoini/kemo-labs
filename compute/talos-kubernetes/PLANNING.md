# Talos Kubernetes Cluster - Planning

## Overview

This is the sole KVM/Libvirt workload in the homelab. All other services run as Docker containers on the Fedora host. Talos Linux provides an immutable, API-driven Kubernetes distribution purpose-built for running in VMs or on bare metal. The cluster will run on 6 libvirt VMs (3 control plane + 3 worker) bridged directly onto the lab network.

**Purpose:** Provide a production-style Kubernetes cluster for workloads that benefit from k8s orchestration -- stateful apps with operators, Helm-based deployments, CI/CD runners, and anything that does not fit neatly into Docker Compose.

**Reference:** https://oneuptime.com/blog/post/2026-03-03-configure-talos-linux-on-libvirt-kvm/view

---

## VM Specifications

Given the host has 128GB+ RAM and 32+ cores, the following allocation dedicates roughly half the host resources to the Kubernetes cluster while leaving ample headroom for Docker workloads and the host OS.

| Role | Count | vCPU | RAM | OS Disk | Data Disk | Total per Role |
|------|-------|------|-----|---------|-----------|----------------|
| Control Plane | 3 | 4 | 8 GB | 50 GB (qcow2) | -- | 12 vCPU, 24 GB RAM |
| Worker | 3 | 6 | 16 GB | 50 GB (qcow2) | 100 GB (qcow2) | 18 vCPU, 48 GB RAM |
| **Cluster Total** | **6** | -- | -- | -- | -- | **30 vCPU, 72 GB RAM** |

**Notes on sizing vs. the reference blog:**
- The blog uses 2 vCPU / 4 GB for control plane and 4 vCPU / 8 GB for workers. Those are minimal values.
- With 128 GB+ and 32+ cores available, the above sizing gives the cluster room to run real workloads (monitoring stacks, databases with operators, CI runners) without starving.
- Adjust downward if the Docker side needs more resources. The minimum viable control plane is 2 vCPU / 4 GB per node.

---

## Node Inventory and Network

### IP Assignments

All nodes are bridged onto the existing 192.168.62.0/23 lab network. Static IPs are configured via Talos machine config (not DHCP).

| Node | Hostname | FQDN | IP Address | MAC Address |
|------|----------|------|------------|-------------|
| CP1 | talos-cp1 | talos-cp1.lab.kemo.dev | 192.168.62.100 | 52:54:00:62:01:00 |
| CP2 | talos-cp2 | talos-cp2.lab.kemo.dev | 192.168.62.101 | 52:54:00:62:01:01 |
| CP3 | talos-cp3 | talos-cp3.lab.kemo.dev | 192.168.62.102 | 52:54:00:62:01:02 |
| W1 | talos-w1 | talos-w1.lab.kemo.dev | 192.168.62.110 | 52:54:00:62:01:10 |
| W2 | talos-w2 | talos-w2.lab.kemo.dev | 192.168.62.111 | 52:54:00:62:01:11 |
| W3 | talos-w3 | talos-w3.lab.kemo.dev | 192.168.62.112 | 52:54:00:62:01:12 |

### Control Plane VIP

| Purpose | FQDN | IP Address |
|---------|------|------------|
| Kubernetes API VIP | talos-api.lab.kemo.dev | 192.168.62.99 |

The VIP floats between control plane nodes using Talos's built-in VIP support. No external load balancer is needed.

### Network Architecture

- **Bridge mode:** VMs attach to the host's existing bridge interface (e.g., `br0`) that is already on the 192.168.62.0/23 network. This is NOT a libvirt NAT network -- the VMs are first-class citizens on the lab LAN.
- **Gateway:** 192.168.62.1 (or whatever the lab network gateway is)
- **DNS:** Handled by the lab's DNS infrastructure (Pi-hole / CoreDNS in the infrastructure stack)
- **Subnet mask:** 255.255.254.0 (/23)

---

## Talos Linux Version and Image

### Version

Use the latest stable Talos release. As of the reference blog, v1.7.0 was current. Check https://github.com/siderolabs/talos/releases for the latest stable version at deployment time.

### Image Download

```bash
# Set the desired version
export TALOS_VERSION="v1.9.5"

# Download the metal image for KVM/libvirt (raw disk image)
curl -LO "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/metal-amd64.raw.xz"
xz -d metal-amd64.raw.xz

# Place in libvirt images directory
sudo mv metal-amd64.raw /var/lib/libvirt/images/talos-${TALOS_VERSION}.raw
```

**Alternative: ISO boot.** You can also use the ISO image for initial boot, then apply the machine config. The raw disk image with qcow2 overlay (backing file approach) is more efficient for multiple VMs.

---

## VM Provisioning

### Approach: Shell Scripts with virt-install

For a homelab, shell scripts calling `virt-install` are the simplest and most transparent approach. A Terraform option using the `dmacvicar/libvirt` provider is a future enhancement.

### Disk Creation

```bash
export TALOS_VERSION="v1.9.5"

# Control plane disks -- 50 GB each, backed by base image
for node in cp1 cp2 cp3; do
  sudo qemu-img create -f qcow2 \
    -b /var/lib/libvirt/images/talos-${TALOS_VERSION}.raw -F raw \
    /var/lib/libvirt/images/talos-${node}.qcow2 50G
done

# Worker disks -- 50 GB OS + 100 GB data disk for storage
for node in w1 w2 w3; do
  sudo qemu-img create -f qcow2 \
    -b /var/lib/libvirt/images/talos-${TALOS_VERSION}.raw -F raw \
    /var/lib/libvirt/images/talos-${node}.qcow2 50G
  sudo qemu-img create -f qcow2 \
    /var/lib/libvirt/images/talos-${node}-data.qcow2 100G
done
```

### VM Creation (virt-install)

All VMs use bridged networking to `br0` (the host bridge on the 192.168.62.0/23 network), UEFI boot, and virtio for disk and network.

```bash
# Control Plane Nodes
declare -A CP_MACS=(
  [cp1]="52:54:00:62:01:00"
  [cp2]="52:54:00:62:01:01"
  [cp3]="52:54:00:62:01:02"
)

for node in cp1 cp2 cp3; do
  sudo virt-install \
    --name talos-${node} \
    --ram 8192 \
    --vcpus 4 \
    --cpu host-passthrough \
    --os-variant generic \
    --disk path=/var/lib/libvirt/images/talos-${node}.qcow2,bus=virtio,cache=writeback \
    --network bridge=br0,model=virtio,mac=${CP_MACS[$node]} \
    --boot uefi \
    --graphics none \
    --console pty,target.type=serial \
    --noautoconsole \
    --import
done

# Worker Nodes
declare -A W_MACS=(
  [w1]="52:54:00:62:01:10"
  [w2]="52:54:00:62:01:11"
  [w3]="52:54:00:62:01:12"
)

for node in w1 w2 w3; do
  sudo virt-install \
    --name talos-${node} \
    --ram 16384 \
    --vcpus 6 \
    --cpu host-passthrough \
    --os-variant generic \
    --disk path=/var/lib/libvirt/images/talos-${node}.qcow2,bus=virtio,cache=writeback \
    --disk path=/var/lib/libvirt/images/talos-${node}-data.qcow2,bus=virtio,cache=writeback \
    --network bridge=br0,model=virtio,mac=${W_MACS[$node]} \
    --boot uefi \
    --graphics none \
    --console pty,target.type=serial \
    --noautoconsole \
    --import
done
```

---

## Talos Configuration and Bootstrap

### Step 1: Generate Cluster Config

```bash
# Generate configs targeting the VIP as the API endpoint
talosctl gen config talos-lab https://192.168.62.99:6443 \
  --output-dir _out \
  --with-docs=false \
  --with-examples=false
```

This produces:
- `_out/controlplane.yaml` -- machine config for control plane nodes
- `_out/worker.yaml` -- machine config for worker nodes
- `_out/talosconfig` -- client config for talosctl

### Step 2: Patch Machine Configs

Each node needs a per-node patch for its static IP, hostname, and (for control plane) the VIP. Create patch files:

**Control plane patch (per-node example for cp1):**

```yaml
# patch-cp1.yaml
machine:
  network:
    hostname: talos-cp1
    interfaces:
      - interface: eth0
        addresses:
          - 192.168.62.100/23
        routes:
          - network: 0.0.0.0/0
            gateway: 192.168.62.1
        vip:
          ip: 192.168.62.99
    nameservers:
      - 192.168.62.1
  install:
    disk: /dev/vda
```

**Worker patch (per-node example for w1):**

```yaml
# patch-w1.yaml
machine:
  network:
    hostname: talos-w1
    interfaces:
      - interface: eth0
        addresses:
          - 192.168.62.110/23
        routes:
          - network: 0.0.0.0/0
            gateway: 192.168.62.1
    nameservers:
      - 192.168.62.1
  install:
    disk: /dev/vda
```

### Step 3: Apply Configs

```bash
# Apply to control plane nodes (--insecure because they have no config yet)
talosctl apply-config --insecure --nodes 192.168.62.100 \
  --config-patch @patch-cp1.yaml --file _out/controlplane.yaml

talosctl apply-config --insecure --nodes 192.168.62.101 \
  --config-patch @patch-cp2.yaml --file _out/controlplane.yaml

talosctl apply-config --insecure --nodes 192.168.62.102 \
  --config-patch @patch-cp3.yaml --file _out/controlplane.yaml

# Apply to worker nodes
talosctl apply-config --insecure --nodes 192.168.62.110 \
  --config-patch @patch-w1.yaml --file _out/worker.yaml

talosctl apply-config --insecure --nodes 192.168.62.111 \
  --config-patch @patch-w2.yaml --file _out/worker.yaml

talosctl apply-config --insecure --nodes 192.168.62.112 \
  --config-patch @patch-w3.yaml --file _out/worker.yaml
```

**Note on initial IP assignment:** Before configs are applied, the VMs will boot into Talos maintenance mode. They will get a DHCP address from the network if DHCP is available, or you can connect via the console to identify the initial IP. Once the config is applied, the node reboots with its static IP.

### Step 4: Bootstrap

```bash
# Configure talosctl to use the VIP endpoint
talosctl config endpoint 192.168.62.99
talosctl config node 192.168.62.100

# Bootstrap etcd on the first control plane node
talosctl bootstrap

# Wait for the cluster to come up (watch node status)
talosctl health --wait-timeout 10m

# Retrieve kubeconfig
talosctl kubeconfig --force -n 192.168.62.99
```

### Step 5: Verify

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

---

## Storage Strategy

### Primary: Local Path Provisioner

For most workloads, local-path-provisioner (from Rancher) is simple and fast. It provisions PVs on the node's local disk.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### Future: Longhorn or Rook-Ceph

The worker nodes each have a dedicated 100 GB data disk (`/dev/vdb`) specifically for distributed storage. Options:

- **Longhorn:** Lightweight, Kubernetes-native distributed block storage. Good for a homelab. Uses the data disks directly.
- **Rook-Ceph:** More complex but feature-rich (block, file, object storage). Overkill for most homelab use cases but valuable for learning.

**Recommendation:** Start with local-path-provisioner, add Longhorn later when replicated storage is needed. The data disks are pre-provisioned and ready for either.

---

## Dependencies

### DNS Records Required

The following DNS records must exist in the `lab.kemo.dev` zone before or at deployment time:

| Record | Type | Value |
|--------|------|-------|
| talos-cp1.lab.kemo.dev | A | 192.168.62.100 |
| talos-cp2.lab.kemo.dev | A | 192.168.62.101 |
| talos-cp3.lab.kemo.dev | A | 192.168.62.102 |
| talos-w1.lab.kemo.dev | A | 192.168.62.110 |
| talos-w2.lab.kemo.dev | A | 192.168.62.111 |
| talos-w3.lab.kemo.dev | A | 192.168.62.112 |
| talos-api.lab.kemo.dev | A | 192.168.62.99 |

A wildcard record for ingress is also useful:

| Record | Type | Value |
|--------|------|-------|
| *.apps.lab.kemo.dev | A | 192.168.62.99 (or a dedicated ingress VIP) |

### Host Prerequisites

On the Fedora host:
- `libvirt`, `qemu-kvm`, `virt-install` installed (`sudo dnf install @virtualization`)
- `libvirtd` enabled and running
- A bridge interface `br0` configured on the 192.168.62.0/23 network
- UEFI firmware available (`/usr/share/edk2/ovmf/OVMF_CODE.fd` on Fedora)

### Client Tools

On the management machine (can be the host itself):
- `talosctl` -- https://www.talos.dev/latest/talos-guides/install/talosctl/
- `kubectl` -- https://kubernetes.io/docs/tasks/tools/

### PKI / Trust

- Talos generates its own PKI (etcd CA, Kubernetes CA, etc.) during `talosctl gen config`. The generated `talosconfig` contains the client credentials.
- If the lab has a custom CA (e.g., PikaPKI), you can inject additional trusted CAs into the Talos machine config under `machine.registries.config` or `machine.files` for services that need to trust internal certificates.

---

## Special Considerations

### Immutable OS

Talos has no SSH, no shell, no package manager. All management is via `talosctl` and the Talos API. This is by design. Plan accordingly:
- Debugging is done via `talosctl logs`, `talosctl dmesg`, `talosctl dashboard`
- Upgrades are done via `talosctl upgrade --image ghcr.io/siderolabs/installer:<version>`
- Config changes are applied via `talosctl apply-config` or `talosctl patch`

### Upgrades

Talos upgrades are rolling and non-disruptive:
```bash
# Upgrade each node one at a time
talosctl upgrade --nodes 192.168.62.100 \
  --image ghcr.io/siderolabs/installer:v1.9.5
```

### Snapshots and Backups

- Use `virsh snapshot-create-as` before upgrades for quick rollback at the VM level
- Back up the `_out/` directory (talosconfig, controlplane.yaml, worker.yaml) -- these contain cluster secrets
- Consider etcd snapshots via `talosctl etcd snapshot`

### Resource Tuning

- `--cpu host-passthrough` gives VMs direct access to the host CPU features (important for performance)
- Disk cache mode `writeback` improves I/O at the cost of durability (acceptable for a homelab with UPS)
- If RAM is tight, control plane nodes can run with 4 GB minimum; workers with 8 GB minimum

### Cluster Networking (CNI)

Talos defaults to Flannel as the CNI. Alternatives to consider:
- **Cilium:** eBPF-based, more features (network policies, observability, service mesh). Can be configured during `talosctl gen config` with `--config-patch`.
- Flannel is fine for a homelab unless you specifically want Cilium features.

### What Goes on Kubernetes vs. Docker

Not everything needs to run on Kubernetes. Use k8s for:
- Workloads that benefit from Helm charts or operators (databases with failover, monitoring stacks)
- Multi-replica services
- Workloads you want to learn k8s patterns with

Keep on Docker Compose:
- Simple single-instance services (Pi-hole, Traefik, Home Assistant, etc.)
- Services that need direct host access (Scrypted, Scrutiny)

---

## File Structure (Planned)

```
compute/talos-kubernetes/
  PLANNING.md              # This file
  scripts/
    download-image.sh      # Download and prepare Talos image
    create-vms.sh          # Create all VMs via virt-install
    destroy-vms.sh         # Tear down all VMs
  talos/
    gen-config.sh           # Generate and patch Talos configs
    patch-cp1.yaml          # Per-node machine config patches
    patch-cp2.yaml
    patch-cp3.yaml
    patch-w1.yaml
    patch-w2.yaml
    patch-w3.yaml
  README.md                 # Operational runbook (after implementation)
```
