#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Update these tags deliberately.
# renovate: datasource=github-tags depName=argoproj/argo-cd versioning=semver
ARGOCD_TAG=v3.5.3
# renovate: datasource=github-releases depName=cert-manager/cert-manager versioning=semver
CERT_MANAGER_TAG=v1.21.2
# renovate: datasource=github-tags depName=kubernetes/ingress-nginx versioning=semver extractVersion=^controller-v(?<version>.*)$
INGRESS_NGINX_TAG=controller-v1.15.1
# renovate: datasource=github-tags depName=metallb/metallb versioning=semver
METALLB_TAG=v0.16.1
# renovate: datasource=github-releases depName=bitnami-labs/sealed-secrets versioning=semver
SEALED_SECRETS_TAG=v0.40.0
# renovate: datasource=github-tags depName=kubernetes-sigs/nfs-subdir-external-provisioner versioning=semver extractVersion=^nfs-subdir-external-provisioner-(?<version>.*)$
NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG=nfs-subdir-external-provisioner-4.0.18
# renovate: datasource=github-releases depName=kubernetes/kube-state-metrics versioning=semver
KUBE_STATE_METRICS_TAG=v2.20.0
# renovate: datasource=docker depName=tailscale/k8s-operator versioning=semver
TAILSCALE_OPERATOR_TAG=v1.102.4

curl -fsSL "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_TAG/manifests/install.yaml" \
  -o "$script_dir/bootstrap/argocd/upstream/install.yaml"
curl -fsSL "https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_TAG/cert-manager.yaml" \
  -o "$script_dir/platform/cert-manager/upstream/cert-manager.yaml"
curl -fsSL "https://raw.githubusercontent.com/kubernetes/ingress-nginx/$INGRESS_NGINX_TAG/deploy/static/provider/cloud/deploy.yaml" \
  -o "$script_dir/platform/ingress-nginx/upstream/deploy.yaml"
curl -fsSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/$SEALED_SECRETS_TAG/controller.yaml" \
  -o "$script_dir/platform/sealed-secrets/upstream/controller.yaml"

tailscale_manifest="$script_dir/platform/tailscale/operator.yaml"
curl -fsSL "https://raw.githubusercontent.com/tailscale/tailscale/$TAILSCALE_OPERATOR_TAG/cmd/k8s-operator/deploy/manifests/operator.yaml" \
  -o "$tailscale_manifest"

metallb_dir="$script_dir/platform/metallb-system/upstream/config"
rm -rf -- "$metallb_dir"
mkdir -p "$metallb_dir"
curl -fsSL "https://github.com/metallb/metallb/archive/refs/tags/$METALLB_TAG.tar.gz" |
  tar -xzf - --strip-components=2 -C "$metallb_dir" --wildcards \
    '*/config/native/*' \
    '*/config/crd/*' \
    '*/config/rbac/*' \
    '*/config/controllers/*' \
    '*/config/webhook/*'

nfs_dir="$script_dir/platform/nfs-provisioner/upstream/deploy"
rm -rf -- "$nfs_dir"
mkdir -p "$nfs_dir"
curl -fsSL "https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/archive/refs/tags/$NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG.tar.gz" |
  tar -xzf - --strip-components=2 -C "$nfs_dir" --wildcards '*/deploy/*'

ksm_dir="$script_dir/platform/kube-system/kube-state-metrics/upstream/standard"
rm -rf -- "$ksm_dir"
mkdir -p "$ksm_dir"
curl -fsSL "https://github.com/kubernetes/kube-state-metrics/archive/refs/tags/$KUBE_STATE_METRICS_TAG.tar.gz" |
  tar -xzf - --strip-components=3 -C "$ksm_dir" --wildcards '*/examples/standard/*.yaml'

sed -i '${/^$/d;}' "$metallb_dir/native/ns.yaml" "$metallb_dir/webhook/patches/patch_webhook_configuration.yaml"

find "$script_dir/bootstrap/argocd/upstream" "$script_dir/platform/cert-manager/upstream" \
  "$script_dir/platform/ingress-nginx/upstream" "$script_dir/platform/metallb-system/upstream" \
  "$script_dir/platform/kube-system/kube-state-metrics/upstream" \
  "$script_dir/platform/sealed-secrets/upstream" \
  "$script_dir/platform/nfs-provisioner/upstream" "$script_dir/platform/tailscale" \
  -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 |
  xargs -0 yamlfmt
