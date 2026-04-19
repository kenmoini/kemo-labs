#\!/usr/bin/env bash
set -euo pipefail

###############################################################################
# apply-configs.sh
# Applies Talos machine configs with per-node patches to all nodes.
#
# Nodes must be booted into Talos maintenance mode (from the ISO) and
# reachable on the network. Before static IPs are applied, nodes will
# have DHCP addresses -- you may need to identify those first.
#
# If nodes already have DHCP addresses from maintenance mode, set the
# environment variables below or pass IPs as arguments.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/_out"
PATCH_DIR="${SCRIPT_DIR}/patches"

# Verify configs exist
if [ \! -f "${CONFIG_DIR}/controlplane.yaml" ]; then
  echo "ERROR: ${CONFIG_DIR}/controlplane.yaml not found."
  echo "       Run ./generate-configs.sh first."
  exit 1
fi

# Target IPs -- these are the static IPs the nodes will receive.
# In maintenance mode, nodes may have different (DHCP) addresses.
# Override with environment variables if needed:
#   CP1_IP=192.168.42.50 ./apply-configs.sh
CP1_IP="${CP1_IP:-192.168.42.100}"
CP2_IP="${CP2_IP:-192.168.42.101}"
CP3_IP="${CP3_IP:-192.168.42.102}"
W1_IP="${W1_IP:-192.168.42.110}"
W2_IP="${W2_IP:-192.168.42.111}"
W3_IP="${W3_IP:-192.168.42.112}"

echo "==> Applying Talos configs"
echo ""
echo "    Control plane nodes:"
echo "      cp1: ${CP1_IP} (patch: cp-1.yaml)"
echo "      cp2: ${CP2_IP} (patch: cp-2.yaml)"
echo "      cp3: ${CP3_IP} (patch: cp-3.yaml)"
echo ""
echo "    Worker nodes:"
echo "      w1:  ${W1_IP} (patch: worker-1.yaml)"
echo "      w2:  ${W2_IP} (patch: worker-2.yaml)"
echo "      w3:  ${W3_IP} (patch: worker-3.yaml)"
echo ""

###############################################################################
# Apply to control plane nodes
###############################################################################
echo "==> Applying config to talos-cp1 at ${CP1_IP} ..."
talosctl apply-config --insecure \
  --nodes "${CP1_IP}" \
  --config-patch @"${PATCH_DIR}/cp-1.yaml" \
  --file "${CONFIG_DIR}/controlplane.yaml"

echo "==> Applying config to talos-cp2 at ${CP2_IP} ..."
talosctl apply-config --insecure \
  --nodes "${CP2_IP}" \
  --config-patch @"${PATCH_DIR}/cp-2.yaml" \
  --file "${CONFIG_DIR}/controlplane.yaml"

echo "==> Applying config to talos-cp3 at ${CP3_IP} ..."
talosctl apply-config --insecure \
  --nodes "${CP3_IP}" \
  --config-patch @"${PATCH_DIR}/cp-3.yaml" \
  --file "${CONFIG_DIR}/controlplane.yaml"

###############################################################################
# Apply to worker nodes
###############################################################################
echo "==> Applying config to talos-w1 at ${W1_IP} ..."
talosctl apply-config --insecure \
  --nodes "${W1_IP}" \
  --config-patch @"${PATCH_DIR}/worker-1.yaml" \
  --file "${CONFIG_DIR}/worker.yaml"

echo "==> Applying config to talos-w2 at ${W2_IP} ..."
talosctl apply-config --insecure \
  --nodes "${W2_IP}" \
  --config-patch @"${PATCH_DIR}/worker-2.yaml" \
  --file "${CONFIG_DIR}/worker.yaml"

echo "==> Applying config to talos-w3 at ${W3_IP} ..."
talosctl apply-config --insecure \
  --nodes "${W3_IP}" \
  --config-patch @"${PATCH_DIR}/worker-3.yaml" \
  --file "${CONFIG_DIR}/worker.yaml"

echo ""
echo "==> All configs applied. Nodes will reboot with their static IPs."
echo "    Wait for nodes to come up, then run ./bootstrap.sh"
