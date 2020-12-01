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
cd pocket-gitops.git 
```

## Starting cluster

```bash
k3s_token=${random}${random}${random} docker-compose up
```

Wait until k8s is up and running.

## Provision cluster

```bash
make all GIT_USER=<flux-service-account> GIT_EMAIL=<email> GIT_URL=<git-repository>
```

## Shutting down the cluster

```bash
k3s_token=${random}${random}${random} docker-compose down
```
