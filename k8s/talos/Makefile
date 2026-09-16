CLUSTER_NAME := my-k8s-cluster
CLUSTER_ENDPOINT := https://192.168.0.18:6443
NODE := 192.168.0.18

TALOS_VERSION := v1.14.1
TALOS_CONFIG_VERSION := v1.12.2
KUBERNETES_VERSION := 1.36.4
TALOS_SCHEMATIC_ID := 376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba
TALOS_IMAGE := factory.talos.dev/metal-installer/$(TALOS_SCHEMATIC_ID):$(TALOS_VERSION)

.PHONY: generate validate apply upgrade upgrade-k8s health versions kubeconfig

generate:
	talosctl gen config $(CLUSTER_NAME) $(CLUSTER_ENDPOINT) \
		--talos-version $(TALOS_CONFIG_VERSION) \
		--kubernetes-version $(KUBERNETES_VERSION) \
		--force \
		--config-patch-control-plane @patch/controlplane.yaml \
		--with-secrets secrets.yaml

validate: generate
	talosctl apply-config \
		--dry-run \
		--nodes $(NODE) \
		--file controlplane.yaml

apply: validate
	talosctl apply-config \
		--nodes $(NODE) \
		--file controlplane.yaml

upgrade:
	talosctl health
	talosctl upgrade \
		--nodes $(NODE) \
		--image $(TALOS_IMAGE)
	talosctl health

upgrade-k8s:
	talosctl upgrade-k8s --to $(KUBERNETES_VERSION)

health:
	talosctl health
	kubectl get nodes -o wide

versions:
	talosctl version
	kubectl version

kubeconfig:
	talosctl kubeconfig \
		--nodes $(NODE) \
		--endpoints $(NODE) \
		--talosconfig ./talosconfig
