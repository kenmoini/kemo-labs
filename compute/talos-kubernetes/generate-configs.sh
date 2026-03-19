#\!/usr/bin/env bash
set -euo pipefail

###############################################################################
# generate-configs.sh
# Generates Talos machine configs using talosctl gen config.
#
# Produces:
#   _out/controlplane.yaml
#   _out/worker.yaml
#   _out/talosconfig
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/_out"
CLUSTER_NAME="homelab"
CLUSTER_ENDPOINT="https://talos-api.lab.kemo.network:6443"

# Pod and Service CIDRs
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
CLUSTER_DNS_DOMAIN="cluster.local"

if [ -d "${OUTPUT_DIR}" ]; then
  echo "WARNING: ${OUTPUT_DIR} already exists."
  echo "         Remove it first if you want to regenerate configs."
  read -rp "         Overwrite? [y/N] " confirm
  if [[ "${confirm}" \!= [yY] ]]; then
    echo "Aborted."
    exit 1
  fi
  rm -rf "${OUTPUT_DIR}"
fi

echo "==> Generating Talos cluster config"
echo "    Cluster name:     ${CLUSTER_NAME}"
echo "    Cluster endpoint: ${CLUSTER_ENDPOINT}"
echo "    Pod CIDR:         ${POD_CIDR}"
echo "    Service CIDR:     ${SERVICE_CIDR}"
echo "    DNS domain:       ${CLUSTER_DNS_DOMAIN}"
echo ""

talosctl gen config "${CLUSTER_NAME}" "${CLUSTER_ENDPOINT}" \
  --output-dir "${OUTPUT_DIR}" \
  --with-docs=false \
  --with-examples=false \
  --kubernetes-version "1.32.0" \
  --config-patch '[
    {"op": "add", "path": "/cluster/network", "value": {
      "podSubnets": ["'"${POD_CIDR}"'"],
      "serviceSubnets": ["'"${SERVICE_CIDR}"'"],
      "dnsDomain": "'"${CLUSTER_DNS_DOMAIN}"'"
    }}
  ]'

echo ""
echo "==> Configs generated in ${OUTPUT_DIR}/"
echo "    controlplane.yaml  -- base control plane machine config"
echo "    worker.yaml        -- base worker machine config"
echo "    talosconfig        -- talosctl client config"
echo ""
echo "    IMPORTANT: Back up ${OUTPUT_DIR}/ -- it contains cluster secrets."
echo ""
echo "    Next: Run ./apply-configs.sh to apply configs with per-node patches."
