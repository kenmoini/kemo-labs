#!/bin/bash
set -euo pipefail

# Destroy all Talos Kubernetes VMs and their storage
# WARNING: This is destructive and irreversible!

VM_PREFIX="talos"
STORAGE_POOL="default"

echo "=== Destroying Talos Kubernetes Cluster VMs ==="
echo "WARNING: This will permanently delete all VMs and their disks!"
read -p "Are you sure? (type 'yes' to confirm): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

# List of all VMs
VMS=(
  "${VM_PREFIX}-cp-1"
  "${VM_PREFIX}-cp-2"
  "${VM_PREFIX}-cp-3"
  "${VM_PREFIX}-w-1"
  "${VM_PREFIX}-w-2"
  "${VM_PREFIX}-w-3"
)

for VM in "${VMS[@]}"; do
  echo "Processing ${VM}..."

  # Check if VM exists
  if virsh dominfo "${VM}" &>/dev/null; then
    # Destroy (force stop) if running
    if virsh domstate "${VM}" | grep -q "running"; then
      echo "  Stopping ${VM}..."
      virsh destroy "${VM}" || true
    fi

    # Get disk paths before undefining
    DISKS=$(virsh domblklist "${VM}" --details | awk '/disk/ {print $4}')

    # Undefine the VM (remove UEFI vars too)
    echo "  Undefining ${VM}..."
    virsh undefine "${VM}" --nvram --remove-all-storage 2>/dev/null || \
    virsh undefine "${VM}" --nvram 2>/dev/null || \
    virsh undefine "${VM}" 2>/dev/null || true

    # Remove any remaining disk files
    for DISK in ${DISKS}; do
      if [ -f "${DISK}" ]; then
        echo "  Removing disk: ${DISK}"
        rm -f "${DISK}"
      fi
    done

    echo "  ${VM} destroyed."
  else
    echo "  ${VM} not found, skipping."
  fi
done

# Clean up generated configs
echo ""
echo "Cleaning up generated configuration files..."
rm -f talosconfig kubeconfig
rm -f controlplane.yaml worker.yaml

echo ""
echo "=== All Talos VMs destroyed ==="
echo "Note: Downloaded ISO and talosctl binary were NOT removed."
echo "To remove those too: rm -f talos-metal-*.iso talosctl"
