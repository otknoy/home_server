#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=upstream-versions.sh
source "$script_dir/upstream-versions.sh"

download() {
  local url=$1
  local destination=$2

  curl --fail --silent --show-error --location --output "$destination" "$url"
}

replace_file() {
  local url=$1
  local destination=$2
  local temporary_file

  temporary_file=$(mktemp)
  download "$url" "$temporary_file"
  install -D -m 0644 "$temporary_file" "$destination"
  rm -f -- "$temporary_file"
}

replace_directory_from_archive() {
  local url=$1
  local archived_path=$2
  local destination=$3
  local temporary_directory archive source

  temporary_directory=$(mktemp -d)
  archive="$temporary_directory/archive.tar.gz"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$temporary_directory"
  source=$(find "$temporary_directory" -mindepth 2 -maxdepth 4 -type d -path "*/$archived_path" -print -quit)

  if [[ -z "$source" ]]; then
    echo "Archive does not contain $archived_path" >&2
    exit 1
  fi

  rm -rf -- "$destination"
  install -d "$(dirname -- "$destination")"
  mv "$source" "$destination"
  rm -rf -- "$temporary_directory"
}

replace_parent_directory_from_archive() {
  local url=$1
  local archived_path=$2
  local destination=$3
  local temporary_directory archive source

  temporary_directory=$(mktemp -d)
  archive="$temporary_directory/archive.tar.gz"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$temporary_directory"
  source=$(find "$temporary_directory" -mindepth 3 -maxdepth 4 -type d -path "*/$archived_path" -print -quit)

  if [[ -z "$source" ]]; then
    echo "Archive does not contain $archived_path" >&2
    exit 1
  fi

  rm -rf -- "$destination"
  install -d "$(dirname -- "$destination")"
  mv "$(dirname -- "$source")" "$destination"
  rm -rf -- "$temporary_directory"
}

retain_directories() {
  local directory=$1
  local temporary_directory name
  shift

  temporary_directory=$(mktemp -d)
  for name in "$@"; do
    mv "$directory/$name" "$temporary_directory/$name"
  done
  rm -rf -- "$directory"
  install -d "$directory"
  for name in "$@"; do
    mv "$temporary_directory/$name" "$directory/$name"
  done
  rm -rf -- "$temporary_directory"
}

replace_file \
  "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_TAG/manifests/install.yaml" \
  "$script_dir/init/argocd/upstream/install.yaml"

replace_file \
  "https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_TAG/cert-manager.yaml" \
  "$script_dir/init/cert-manager/upstream/cert-manager.yaml"

replace_file \
  "https://raw.githubusercontent.com/kubernetes/ingress-nginx/$INGRESS_NGINX_TAG/deploy/static/provider/cloud/deploy.yaml" \
  "$script_dir/init/ingress-nginx/upstream/deploy.yaml"

replace_parent_directory_from_archive \
  "https://github.com/metallb/metallb/archive/refs/tags/$METALLB_TAG.tar.gz" \
  "config/native" \
  "$script_dir/init/metallb-system/upstream/config"
retain_directories "$script_dir/init/metallb-system/upstream/config" native crd rbac controllers webhook

replace_directory_from_archive \
  "https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/archive/refs/tags/$NFS_SUBDIR_EXTERNAL_PROVISIONER_TAG.tar.gz" \
  "deploy" \
  "$script_dir/base/nfs-provisioner/upstream/deploy"
