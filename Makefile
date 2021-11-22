ROOT := $(shell pwd)
BASE := ${ROOT}/kustomize/base
K3S := ${ROOT}/kustomize/k3s

DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
GITEA_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /gitea)
REGISTRY_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /registry)

COREDNS_COREFILE := ${K3S}/configs/Corefile

${COREDNS_COREFILE}:
	sed "s/__GITEA_IP_ADDRESS__/${GITEA_IP_ADDRESS}/" \
	${K3S}/configs/Corefile.template > ${COREDNS_COREFILE}

NAMESPACE := 'flux'
HOST := 'gitea'
FLUX_KNOWN_HOSTS := ${K3S}/configs/known_hosts

${FLUX_KNOWN_HOSTS}:
	@docker run -i -t --rm \
	--network=hyc \
	kroniak/ssh-client \
	ssh-keyscan ${HOST} \
	> ${FLUX_KNOWN_HOSTS}

FLUX_YAML := ${BASE}/flux.yaml

GIT_USER=hyc-bot
GIT_EMAIL=hyc-bot@hyc.com
GIT_URL=git@gitea:HYC/hyctestk3s.git
GIT_BRANCH=main
GIT_PATH=resources/

${FLUX_YAML}:
	@fluxctl install \
	--git-user=${GIT_USER} \
	--git-email=${GIT_EMAIL} \
	--git-url=${GIT_URL} \
	--git-branch=${GIT_BRANCH} \
	--namespace=flux > ${FLUX_YAML}

start-k3d:
	@k3d cluster create hyc \
		--network=hyc \
		--registry-create=k3d-hyc-registry.localhost:5001 \
		--wait

generate: clean ${FLUX_KNOWN_HOSTS} ${FLUX_YAML}; 

apply-k3s-flux: generate
	@kustomize build ${K3S} | kubectl apply -f -
	@kubectl -n flux rollout status deployment/flux

apply-k8s: ${FLUX_YAML}
	kustomize build ${BASE} | kubectl apply -f -
	kubectl -n flux rollout status deployment/flux

clean:
	rm -f ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_YAML} || true

.PHONY: apply-k3s-flux apply-k8s clean
