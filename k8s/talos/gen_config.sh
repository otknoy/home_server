#!/bin/sh

talosctl gen config my-k8s-cluster https://192.168.0.18:6443 \
	 --force \
	 --config-patch @patch/all.yaml \
	 --config-patch-control-plane @patch/controlplane.yaml \
	 --config-patch-worker @patch/worker.yaml \
	 --with-secrets secrets.yaml 


# talosctl gen secrets -o secrets.yaml

# talosctl gen config --with-secrets secrets.yaml my-k8s-cluster https://192.168.0.18:6443

# talosctl apply-config --dry-run -n 192.168.0.18 --file controlplane.yaml
