#!/bin/sh

# this format will return only the ip address of the container
readonly DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

readonly GITEA_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /gitea)

readonly REGISTRY_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /registry)

sed "s/__GITEA_IP_ADDRESS__/$GITEA_IP_ADDRESS/; s/__REGISTRY_IP_ADDRESS__/$REGISTRY_IP_ADDRESS/" \
./coredns.template.patch.yaml \
| tee coredns.patch.yaml

kubectl -n kube-system patch cm coredns --patch "$(cat coredns.patch.yaml)"