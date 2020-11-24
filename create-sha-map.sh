#!/bin/sh

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