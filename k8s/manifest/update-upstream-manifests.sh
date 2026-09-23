#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

update_yaml() {
  local url=$1 destination=$2 staging
  staging=$(mktemp "${destination}.tmp.XXXXXX")
  if ! curl -fsSL "$url" -o "$staging" || [[ ! -s "$staging" ]]; then
    rm -f -- "$staging"
    return 1
  fi
  chmod 644 -- "$staging"
  mv -- "$staging" "$destination"
}

update_archive_directory() {
  local url=$1 destination=$2 strip_components=$3 staging
  shift 3
  staging=$(mktemp -d "$(dirname -- "$destination")/.upstream.XXXXXX")
  if ! curl -fsSL "$url" |
    tar -xzf - --strip-components="$strip_components" -C "$staging" --wildcards "$@"; then
    rm -rf -- "$staging"
    return 1
  fi
  if [[ -z $(find "$staging" -type f -print -quit) ]]; then
    rm -rf -- "$staging"
    return 1
  fi
  rm -rf -- "$destination"
  mv -- "$staging" "$destination"
}

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

update_yaml "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_TAG/manifests/install.yaml" \
  "$script_dir/bootstrap/argocd/upstream/install.yaml"
update_yaml "https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_TAG/cert-manager.yaml" \
  "$script_dir/platform/cert-manager/upstream/cert-manager.yaml"
update_yaml "https://raw.githubusercontent.com/kubernetes/ingress-nginx/$INGRESS_NGINX_TAG/deploy/static/provider/cloud/deploy.yaml" \
  "$script_dir/platform/ingress-nginx/upstream/deploy.yaml"
update_yaml "https://github.com/bitnami-labs/sealed-secrets/releases/download/$SEALED_SECRETS_TAG/controller.yaml" \
  "$script_dir/platform/sealed-secrets/upstream/controller.yaml"
update_yaml "https://raw.githubusercontent.com/tailscale/tailscale/$TAILSCALE_OPERATOR_TAG/cmd/k8s-operator/deploy/manifests/operator.yaml" \
  "$script_dir/platform/tailscale/upstream/operator.yaml"

update_archive_directory "https://github.com/metallb/metallb/archive/refs/tags/$METALLB_TAG.tar.gz" \
  "$script_dir/platform/metallb-system/upstream/config" 2 \
  '*/config/native/*' \
  '*/config/crd/*' \
  '*/config/rbac/*' \
  '*/config/controllers/*' \
  '*/config/webhook/*'

update_archive_directory "https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/archive/refs/tags/$NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG.tar.gz" \
  "$script_dir/platform/nfs-provisioner/upstream/deploy" 2 '*/deploy/*'

update_archive_directory "https://github.com/kubernetes/kube-state-metrics/archive/refs/tags/$KUBE_STATE_METRICS_TAG.tar.gz" \
  "$script_dir/platform/kube-system/kube-state-metrics/upstream/standard" 3 '*/examples/standard/*.yaml'

find "$script_dir/bootstrap/argocd/upstream" "$script_dir/platform/cert-manager/upstream" \
  "$script_dir/platform/ingress-nginx/upstream" "$script_dir/platform/metallb-system/upstream" \
  "$script_dir/platform/kube-system/kube-state-metrics/upstream" \
  "$script_dir/platform/sealed-secrets/upstream" \
  "$script_dir/platform/nfs-provisioner/upstream" "$script_dir/platform/tailscale/upstream" \
  -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 |
  xargs -0 yamlfmt
