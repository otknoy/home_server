## argocd

```
$ kubectl create namespace argocd
$ kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## metrics-server

https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

```sh
$ wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml \
  -O manifest/base/kube-system/metrics-server/components.yaml
```

## tailscale-operator

https://github.com/tailscale/tailscale/tree/main/cmd/k8s-operator/deploy


```sh
$ VERSION=v1.102.2
$ wget "https://raw.githubusercontent.com/tailscale/tailscale/refs/tags/${VERSION}/cmd/k8s-operator/deploy/manifests/operator.yaml" \
  -O manifest/init/tailscale-k8s-operator.yaml
```
