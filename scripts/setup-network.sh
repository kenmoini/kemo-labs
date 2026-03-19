#!/bin/bash
set -euo pipefail

# Create the shared macvlan Docker network for all homelab services
# Run this ONCE before deploying any stack

NETWORK_NAME="homelab"
SUBNET="192.168.62.0/23"
GATEWAY="192.168.62.1"
IP_RANGE="192.168.62.0/24"
PARENT_INTERFACE="${1:-br0}"

echo "=== Creating Homelab Docker Network ==="
echo "Network:   ${NETWORK_NAME}"
echo "Subnet:    ${SUBNET}"
echo "Gateway:   ${GATEWAY}"
echo "IP Range:  ${IP_RANGE}"
echo "Parent:    ${PARENT_INTERFACE}"
echo ""

# Check if network already exists
if docker network inspect "${NETWORK_NAME}" &>/dev/null; then
  echo "Network '${NETWORK_NAME}' already exists."
  docker network inspect "${NETWORK_NAME}" --format '{{.IPAM.Config}}'
  exit 0
fi

# Create macvlan network
docker network create \
  --driver macvlan \
  --subnet="${SUBNET}" \
  --gateway="${GATEWAY}" \
  --ip-range="${IP_RANGE}" \
  -o parent="${PARENT_INTERFACE}" \
  "${NETWORK_NAME}"

echo ""
echo "Network '${NETWORK_NAME}' created successfully."
echo ""
echo "To verify: docker network inspect ${NETWORK_NAME}"
echo ""
echo "Note: Containers on macvlan cannot communicate with the host directly."
echo "If you need host-to-container communication, create a macvlan interface on the host:"
echo "  sudo ip link add ${NETWORK_NAME}-shim link ${PARENT_INTERFACE} type macvlan mode bridge"
echo "  sudo ip addr add 192.168.62.1/32 dev ${NETWORK_NAME}-shim"
echo "  sudo ip link set ${NETWORK_NAME}-shim up"
echo "  sudo ip route add 192.168.62.0/24 dev ${NETWORK_NAME}-shim"
