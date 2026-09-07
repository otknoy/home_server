#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Update these tags deliberately.
ARGOCD_TAG=v3.5.1
CERT_MANAGER_TAG=v1.17.0
INGRESS_NGINX_TAG=controller-v1.15.1
METALLB_TAG=v0.16.1
NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG=nfs-subdir-external-provisioner-4.0.18

curl -fsSL "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_TAG/manifests/install.yaml" \
  -o "$script_dir/init/argocd/upstream/install.yaml"
curl -fsSL "https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_TAG/cert-manager.yaml" \
  -o "$script_dir/init/cert-manager/upstream/cert-manager.yaml"
curl -fsSL "https://raw.githubusercontent.com/kubernetes/ingress-nginx/$INGRESS_NGINX_TAG/deploy/static/provider/cloud/deploy.yaml" \
  -o "$script_dir/init/ingress-nginx/upstream/deploy.yaml"

metallb_dir="$script_dir/init/metallb-system/upstream/config"
rm -rf -- "$metallb_dir"
mkdir -p "$metallb_dir"
curl -fsSL "https://github.com/metallb/metallb/archive/refs/tags/$METALLB_TAG.tar.gz" |
  tar -xzf - --strip-components=2 -C "$metallb_dir" --wildcards \
    '*/config/native/*' \
    '*/config/crd/*' \
    '*/config/rbac/*' \
    '*/config/controllers/*' \
    '*/config/webhook/*'

nfs_dir="$script_dir/base/nfs-provisioner/upstream/deploy"
rm -rf -- "$nfs_dir"
mkdir -p "$nfs_dir"
curl -fsSL "https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/archive/refs/tags/$NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG.tar.gz" |
  tar -xzf - --strip-components=2 -C "$nfs_dir" --wildcards '*/deploy/*'

find "$script_dir/init/argocd/upstream" "$script_dir/init/cert-manager/upstream" \
  "$script_dir/init/ingress-nginx/upstream" "$script_dir/init/metallb-system/upstream" \
  "$script_dir/base/nfs-provisioner/upstream" -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 |
  xargs -0 yamlfmt
sed -i '${/^$/d;}' "$metallb_dir/native/ns.yaml" "$metallb_dir/webhook/patches/patch_webhook_configuration.yaml"
