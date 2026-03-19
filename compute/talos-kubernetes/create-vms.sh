#\!/usr/bin/env bash
set -euo pipefail

###############################################################################
# create-vms.sh
# Creates all 6 Talos Kubernetes VMs using virt-install.
#
# Prerequisites:
#   - Run download-talos.sh first to obtain the ISO
#   - libvirt, qemu-kvm, virt-install installed
#   - br0 bridge interface configured
#   - UEFI firmware available
###############################################################################

TALOS_VERSION="${TALOS_VERSION:-v1.9.5}"
ISO_DIR="/var/lib/libvirt/images"
ISO_PATH="${ISO_DIR}/talos-${TALOS_VERSION}-metal-amd64.iso"
DISK_DIR="/var/lib/libvirt/images"

# Verify ISO exists
if [ \! -f "${ISO_PATH}" ]; then
  echo "ERROR: Talos ISO not found at ${ISO_PATH}"
  echo "       Run ./download-talos.sh first."
  exit 1
fi

###############################################################################
# Control Plane Nodes: 4 vCPU, 8 GB RAM, 50 GB disk
###############################################################################

declare -A CP_NODES=(
  [talos-cp1]="52:54:00:62:01:00"
  [talos-cp2]="52:54:00:62:01:01"
  [talos-cp3]="52:54:00:62:01:02"
)

for node in talos-cp1 talos-cp2 talos-cp3; do
  mac="${CP_NODES[$node]}"
  disk="${DISK_DIR}/${node}.qcow2"

  echo "==> Creating control plane node: ${node} (MAC: ${mac})"

  # Create OS disk
  if [ \! -f "${disk}" ]; then
    sudo qemu-img create -f qcow2 "${disk}" 50G
  else
    echo "    Disk ${disk} already exists, skipping creation."
  fi

  sudo virt-install \
    --name "${node}" \
    --ram 8192 \
    --vcpus 4 \
    --cpu host-passthrough \
    --os-variant generic \
    --disk "path=${disk},bus=virtio,cache=writeback" \
    --cdrom "${ISO_PATH}" \
    --network "bridge=br0,model=virtio,mac=${mac}" \
    --boot uefi \
    --graphics none \
    --console pty,target.type=serial \
    --noautoconsole

  echo "    ${node} created."
done

###############################################################################
# Worker Nodes: 6 vCPU, 16 GB RAM, 50 GB OS disk + 100 GB data disk
###############################################################################

declare -A W_NODES=(
  [talos-w1]="52:54:00:62:01:10"
  [talos-w2]="52:54:00:62:01:11"
  [talos-w3]="52:54:00:62:01:12"
)

for node in talos-w1 talos-w2 talos-w3; do
  mac="${W_NODES[$node]}"
  os_disk="${DISK_DIR}/${node}.qcow2"
  data_disk="${DISK_DIR}/${node}-data.qcow2"

  echo "==> Creating worker node: ${node} (MAC: ${mac})"

  # Create OS disk
  if [ \! -f "${os_disk}" ]; then
    sudo qemu-img create -f qcow2 "${os_disk}" 50G
  else
    echo "    OS disk ${os_disk} already exists, skipping creation."
  fi

  # Create data disk
  if [ \! -f "${data_disk}" ]; then
    sudo qemu-img create -f qcow2 "${data_disk}" 100G
  else
    echo "    Data disk ${data_disk} already exists, skipping creation."
  fi

  sudo virt-install \
    --name "${node}" \
    --ram 16384 \
    --vcpus 6 \
    --cpu host-passthrough \
    --os-variant generic \
    --disk "path=${os_disk},bus=virtio,cache=writeback" \
    --disk "path=${data_disk},bus=virtio,cache=writeback" \
    --cdrom "${ISO_PATH}" \
    --network "bridge=br0,model=virtio,mac=${mac}" \
    --boot uefi \
    --graphics none \
    --console pty,target.type=serial \
    --noautoconsole

  echo "    ${node} created."
done

echo ""
echo "==> All VMs created. They will boot into Talos maintenance mode."
echo "    Next steps:"
echo "      1. Run ./generate-configs.sh to generate Talos machine configs"
echo "      2. Run ./apply-configs.sh to apply configs to each node"
echo "      3. Run ./bootstrap.sh to bootstrap the cluster"
