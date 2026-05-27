#!/bin/bash

systemctl stop caas-it-tools
systemctl stop caas-openspeedtest
systemctl stop caas-iperf3
systemctl stop caas-squid
systemctl stop caas-homepage
systemctl stop caas-dozzle
systemctl stop caas-auto-kuma
systemctl stop caas-stepca
systemctl stop caas-dockns
systemctl stop caas-authentik-pod
systemctl stop caas-uptime-kuma
systemctl stop caas-dns-pod
systemctl stop caas-shared-db-pod
systemctl stop caas-pki
systemctl stop caas-traefik
systemctl stop caas-podman-proxy
systemctl stop caas-chrony
