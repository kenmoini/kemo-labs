#!/bin/bash

# ==================================================================
POD_NAME="acme"
POD_NETWORK="bridge42"
POD_IP_ADDRESS="192.168.42.6"
POD_PORTS="-p 9100"

STEP_CA_CONTAINER_NAME="step-ca"
STEP_CA_CONTAINER_IMAGE="docker.io/smallstep/step-ca:0.30.2"
STEP_CA_CONTAINER_RESTART_POLICY="unless-stopped"
STEP_CA_CONTAINER_HEALTHCHECK="CMD-SHELL curl -fk https://localhost:9100/health || exit 1"
STEP_CA_CONTAINER_VOLUMES="-v /opt/workdir/caas/stepca/data/db:/home/step/db:Z
      -v ./config/ca.json:/home/step/config/ca.json:ro,Z
      -v ./config/defaults.json:/home/step/config/defaults.json:ro,Z
      -v ./secrets/password:/home/step/secrets/password:ro,Z
      -v /opt/workdir/caas/pika-pki/data/.pika-pki/roots/kemo-labs-root-certificate-authority/certs/ca.cert.pem:/home/step/certs/root_ca.crt:ro,Z
      -v /opt/workdir/caas/pika-pki/data/.pika-pki/roots/kemo-labs-root-certificate-authority/intermediate-ca/kemo-labs-stepca-intermediate-ca/certs/ca.cert.pem:/home/step/certs/intermediate_ca.crt:ro,Z
      -v /opt/workdir/caas/pika-pki/data/.pika-pki/roots/kemo-labs-root-certificate-authority/intermediate-ca/kemo-labs-stepca-intermediate-ca/private/ca.key.pem:/home/step/secrets/intermediate_ca_key:ro,Z"

STEP_CA_CONTAINER_LABELS='
      --label "traefik.enable=true"
      --label "traefik.http.routers.step-ca.rule=Host(`step-ca.lab.kemo.dev`)"
      --label "traefik.http.routers.step-ca.entrypoints=websecure"
      --label "traefik.http.routers.step-ca.tls=true"
      --label "traefik.http.routers.step-ca.tls.certresolver=stepca"
      --label "traefik.http.services.step-ca.loadbalancer.server.port=9100"
      --label "traefik.http.services.step-ca.loadbalancer.server.scheme=https"
      --label "homepage.group=Services"
      --label "homepage.name=Step CA"
      --label "homepage.icon=stepca.png"
      --label "homepage.description='Step Certificate Authority'"
      --label "homepage.href=https://step-ca.lab.kemo.dev"'


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
  "restart" | "stop" | "start" | "init")
    echo "Stopping container services if running..."

    echo "Killing ${POD_NAME} pod..."
    /usr/bin/podman pod kill ${POD_NAME}

    echo "Removing ${POD_NAME} pod..."
    /usr/bin/podman pod rm -f -i ${POD_NAME}
    ;;

esac

case $1 in

  ################################################################################# RESTART/START SERVICE
  "pull")

      echo "Pulling container images..."
      /usr/bin/podman pull ${STEP_CA_CONTAINER_IMAGE}

    ;;

  "restart" | "start")

    echo "Creating Pod..."

    /usr/bin/podman pod create --name ${POD_NAME} --network ${POD_NETWORK}:ip="${POD_IP_ADDRESS}" ${POD_PORTS}

    echo "Starting ${STEP_CA_CONTAINER_NAME} container..."

    /usr/bin/podman run -dt \
      --pod ${POD_NAME} \
      --name ${STEP_CA_CONTAINER_NAME} \
      --restart ${STEP_CA_CONTAINER_RESTART_POLICY} \
      --healthcheck-command "${STEP_CA_CONTAINER_HEALTHCHECK}" \
      --healthcheck-interval 30s \
      --healthcheck-retries 3 \
      --healthcheck-start-period 15s \
      ${STEP_CA_CONTAINER_LABELS} \
      ${STEP_CA_CONTAINER_VOLUMES} \
      ${STEP_CA_CONTAINER_IMAGE}

    ;;

esac