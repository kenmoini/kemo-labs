#!/bin/bash

# This script simply symbolically links the Podman Quadlets to the system directory

export GIT_SRC_DIR="/opt/workdir/kemo-labs"

# Check to see if the GIT_SRC_DIR exists
if [ ! -d "${GIT_SRC_DIR}" ]; then
  echo "Error: Source directory ${GIT_SRC_DIR} does not exist. Please clone the repository and try again."
  exit 1
fi

# Networking
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/quadlets/networks.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/quadlets/pods.quadlets

# Services - No Requirements
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/chrony/chrony.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/utilities/podman-proxy/podman-proxy.quadlets

# Services - Requires Podman Proxy
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/traefik/traefik.quadlets

# Services - Requires Traefik Proxy
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/security/pki/pki.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/databases/shared/databases.quadlets

# Services - Requires Traefik Proxy and Databases
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/dns/dns.quadlets

# Services - Requires Podman Proxy, Traefik Proxy, Databases, and DNS
# podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/observability/grafana-alloy/grafana-alloy.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/observability/uptime-kuma/uptime-kuma.quadlets

# Services - Requires Traefik Proxy, Databases, and DNS
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/security/identity/authentik.quadlets

# Services - Requires Traefik Proxy and DNS
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/utilities/dockns/dockns.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/security/acme/acme.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/storage/dropbox/dropbox.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/security/vault/vault.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/storage/s3/s3.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/storage/container-registry/nexus.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/documentation/paperless/paperless.quadlets

# Services - Requires Podman Proxy, Traefik Proxy, and DNS
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/utilities/auto-kuma/auto-kuma.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/observability/dozzle/dozzle.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/landing-page/landing-page.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/outbound-proxy/squid.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/infrastructure/network-testing/network-testing.quadlets
podman quadlet install --replace --reload-systemd ${GIT_SRC_DIR}/development/it-tools/it-tools.quadlets