#!/bin/sh

# this format will return only the ip address of the container
readonly DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

readonly GITEA_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /gitea)

readonly REGISTRY_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /registry)

sed "s/__GITEA_IP_ADDRESS__/$GITEA_IP_ADDRESS/; s/__REGISTRY_IP_ADDRESS__/$REGISTRY_IP_ADDRESS/" \
./coredns.template.patch.yaml \
| tee coredns.patch.yaml

kubectl -n kube-system patch cm coredns --patch "$(cat coredns.patch.yaml)"

NAMESPACE=${1:-flux}
HOST=${2:-gitea}

docker run -i -t --rm --network=pocker-gitops_hyc-demo kroniak/ssh-client ssh-keyscan $HOST \
| tee ./known_hosts

# create namespace if not exists
kubectl create ns $NAMESPACE \
    -oyaml \
    --save-config \
    --dry-run \
| kubectl apply -f -

# create or replace configmap with known_hosts
kubectl create configmap flux-ssh-config \
    -n $NAMESPACE \
    --from-file=known_hosts \
    -oyaml \
    --dry-run \
| kubectl apply -f -

fluxctl install \
    --git-user=admin123 \
    --git-email=me@test.you \
    --git-url=git@gitea:hyc-gitops/dywan.git \
    --namespace=flux > ./kustomize/base/flux.yaml

kubectl apply -k ./kustomize/known_hosts