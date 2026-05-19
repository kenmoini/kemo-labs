#!/bin/bash

until [ "`podman inspect -f {{.State.Running}} vault`"=="true" ]; do
    sleep 2;
done;

podman exec vault vault operator unseal $KEY1
podman exec vault vault operator unseal $KEY2
podman exec vault vault operator unseal $KEY3