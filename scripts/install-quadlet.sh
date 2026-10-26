#!/bin/bash

# This script simply symbolically links the Podman Quadlets to the system directory

# Check to see if the quadlet path exists
if [ -z "${1}" ]; then
  echo "Error: Path to the quadlet file is not provided. Please provide the path to the quadlet file as an argument."
  exit 1
fi

# Check to see if the provided quadlet path exists
if [ ! -f "${1}" ]; then
  echo "Error: Quadlet file ${1} does not exist. Please provide a valid path to the quadlet file."
  exit 1
fi

# Networking
podman quadlet install --replace --reload-systemd $1