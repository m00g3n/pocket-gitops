ROOT := $(shell pwd)
BASE := ${ROOT}/kustomize/base
K3S := ${ROOT}/kustomize/k3s
K8S := ${ROOT}/kustomize/k8s
GITEA := ${ROOT}/kustomize/gitea


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
	mkdir -p ${K3S}/configs
	@docker run -i -t --rm \
	--network=hyc \
	kroniak/ssh-client \
	ssh-keyscan ${HOST} \
	> ${FLUX_KNOWN_HOSTS}

FLUX_KNOWN_HOSTS_K8S := ${K8S}/configs/known_hosts

${FLUX_KNOWN_HOSTS_K8S}:
	mkdir -p ${K8S}/configs
	${ROOT}/hack/ssh_keyscan.sh > ${FLUX_KNOWN_HOSTS_K8S}

FLUX_YAML := ${BASE}/flux.yaml

${FLUX_YAML}:
	@fluxctl install \
	--git-url="git@gitea:HYC/hyctestk3s.git" \
	--git-email="hyc-bot@hyc.com" \
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

apply-k8s-flux: clean ${FLUX_KNOWN_HOSTS_K8S} ${FLUX_YAML}
	@${ROOT}/hack/createGitUser.sh ${GIT_PASSWD}
	kustomize build ${K8S}  | kubectl apply -f -
	kubectl -n flux rollout status deployment/flux
	
clean:
	rm -f ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_KNOWN_HOSTS_K8S} ${FLUX_YAML}

all: clean apply-k3s;

.PHONY: apply-k8s-gitea apply-k8s-flux apply-k3s clean all
