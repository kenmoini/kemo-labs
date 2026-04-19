#!/bin/bash
set -euo pipefail

# =============================================================================
# Docker Network Setup
# =============================================================================
# Creates macvlan Docker networks for the homelab.
# Supports creating a single network via named parameters, or all predefined
# networks via the --all flag.
#
# Usage:
#   ./setup-network.sh --all                    Create all predefined networks
#   ./setup-network.sh --name homelab-lab \      Create a single network
#     --subnet 192.168.42.0/23 \
#     --gateway 192.168.42.1 \
#     --ip-range 192.168.42.0/24 \
#     --parent br0.62
#   ./setup-network.sh                          Interactive mode (prompts)
# =============================================================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[NET]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }

# --- Predefined networks matching the architecture ---
# Format: NAME|SUBNET|GATEWAY|IP_RANGE|PARENT|DESCRIPTION
PREDEFINED_NETWORKS=(
  "homelab-access|192.168.92.0/23|192.168.92.1|192.168.92.0/24|br0|Access VLAN"
  "homelab-lab|192.168.42.0/23|192.168.42.1|192.168.42.0/24|br0.62|Lab VLAN 62 - primary workload network"
  "homelab-disconnected|192.168.70.0/24|192.168.70.1|192.168.70.0/24|br0.70|Disconnected VLAN 70 - no upstream connectivity"
  "homelab-isolated|192.168.86.0/24|192.168.86.1|192.168.86.0/24|br0.86|Isolated VLAN 86 - restricted traffic"
)

# --- Functions ---

create_network() {
  local name="$1"
  local subnet="$2"
  local gateway="$3"
  local ip_range="$4"
  local parent="$5"
  local description="${6:-}"

  if docker network inspect "${name}" &>/dev/null; then
    warn "Network '${name}' already exists, skipping."
    return 0
  fi

  # Verify parent interface exists
  if ! ip link show "${parent}" &>/dev/null; then
    warn "Parent interface '${parent}' not found on host. Skipping '${name}'."
    warn "  Create it first, e.g.: sudo ip link add link br0 name ${parent} type vlan id <vid>"
    return 1
  fi

  log "Creating network '${name}'..."
  info "  Subnet:    ${subnet}"
  info "  Gateway:   ${gateway}"
  info "  IP Range:  ${ip_range}"
  info "  Parent:    ${parent}"
  [ -n "${description}" ] && info "  Purpose:   ${description}"

  docker network create \
    --driver macvlan \
    --subnet="${subnet}" \
    --gateway="${gateway}" \
    --ip-range="${ip_range}" \
    -o parent="${parent}" \
    "${name}"

  log "Network '${name}' created successfully."
  echo ""
}

create_shim() {
  local name="$1"
  local parent="$2"
  local host_ip="$3"
  local route_subnet="$4"

  local shim_name="${name}-shim"

  if ip link show "${shim_name}" &>/dev/null; then
    warn "Shim interface '${shim_name}' already exists, skipping."
    return 0
  fi

  log "Creating macvlan shim '${shim_name}' for host-to-container communication..."
  sudo ip link add "${shim_name}" link "${parent}" type macvlan mode bridge
  sudo ip addr add "${host_ip}/32" dev "${shim_name}"
  sudo ip link set "${shim_name}" up
  sudo ip route add "${route_subnet}" dev "${shim_name}" 2>/dev/null || true
  log "Shim '${shim_name}' created (${host_ip} -> ${route_subnet})."
}

create_all_networks() {
  log "=== Creating All Predefined Docker Networks ==="
  echo ""

  local created=0
  local skipped=0
  local failed=0

  for entry in "${PREDEFINED_NETWORKS[@]}"; do
    IFS='|' read -r name subnet gateway ip_range parent description <<< "${entry}"
    if create_network "${name}" "${subnet}" "${gateway}" "${ip_range}" "${parent}" "${description}"; then
      ((created++)) || true
    else
      ((failed++)) || true
    fi
  done

  echo ""
  log "=== Done ==="
  log "Created/verified ${#PREDEFINED_NETWORKS[@]} networks."
  echo ""
  info "To enable host-to-container communication, create shim interfaces:"
  echo ""
  for entry in "${PREDEFINED_NETWORKS[@]}"; do
    IFS='|' read -r name subnet gateway ip_range parent description <<< "${entry}"
    local shim_ip="${gateway}"
    echo "  # ${description}"
    echo "  sudo ip link add ${name}-shim link ${parent} type macvlan mode bridge"
    echo "  sudo ip addr add ${shim_ip}/32 dev ${name}-shim"
    echo "  sudo ip link set ${name}-shim up"
    echo "  sudo ip route add ${ip_range} dev ${name}-shim"
    echo ""
  done

  info "Or run: $0 --shims  to create all shim interfaces automatically."
}

create_all_shims() {
  log "=== Creating Macvlan Shim Interfaces ==="
  echo ""

  for entry in "${PREDEFINED_NETWORKS[@]}"; do
    IFS='|' read -r name subnet gateway ip_range parent description <<< "${entry}"
    if docker network inspect "${name}" &>/dev/null; then
      create_shim "${name}" "${parent}" "${gateway}" "${ip_range}"
    else
      warn "Network '${name}' does not exist, skipping shim."
    fi
  done

  echo ""
  log "=== Shims created ==="
  info "Note: Shim interfaces are not persistent across reboots."
  info "Add them to a systemd service or NetworkManager dispatcher script for persistence."
}

prompt_value() {
  local prompt="$1"
  local default="$2"
  local varname="$3"

  if [ -n "${default}" ]; then
    read -rp "${prompt} [${default}]: " value
    eval "${varname}=\"${value:-${default}}\""
  else
    read -rp "${prompt}: " value
    eval "${varname}=\"${value}\""
  fi
}

interactive_mode() {
  log "=== Interactive Network Setup ==="
  echo ""

  prompt_value "Network name" "homelab-lab" NETWORK_NAME
  prompt_value "Subnet (CIDR)" "192.168.42.0/23" SUBNET
  prompt_value "Gateway" "192.168.42.1" GATEWAY
  prompt_value "IP range for containers (CIDR)" "192.168.42.0/24" IP_RANGE
  prompt_value "Parent interface" "br0.62" PARENT
  prompt_value "Description (optional)" "" DESCRIPTION

  echo ""
  create_network "${NETWORK_NAME}" "${SUBNET}" "${GATEWAY}" "${IP_RANGE}" "${PARENT}" "${DESCRIPTION}"
}

list_networks() {
  log "=== Predefined Networks ==="
  echo ""
  printf "  %-22s %-20s %-15s %-10s %s\n" "NAME" "SUBNET" "GATEWAY" "PARENT" "DESCRIPTION"
  printf "  %-22s %-20s %-15s %-10s %s\n" "----" "------" "-------" "------" "-----------"
  for entry in "${PREDEFINED_NETWORKS[@]}"; do
    IFS='|' read -r name subnet gateway ip_range parent description <<< "${entry}"
    printf "  %-22s %-20s %-15s %-10s %s\n" "${name}" "${subnet}" "${gateway}" "${parent}" "${description}"
  done
  echo ""

  log "=== Current Docker Networks ==="
  docker network ls --filter driver=macvlan --format "  {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>/dev/null || echo "  (none)"
  echo ""
}

show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Create macvlan Docker networks for the homelab.

Options:
  --all                 Create all predefined networks
  --shims              Create macvlan shim interfaces for host-to-container comms
  --list               List predefined and existing networks
  --name NAME          Network name
  --subnet CIDR        Subnet (e.g., 192.168.42.0/23)
  --gateway IP         Gateway address
  --ip-range CIDR      Container IP range
  --parent IFACE       Parent host interface (e.g., br0.62)
  --description TEXT    Optional description
  -h, --help           Show this help

Examples:
  $(basename "$0") --all
  $(basename "$0") --list
  $(basename "$0") --shims
  $(basename "$0") --name homelab-lab --subnet 192.168.42.0/23 --gateway 192.168.42.1 --ip-range 192.168.42.0/24 --parent br0.62
  $(basename "$0")                    # Interactive mode
EOF
}

# --- Parse arguments ---

NETWORK_NAME=""
SUBNET=""
GATEWAY=""
IP_RANGE=""
PARENT=""
DESCRIPTION=""
MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)          MODE="all"; shift ;;
    --shims)        MODE="shims"; shift ;;
    --list)         MODE="list"; shift ;;
    --name)         NETWORK_NAME="$2"; shift 2 ;;
    --subnet)       SUBNET="$2"; shift 2 ;;
    --gateway)      GATEWAY="$2"; shift 2 ;;
    --ip-range)     IP_RANGE="$2"; shift 2 ;;
    --parent)       PARENT="$2"; shift 2 ;;
    --description)  DESCRIPTION="$2"; shift 2 ;;
    -h|--help)      show_usage; exit 0 ;;
    *)              warn "Unknown option: $1"; show_usage; exit 1 ;;
  esac
done

# --- Execute ---

case "${MODE}" in
  all)
    create_all_networks
    ;;
  shims)
    create_all_shims
    ;;
  list)
    list_networks
    ;;
  "")
    # If any named params were provided, use them; otherwise go interactive
    if [ -n "${NETWORK_NAME}" ]; then
      # Fill in missing params interactively
      [ -z "${SUBNET}" ] && prompt_value "Subnet (CIDR)" "" SUBNET
      [ -z "${GATEWAY}" ] && prompt_value "Gateway" "" GATEWAY
      [ -z "${IP_RANGE}" ] && prompt_value "IP range (CIDR)" "" IP_RANGE
      [ -z "${PARENT}" ] && prompt_value "Parent interface" "" PARENT
      create_network "${NETWORK_NAME}" "${SUBNET}" "${GATEWAY}" "${IP_RANGE}" "${PARENT}" "${DESCRIPTION}"
    else
      interactive_mode
    fi
    ;;
esac
