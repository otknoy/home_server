#!/bin/bash

kind create cluster --config=kind.yaml
# kind delete clusters my-cluster

# Ingress NGINX
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# ingress example
# kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
# sleep 15
# curl -v localhost:81/foo/hostname
# curl -v localhost:81/bar/hostname

# cluster init
kubectl apply -k manifest/cluster

# deploy apps
kubectl apply -k manifest/base/

