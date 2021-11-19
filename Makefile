ROOT := $(shell pwd)
BASE := ${ROOT}/kustomize/base
K3S := ${ROOT}/kustomize/k3s
CLOUD := ${ROOT}/kustomize/cloud
GITEA := ${ROOT}/kustomize/gitea

GIT_USER ?= flux-bot
GIT_EMAIL ?= flux@hyc.com
GIT_URL ?= git@gitea.gitea.svc.cluster.local:HYC/infrastructure.git

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

FLUX_KNOWN_HOSTS_CLOUD := ${CLOUD}/configs/known_hosts

${FLUX_KNOWN_HOSTS_CLOUD}:
	mkdir -p ${CLOUD}/configs
	${ROOT}/hack/ssh_keyscan.sh > ${FLUX_KNOWN_HOSTS_CLOUD}

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
	--git-path=${GIT_PATH} \
	--namespace=flux > ${FLUX_YAML}

start-k3d:
	@k3d cluster create hyc \
		--network=hyc \
		--registry-create=k3d-hyc-registry.localhost:5001 \
		--wait

apply-k3s-flux: clean ${FLUX_KNOWN_HOSTS} ${FLUX_YAML}
	@kustomize build ${K3S} | kubectl apply -f -
	@kubectl -n flux rollout status deployment/flux

apply-k8s-gitea:
	kustomize build ${GITEA} | kubectl apply -f -
	kubectl -n gitea rollout status deployment/gitea
	@${ROOT}/hack/updateHosts.sh gitea gitea gitea.hyc.com

apply-k8s-flux: clean ${FLUX_KNOWN_HOSTS_CLOUD} ${FLUX_YAML}
	@${ROOT}/hack/createGitUser.sh ${GIT_PASSWD}
	kustomize build ${CLOUD}  | kubectl apply -f -
	kubectl -n flux rollout status deployment/flux
	
clean:
	rm -f ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_KNOWN_HOSTS_CLOUD} ${FLUX_YAML}

all: clean apply-k3s;

.PHONY: apply-k8s-gitea apply-k8s-flux apply-k3s clean all
