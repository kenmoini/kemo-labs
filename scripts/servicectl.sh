#!/bin/bash

# ==================================================================
# This script starts all CaaS services in the correct order with appropriate delays
# ==================================================================

################################################################################### EXECUTION PREFLIGHT
## Ensure there is an action arguement
if [ -z "$1" ]; then
  echo "Need action arguement of 'start', 'restart', or 'stop'!"
  echo "${0} start|stop|restart"
  exit 1
fi

################################################################################### SERVICE ACTION SWITCH
case $1 in

  ################################################################################# RESTART/STOP SERVICE
  "restart" | "stop")
    echo "Stopping container services if running..."

    # Network Testing
    cd /opt/workdir/kemo-labs/infrastructure/network-testing
    podman compose down

    # IT Tools
    cd /opt/workdir/kemo-labs/development/it-tools
    podman compose down

    # Observability Stack
    cd /opt/workdir/kemo-labs/observability/grafana-alloy
    podman compose down

    # Container Registry
    cd /opt/workdir/kemo-labs/storage/container-registry
    podman compose down

    # DockNS
    cd /opt/workdir/kemo-labs/utilities/dockns
    podman compose down

    # Docker Proxy
    cd /opt/workdir/kemo-labs/utilities/docker-proxy
    podman compose down

    # Outbound Proxy
    cd /opt/workdir/kemo-labs/infrastructure/outbound-proxy
    podman compose down

    # Landing Page
    cd /opt/workdir/kemo-labs/infrastructure/landing-page
    podman compose down

    # Traefik Proxy
    cd /opt/workdir/kemo-labs/infrastructure/traefik
    podman compose down

    # DNS Services
    cd /opt/workdir/kemo-labs/infrastructure/dns
    podman compose down

    # Step CA
    cd /opt/workdir/kemo-labs/security/acme
    podman compose down

    # Databases
    cd /opt/workdir/kemo-labs/databases/shared
    podman compose down

    # Time
    cd /opt/workdir/kemo-labs/infrastructure/chrony
    podman compose down

    # PKI
    cd /opt/workdir/kemo-labs/security/pki
    podman compose down

    ;;

esac

################################################################################### SERVICE ACTION SWITCH
case $1 in

  ################################################################################# RESTART/STOP SERVICE
  "restart" | "start")
    echo "Starting container services..."

    # PKI
    cd /opt/workdir/kemo-labs/security/pki
    podman compose up -d

    # Time
    cd /opt/workdir/kemo-labs/infrastructure/chrony
    podman compose up -d

    # Databases
    cd /opt/workdir/kemo-labs/databases/shared
    podman compose up -d

    # Step CA
    cd /opt/workdir/kemo-labs/security/acme
    podman compose up -d

    # DNS Services
    cd /opt/workdir/kemo-labs/infrastructure/dns
    podman compose up -d

    # Traefik Proxy
    cd /opt/workdir/kemo-labs/infrastructure/traefik
    podman compose up -d

    # Landing Page
    cd /opt/workdir/kemo-labs/infrastructure/landing-page
    podman compose up -d

    # Outbound Proxy
    cd /opt/workdir/kemo-labs/infrastructure/outbound-proxy
    podman compose up -d

    # Docker Proxy
    cd /opt/workdir/kemo-labs/utilities/docker-proxy
    podman compose up -d

    # DockNS
    cd /opt/workdir/kemo-labs/utilities/dockns
    podman compose up -d

    # Container Registry
    cd /opt/workdir/kemo-labs/storage/container-registry
    podman compose up -d

    # Observability Stack
    cd /opt/workdir/kemo-labs/observability/grafana-alloy
    podman compose up -d

    # Network Testing
    cd /opt/workdir/kemo-labs/infrastructure/network-testing
    podman compose up -d

    # IT Tools
    cd /opt/workdir/kemo-labs/development/it-tools
    podman compose up -d

    ;;

esac