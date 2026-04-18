#!/usr/bin/with-contenv bash

echo "==============================================================="
echo "Bootstrapping MariaDB container with needed databases..."
echo "==============================================================="

while ! mysql -e '\q' >/dev/null 2>&1; do
  echo "===== Waiting for MariaDB to be ready..."
  sleep 5
done

echo "===== MariaDB is initialized. Creating databases..."

# Create databases
/docker-entrypoint-initdb.d/01-create-databases.sh

# Go to sleep
sleep infinity