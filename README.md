# Pocket GitOps

This repository contains a simple environment setup to experiment with GitOps localy and on cloud. 

## Run whole flow locally

Prerequisites:

- docker
- docker-compose
- kubectl
- make
- kustomize
- fluxctl

### Start `Gitea` container

```bash
docker-compose up -d
```

### In your web browser go to the address below, click the `Register` button, create `hyc-bot` service account and then the `Install Gitea`
```http
https://localhost:3000
```

### Create HYC organization and migrate the repository. Make sure to mark HYC as repository owner.

```http
https://github.com/m00g3n/hyctestk3s.git
```

### Navigate `pocket-gitops` directory and run k3d with the `start-k3d` recipe. Run the following

```bash
make start-k3d
```

### Clone repository 

```bash
git clone http://localhost:3000/HYC/hyctestk3s.git
cd hyctestk3s
```

### Build container image and push it to internal docker registry

```bash
make build TAG=1 && make push TAG=1
```

### Navigate to `pocket-gitops` directory and install flux agent, run the following command

```bash
make apply-k3s-flux
```

### Update SSH key

1. Run following command in the shell and copy the whole output:

    ```bash
    fluxctl identity --k8s-fwd-ns flux
    ```

2. Using the `hyc-bot` account create new SSH key with data from the previous step.

### Sync flux

```bash
fluxctl sync --k8s-fwd-ns flux
```

## Run whole flow on your own cluster

Prerequisites:

- kubectl
- make
- kustomize
- fluxctl

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

### Prepare the git repository

1. Go to the `gitea.hyc.com` in you browser and login as `flux-bot`.
2. Create the `HYC` organization and the `infrastructure` repository inside it. Make sure to store workloads in the infrastructure directory.
3. Prepare whole infrastructure inside repository.

### Update SSH key

1. Run following command in the shell and copy the whole output:

    ```bash
    fluxctl identity --k8s-fwd-ns flux
    ```

2. Using the `flux-bot` account create new SSH key with data from the previous step.

### Sync flux

```bash
fluxctl sync  --k8s-fwd-ns flux
```
