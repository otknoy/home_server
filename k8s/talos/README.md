# talos linux

## Usage

```sh
$ make generate
```

生成した設定を dry-run で検証します。

```sh
$ make validate
```

検証後、設定を適用します。

```sh
$ make apply
```

Talos Linux と Kubernetes をアップグレードします。バージョンは
`Makefile` 冒頭の `TALOS_VERSION` と `KUBERNETES_VERSION` で管理します。
`TALOS_CONFIG_VERSION` はマシン設定を再現するための生成契約であり、
Talos Linux のアップグレード時には変更しません。

```sh
$ make upgrade
$ make upgrade-k8s
```

状態とバージョンを確認します。

```sh
$ make health
$ make versions
```

## Re-create kubeconfig

```sh
$ make kubeconfig
```
