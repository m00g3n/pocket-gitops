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
	docker run -i -t --rm \
	--network=hyc \
	kroniak/ssh-client \
	ssh-keyscan ${HOST} \
	> ${FLUX_KNOWN_HOSTS}

FLUX_YAML := ${BASE}/flux.yaml

GIT_USER=hyc-bot
GIT_EMAIL=hyc-bot@hyc.com
GIT_URL=git@gitea:HYC/hyctestk3s.git

${FLUX_YAML}:
	fluxctl install \
	--git-user=${GIT_USER} \
	--git-email=${GIT_EMAIL} \
	--git-url=${GIT_URL} \
	--namespace=flux > ${FLUX_YAML}

start-k3d:
	@k3d cluster create hyc \
		--network=hyc \
		--registry-create=k3d-hyc-registry.localhost:5001
		--wait

start-gitea:
	@docker run \
		-d \
		--name gitea \
		--env USER_UID=1000 \
		--env USER_GID=1000 \
		--restart=always \
		--volume gitea:/data \
		--volume /etc/timezone:/etc/timezone:ro \
		--volume /etc/localtime:/etc/localtime:ro \
		--network=hyc \
		-p 3000:3000 \
		-p 222:22 \
		gitea/gitea:1.12.6

apply-k3s-flux: clean ${FLUX_KNOWN_HOSTS} ${COREDNS_COREFILE} ${FLUX_YAML};
	@kustomize build ${K3S} | kubectl apply -f -
	@kubectl -n flux rollout status deployment/flux

apply-k8s: ${FLUX_YAML}
	kustomize build ${BASE} | kubectl apply -f -
	kubectl -n flux rollout status deployment/flux

clean:
	rm -f ${COREDNS_COREFILE} ${FLUX_KNOWN_HOSTS} ${FLUX_YAML} || true

.PHONY: apply-k3s-flux apply-k8s clean
