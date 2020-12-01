# Pocket GitOps

This repository contains a simple local environment setup to experiment with GitOps. 

## Prerequesites

- docker
- docker-compose
- kubectl
- make
- kustomize
- fluxctl

## Clone this repository

```bash
git clone https://github.com/m00g3n/pocket-gitops.git 
cd pocket-gitops
```

## Starting cluster

```bash
K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM} docker-compose up -d
```

Wait until k8s is up and running.
Than create an organization and repository in Gitea.

## Provision cluster

```bash
export KUBECONFIG=./kubeconfig.yaml
make all GIT_USER=<flux-service-account> GIT_EMAIL=<email> GIT_URL=<git-repository>
```

## Shutting down the cluster

```bash
K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM} docker-compose down
```
