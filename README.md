# Pocket GitOps

This repository contains a simple local environment setup to experiment with GitOps. 

## Prerequisites

- docker
- docker-compose
- kubectl
- make
- kustomize
- fluxctl

## Run whole flow locally

### Clone this repository

```bash
git clone https://github.com/m00g3n/pocket-gitops.git 
cd pocket-gitops
```

### Starting cluster

```bash
K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM} docker-compose up -d
```

Wait until k8s is up and running.
Than create an organization and repository in Gitea.

### Provision cluster

```bash
export KUBECONFIG=./kubeconfig.yaml
make all GIT_USER=<flux-service-account> GIT_EMAIL=<email> GIT_URL=<git-repository>
```

### Shutting down the cluster

```bash
K3S_TOKEN=${RANDOM}${RANDOM}${RANDOM} docker-compose down
```

## Run whole flow on your own cluster

### Export password for all gitea users

```bash
export GIT_PASSWD=<your_password>
```

### Run the following command to install the gitea

```bash
make apply-k8s-gitea
```

### In your web browser go to the address below, click the `Register` button, and then the `Install Gitea`

```http
gitea.hyc.com
```

### Run the following command to install the flux

```bash
make apply-k8s-flux
```

### Create the HYC repository

1. Go to the `gitea.hyc.com` in you browser and login as `flux-bot`.
2. Create the `HYC` organization and the `infrastructure` repository inside it.
3. Prepare whole infrastructure inside repository.

### Update SSH key

1. Run following command in the shell and coppy the whole output:

    ```bash
    fluxctl identity --k8s-fwd-ns flux
    ```

2. Using the `flux-bot` account create new SSH key with data from the previous step.

### Sync flux

```bash
fluxctl sync  --k8s-fwd-ns flux
```
