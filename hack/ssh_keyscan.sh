#!/bin/bash

kubectl run my-shell --image kroniak/ssh-client -- sleep 10000 > /dev/null
kubectl wait --for=condition=Ready pod/my-shell > /dev/null
kubectl exec my-shell -- ssh-keyscan gitea.gitea.svc.cluster.local
kubectl delete pod my-shell > /dev/null
