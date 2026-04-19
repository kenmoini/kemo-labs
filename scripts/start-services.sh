#!/bin/bash

# ==================================================================
# This script starts all CaaS services in the correct order with appropriate delays
# ==================================================================

# PKI
cd /opt/workdir/kemo-labs/security/pki
podman compose up -d

# Databases
cd /opt/workdir/kemo-labs/databases/shared
podman compose up -d

# DNS Services
cd /opt/workdir/kemo-labs/infrastructure/dns
podman compose up -d

# Step CA
cd /opt/workdir/kemo-labs/security/acme
podman compose up -d

# Traefik Proxy
cd /opt/workdir/kemo-labs/infrastructure/traefik
podman compose up -d

# Landing Page
cd /opt/workdir/kemo-labs/infrastructure/landing-page
podman compose up -d