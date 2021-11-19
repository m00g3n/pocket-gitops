#!/bin/bash

ip=""
while [ -z $ip ]; do
  ip=$(kubectl get svc $2 --namespace $1 --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$ip" ] && sleep 1
done
echo "$1 address: $ip"

if [[ $(grep -rnw '/etc/hosts' -e $3) != "" ]]; then
    cat /etc/hosts | sed "s/.*$3.*/$ip $3/g" | sudo tee /etc/hosts > /dev/null
else
    echo "$ip $3" | sudo tee -a /etc/hosts > /dev/null
fi
echo "hosts updated!"
