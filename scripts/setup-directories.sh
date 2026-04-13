#!/bin/bash

# ==================================================================
# This script sets up the directory structure for the CaaS and VM services
# ==================================================================

# Variables
export CONTAINER_WORK_DIR="/opt/workdir/caas"
export VM_WORK_DIR="/opt/workdir/vm"

# ==================================================================
# Create directories for CaaS services
# ==================================================================

# Pika PKI
mkdir -p ${CONTAINER_WORK_DIR}/pika-pki/data
if [ -d "${CONTAINER_WORK_DIR}/pika-pki/data" ]; then
  chown -R 1001:1001 ${CONTAINER_WORK_DIR}/pika-pki/data
fi
if [ -d "${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles" ]; then
  chmod -R 755 ${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles
fi

# Shared Databases
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mariadb_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/postgres_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/valkey_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_log
mkdir -p ${CONTAINER_WORK_DIR}/databases/backups
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/mariadb_data" ]; then
  chown -R 911:911 ${CONTAINER_WORK_DIR}/databases/shared/mariadb_data
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/postgres_data" ]; then
  chown -R 999:999 ${CONTAINER_WORK_DIR}/databases/shared/postgres_data
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/valkey_data" ]; then
  chown -R 999:999 ${CONTAINER_WORK_DIR}/databases/shared/valkey_data
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/mosquitto_data" ]; then
  chown -R 1883:1883 ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_data
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/mosquitto_log" ]; then
  chown -R 1883:1883 ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_log
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/backups" ]; then
  chown -R 999:999 ${CONTAINER_WORK_DIR}/databases/backups
fi