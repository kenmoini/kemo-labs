#!/bin/bash
set -euo pipefail

# Master deployment script for the homelab
# Deploys workloads in dependency order with health gates between phases

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }

deploy_stack() {
  local dir="$1"
  local name="$(basename "$dir")"
  local parent="$(basename "$(dirname "$dir")")"

  if [ ! -f "${dir}/docker-compose.yml" ]; then
    warn "No docker-compose.yml in ${dir}, skipping"
    return 0
  fi

  log "Deploying ${parent}/${name}..."

  # Copy .env.example to .env if .env doesn't exist
  if [ -f "${dir}/.env.example" ] && [ ! -f "${dir}/.env" ]; then
    warn ".env not found, copying from .env.example — EDIT SECRETS BEFORE PRODUCTION USE"
    cp "${dir}/.env.example" "${dir}/.env"
  fi

  docker compose -f "${dir}/docker-compose.yml" --env-file "${dir}/.env" up -d

  log "${parent}/${name} deployed."
}

wait_healthy() {
  local container="$1"
  local max_wait="${2:-120}"
  log "Waiting for ${container} to be healthy (max ${max_wait}s)..."
  for i in $(seq 1 $((max_wait / 5))); do
    status=$(docker inspect --format='{{.State.Health.Status}}' "${container}" 2>/dev/null || echo "not_found")
    if [ "${status}" = "healthy" ]; then
      log "${container} is healthy!"
      return 0
    fi
    sleep 5
  done
  warn "${container} did not become healthy within ${max_wait}s, continuing anyway..."
}

# Check prerequisites
if ! docker network inspect homelab &>/dev/null; then
  err "Docker network 'homelab' not found. Run scripts/setup-network.sh first."
  exit 1
fi

PHASE="${1:-all}"

case "${PHASE}" in
  0|all)
    log "=== Phase 0: Foundation (PKI) ==="
    deploy_stack "security/pki"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  1|all)
    log "=== Phase 1: Core Infrastructure (DNS + ACME) ==="
    deploy_stack "infrastructure/dns"
    deploy_stack "security/acme"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  2|all)
    log "=== Phase 2: Networking (Traefik + Squid) ==="
    deploy_stack "infrastructure/traefik"
    deploy_stack "infrastructure/outbound-proxy"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  3|all)
    log "=== Phase 3: Data Layer (Databases + S3) ==="
    deploy_stack "databases/shared"
    deploy_stack "storage/s3"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  4|all)
    log "=== Phase 4: Identity & Secrets ==="
    deploy_stack "security/identity"
    deploy_stack "security/vault"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  5|all)
    log "=== Phase 5: Observability ==="
    deploy_stack "observability/grafana-alloy"
    deploy_stack "observability/dozzle"
    deploy_stack "observability/uptime-kuma"
    deploy_stack "observability/scrutiny"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  6|all)
    log "=== Phase 6: Storage Services ==="
    deploy_stack "storage/container-registry"
    deploy_stack "storage/backups"
    deploy_stack "storage/dropbox"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  7|all)
    log "=== Phase 7: Core Applications ==="
    deploy_stack "development/gitlab"
    deploy_stack "documentation/netbox"
    deploy_stack "documentation/paperless-ngx"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  8|all)
    log "=== Phase 8: Application Extensions ==="
    deploy_stack "development/renovate"
    deploy_stack "documentation/paperless-ai"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  9|all)
    log "=== Phase 9: Communication & Notifications ==="
    warn "Mailcow requires manual setup — run communication/mailcow/setup.sh"
    deploy_stack "communication/shlink"
    deploy_stack "communication/ntfy"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  10|all)
    log "=== Phase 10: Documentation & Tools ==="
    deploy_stack "documentation/affine"
    deploy_stack "documentation/drawio"
    deploy_stack "development/code-server"
    deploy_stack "development/it-tools"
    deploy_stack "infrastructure/landing-page"
    deploy_stack "infrastructure/wud"
    deploy_stack "infrastructure/semaphore"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  11|all)
    log "=== Phase 11: Home Automation ==="
    deploy_stack "automation/home-assistant"
    deploy_stack "automation/scrypted"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  12|all)
    log "=== Phase 12: AI & Workflows ==="
    deploy_stack "ai/open-webui"
    deploy_stack "ai/n8n"
    deploy_stack "ai/postiz"
    [ "${PHASE}" != "all" ] && exit 0
    ;;&

  13|all)
    log "=== Phase 13: Network & Boot Services ==="
    deploy_stack "infrastructure/boot-services"
    deploy_stack "infrastructure/network-testing"
    [ "${PHASE}" != "all" ] && exit 0
    ;;

  *)
    echo "Usage: $0 [phase_number|all]"
    echo "Phases: 0-13, or 'all' to deploy everything"
    exit 1
    ;;
esac

log "=== Deployment complete! ==="
log "Kubernetes (Phase 14) must be deployed separately via compute/talos-kubernetes/ scripts."
