#!/bin/sh

talosctl gen config my-k8s-cluster https://192.168.0.18:6443 \
	 --with-secrets secrets.yaml \
	 --kubernetes-version 1.33.7 \
	 --talos-version 1.12.0 \
	 --config-patch @patch/controlplane.yaml \
	 --force

# talosctl gen secrets -o secrets.yaml

# talosctl gen config --with-secrets secrets.yaml my-k8s-cluster https://192.168.0.18:6443

# talosctl apply-config --dry-run -n 192.168.0.18 --file controlplane.yaml
