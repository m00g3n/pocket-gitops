ROOT := $(shell pwd)
BASE := ${ROOT}/kustomize/base
K3S := ${ROOT}/kustomize/k3s

DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
GITEA_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /gitea)
REGISTRY_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /registry)

COREDNS_COREFILE := ${K3S}/configs/Corefile

${COREDNS_COREFILE}:
	sed "s/__GITEA_IP_ADDRESS__/${GITEA_IP_ADDRESS}/; s/__REGISTRY_IP_ADDRESS__/${REGISTRY_IP_ADDRESS}/" \
	${K3S}/configs/Corefile.template > ${COREDNS_COREFILE}

NAMESPACE := 'flux'
HOST := 'gitea'
FLUX_KNOWN_HOSTS := ${K3S}/configs/known_hosts

${FLUX_KNOWN_HOSTS}:
	docker run -i -t --rm \
	--network=hyc-demo \
	kroniak/ssh-client \
	ssh-keyscan ${HOST} \
	> ${FLUX_KNOWN_HOSTS}

FLUX_YAML := ${BASE}/flux.yaml

${FLUX_YAML}:
	fluxctl install \
	--git-user=${GIT_USER} \
	--git-email=${GIT_EMAIL} \
	--git-url=${GIT_URL} \
	--namespace=flux > ${FLUX_YAML}

generate: ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_YAML};

apply-k3s: generate
	kubectl config use-context default --kubeconfig='kubeconfig.yaml'
	kustomize build ${K3S} | kubectl apply -f -
	kubectl -n flux rollout status deployment/flux

clean:
	rm -f ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_YAML}

all: clean apply-k3s;

.PHONY: apply-k3s clean all