# Pocket GitOps

This repository contains...

## Prerequesites

- docker
- docker-compose
- kubectl
- make
- kustomize
- fluxctl

## Clone this repository

```bash
git clone https://...
```

## Starting cluster

```bash
K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM} docker-compose up
```

Wait until k8s is up and running.

## Provision cluster

```bash
make clean-apply-k3s
```

## Shutting down the cluster