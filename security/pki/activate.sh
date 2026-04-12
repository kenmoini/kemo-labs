#!/bin/bash

# ==================================================================
# This script lets you activate the interactive profile for the PKI services
# ==================================================================

# Enter the script directory
cd "$(dirname "$0")"

# Activate the interactive profile for the PKI services
podman compose --profile interactive run pika-pki
