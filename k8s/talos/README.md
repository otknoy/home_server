# talos linux

## generate talos manifest

```sh
$ ./gen_config.sh
```

```sh
talosctl gen config my-k8s-cluster https://192.168.0.18:6443 \
	 --force \
	 --config-patch @patch/all.yaml \
	 --config-patch-control-plane @patch/controlplane.yaml \
	 --config-patch-worker @patch/worker.yaml \
	 --with-secrets secrets.yaml
```

## apply

```sh
$ talosctl -n 192.168.0.18 apply-config -f controlplane.yaml --dry-run
```

## upgrade talos linux

```sh
$ talosctl upgrade \
  --image factory.talos.dev/metal-installer/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba:v1.14
```

## upgrade kubernetes

```sh
$ talosctl upgrade-k8s --to 1.36.4
```

## memo

re-create talosconfig
```sh
$ talosctl kubeconfig -n 192.168.0.18 -e 192.168.0.18 --talosconfig ./talosconfig
```
