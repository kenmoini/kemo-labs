#!/bin/bash
set -euo pipefail

# Bootstrap Talos Kubernetes Cluster
# Run this AFTER apply-configs.sh has been run on all nodes

CLUSTER_NAME="homelab"
CP1_IP="192.168.42.100"
VIP="192.168.42.99"
TALOSCTL="./talosctl"

echo "=== Bootstrapping Talos Kubernetes Cluster ==="

# Step 1: Bootstrap etcd on the first control plane node
echo "[1/4] Bootstrapping etcd on CP1 (${CP1_IP})..."
${TALOSCTL} bootstrap \
  --nodes ${CP1_IP} \
  --endpoints ${CP1_IP} \
  --talosconfig ./talosconfig

echo "[2/4] Waiting for cluster to become healthy..."
sleep 30

# Step 2: Wait for the cluster to be healthy
for i in $(seq 1 60); do
  if ${TALOSCTL} health \
    --nodes ${CP1_IP} \
    --endpoints ${CP1_IP} \
    --talosconfig ./talosconfig 2>/dev/null; then
    echo "Cluster is healthy!"
    break
  fi
  echo "  Attempt ${i}/60 - waiting 10s..."
  sleep 10
done

# Step 3: Retrieve kubeconfig
echo "[3/4] Retrieving kubeconfig..."
${TALOSCTL} kubeconfig \
  --nodes ${VIP} \
  --endpoints ${VIP} \
  --talosconfig ./talosconfig \
  -f ./kubeconfig

echo "[4/4] Verifying cluster access..."
export KUBECONFIG=./kubeconfig
if command -v kubectl &>/dev/null; then
  kubectl get nodes
  kubectl get pods -A
else
  echo "kubectl not found. Install it and run:"
  echo "  export KUBECONFIG=$(pwd)/kubeconfig"
  echo "  kubectl get nodes"
fi

echo ""
echo "=== Bootstrap Complete ==="
echo "Kubeconfig saved to: ./kubeconfig"
echo "Talosconfig saved to: ./talosconfig"
echo ""
echo "Next steps:"
echo "  export KUBECONFIG=$(pwd)/kubeconfig"
echo "  kubectl get nodes"
echo "  # Install CNI (if using Cilium instead of default Flannel)"
echo "  # Install local-path-provisioner for storage"
echo "  # Install MetalLB or similar for LoadBalancer services"
