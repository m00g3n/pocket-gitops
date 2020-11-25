ROOT := $(shell pwd)
BASE := ${ROOT}/kustomize/base
K3S := ${ROOT}/kustomize/k3s

DOCKER_IP_ADDR_TPL='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
GITEA_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /gitea)
REGISTRY_IP_ADDRESS=$(shell docker inspect -f ${DOCKER_IP_ADDR_TPL} /registry)

COREDNS_PATCH_YAML := ${K3S}/coredns.patch.yaml

${COREDNS_PATCH_YAML}:
	sed "s/__GITEA_IP_ADDRESS__/${GITEA_IP_ADDRESS}/; s/__REGISTRY_IP_ADDRESS__/${REGISTRY_IP_ADDRESS}/" \
	./coredns.template.patch.yaml > ${COREDNS_PATCH_YAML}

NAMESPACE := 'flux'
HOST := 'gitea'
FLUX_SSH_CONFIG_YAML := ${K3S}/flux-ssh-config.yaml

${FLUX_SSH_CONFIG_YAML}:
	$(eval tmpfile=$(shell mktemp /tmp/known_hosts.XXXXXX))
	exec 3>"$tmpfile"

	docker run -i -t --rm \
	--network=hyc-demo \
	kroniak/ssh-client \
	ssh-keyscan ${HOST} \
	> $tmpfile

	kubectl create configmap flux-ssh-config \
	-n ${NAMESPACE} \
	--from-file=known_hosts=$tmpfile \
	-oyaml \
	--dry-run \
	--save-config \
	> ${K3S}/flux-ssh-config.yaml

	rm "$tmpfile"

FLUX_YAML := ${BASE}/flux.yaml

${FLUX_YAML}:
	fluxctl install \
	--git-user=admin123 \
	--git-email=me@test.you \
	--git-url=git@gitea:hyc-gitops/dywan.git \
	--namespace=flux > ${FLUX_YAML}

generate: ${COREDNS_PATCH_YAML} ${FLUX_SSH_CONFIG_YAML} ${FLUX_YAML};

apply-k3s: generate
	kubectl config use-context default --kubeconfig='kubeconfig.yaml'
	kubectl apply -k ${K3S}
	kubectl -n flux rollout status deployment/flux

clean-apply-k3s: clean apply-k3s;

clean:
	rm -f ${COREDNS_PATCH_YAML} ${FLUX_SSH_CONFIG_YAML} ${FLUX_YAML}

.PHONY: apply-k3s clean clean-apply-k38s