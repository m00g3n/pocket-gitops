#!/bin/bash

POD_NAME=$(kubectl get pods -n gitea -l "app.kubernetes.io/name=gitea" -ojson | jq --raw-output '.items[0].metadata.name')
kubectl exec -n gitea $POD_NAME -- su git -c "gitea admin create-user --username flux-bot --password $1 --email flux@hyc.com  --admin --must-change-password=false"
kubectl exec -n gitea $POD_NAME -- su git -c "gitea admin create-user --username m00g3n --password $1 --email marcin@hyc.com --admin --must-change-password=false"
kubectl exec -n gitea $POD_NAME -- su git -c "gitea admin create-user --username pPrecel --password $1 --email filip@hyc.com --admin --must-change-password=false"

echo "done"
