#!/bin/sh

############################ COREDNS PATCH ################################################################

readonly DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
readonly GITEA_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /gitea)
readonly REGISTRY_IP_ADDRESS=$(docker inspect -f "$DOCKER_IP_ADDR_TPL" /registry)

sed "s/__GITEA_IP_ADDRESS__/$GITEA_IP_ADDRESS/; s/__REGISTRY_IP_ADDRESS__/$REGISTRY_IP_ADDRESS/" \
./coredns.template.patch.yaml > ./kustomize/base/coredns.patch.yaml

############################ CREATE FLUX KNOWN HOSTS CONFIGMAP ############################################

readonly NAMESPACE=${1:-flux}
readonly HOST=${2:-gitea}

# create temp file that will contain known hosts
readonly tmpfile=$(mktemp /tmp/known_hosts.XXXXXX)
exec 3>"$tmpfile"

docker run -i -t --rm \
--network=hyc-demo \
kroniak/ssh-client \
ssh-keyscan $HOST \
> $tmpfile

kubectl create configmap flux-ssh-config \
-n $NAMESPACE \
--from-file=known_hosts=$tmpfile \
-oyaml \
--dry-run \
--save-config \
> ./kustomize/base/flux-ssh-config.yaml

rm "$tmpfile"

############################ ###############################################################################

fluxctl install \
--git-user=admin123 \
--git-email=me@test.you \
--git-url=git@gitea:hyc-gitops/dywan.git \
--namespace=flux > ./kustomize/base/flux.yaml

############################ ###############################################################################

kubectl apply -k ./kustomize/known_hosts