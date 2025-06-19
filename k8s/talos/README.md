# talos linux

## generate talos manifest

```sh
talosctl gen config my-k8s-cluster https://192.168.0.18:6443 \
	 --force \
	 --config-patch @patch/all.yaml \
	 --config-patch-control-plane @patch/controlplane.yaml \
	 --config-patch-worker @patch/worker.yaml \
	 --with-secrets secrets.yaml
```

## upgrade talos linux

```sh
$ talosctl upgrade --image ghcr.io/siderolabs/installer:v1.10.4
```

## upgrade kubernetes

```sh
$ talosctl upgrade-k8s --to 1.32.6
```
