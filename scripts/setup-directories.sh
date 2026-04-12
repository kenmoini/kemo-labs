#!/bin/bash

# ==================================================================
# This script sets up the directory structure for the CaaS and VM services
# ==================================================================

# Variables
export CONTAINER_WORK_DIR="/opt/workdir/caas"
export VM_WORK_DIR="/opt/workdir/vm"

# Create directories for CaaS services
mkdir -p ${CONTAINER_WORK_DIR}/pika-pki/data
if [ -d "${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles" ]; then
  chmod -R 755 ${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles
fi