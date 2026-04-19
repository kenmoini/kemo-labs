#!/bin/bash

# ==================================================================
# This script sets up the directory structure for the CaaS and VM services
# ==================================================================

# Variables
export CONTAINER_WORK_DIR="/opt/workdir/caas"
export VM_WORK_DIR="/opt/workdir/vm"
export GIT_SRC_DIR="/opt/workdir/kemo-labs"

# ==================================================================
# Create directories for CaaS services
# ==================================================================

# ==================================================================
# Pika PKI
mkdir -p ${CONTAINER_WORK_DIR}/pika-pki/data
if [ -d "${CONTAINER_WORK_DIR}/pika-pki/data" ]; then
  chown -R 1001:1001 ${CONTAINER_WORK_DIR}/pika-pki/data
fi
if [ -d "${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles" ]; then
  chmod -R 755 ${CONTAINER_WORK_DIR}/pika-pki/data/.pika-pki/public_bundles
fi

# ==================================================================
# Shared Databases
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mariadb_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/postgresql_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/valkey_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_data
mkdir -p ${CONTAINER_WORK_DIR}/databases/shared/mosquitto_log
mkdir -p ${CONTAINER_WORK_DIR}/databases/backups

if [ -d "${CONTAINER_WORK_DIR}/databases/shared/mariadb_data" ]; then
  chown -R 911:911 ${CONTAINER_WORK_DIR}/databases/shared/mariadb_data
fi
if [ -d "${CONTAINER_WORK_DIR}/databases/shared/postgresql_data" ]; then
  chown -R 999:999 ${CONTAINER_WORK_DIR}/databases/shared/postgresql_data
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

# ==================================================================
# DNS Services
mkdir -p ${CONTAINER_WORK_DIR}/dns/pihole/etc-pihole
mkdir -p ${CONTAINER_WORK_DIR}/dns/pdns-admin/data
if [ -d "${CONTAINER_WORK_DIR}/dns/pihole/etc-pihole" ]; then
  chown -R 0:1000 ${CONTAINER_WORK_DIR}/dns/pihole/etc-pihole
fi
if [ -d "${CONTAINER_WORK_DIR}/dns/pdns-admin/data" ]; then
  chown -R 999:999 ${CONTAINER_WORK_DIR}/dns/pdns-admin/data
fi

# ==================================================================
# StepCA
mkdir -p ${CONTAINER_WORK_DIR}/stepca/data/{db,templates}
if [ -d "${CONTAINER_WORK_DIR}/stepca/data" ]; then
  chown -R 1000:1000 ${CONTAINER_WORK_DIR}/stepca/data
fi

# ==================================================================
# Traefik
mkdir -p ${CONTAINER_WORK_DIR}/traefik/data/storage
if [ -d "${CONTAINER_WORK_DIR}/traefik/data/storage" ]; then
  chown -R 0:0 ${CONTAINER_WORK_DIR}/traefik/data/storage
fi

# ==================================================================
# Homepage
mkdir -p ${CONTAINER_WORK_DIR}/homepage/logs
if [ -d "${CONTAINER_WORK_DIR}/homepage/logs" ]; then
  chown -R 1001:1001 ${CONTAINER_WORK_DIR}/homepage/logs
fi
if [ -d "${GIT_SRC_DIR}/infrastructure/landing-page/config" ]; then
  chown -R 1000:1000 ${GIT_SRC_DIR}/infrastructure/landing-page/config
fi

# ==================================================================
# Squid Proxy
mkdir -p ${CONTAINER_WORK_DIR}/outbound-proxy/data/cache
mkdir -p ${CONTAINER_WORK_DIR}/outbound-proxy/data/logs
if [ -d "${CONTAINER_WORK_DIR}/outbound-proxy/data/cache" ]; then
  chown -R 23:23 ${CONTAINER_WORK_DIR}/outbound-proxy/data/cache
fi
if [ -d "${CONTAINER_WORK_DIR}/outbound-proxy/data/logs" ]; then
  chown -R 23:23 ${CONTAINER_WORK_DIR}/outbound-proxy/data/logs
fi