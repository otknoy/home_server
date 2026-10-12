# Kubernetes クラスタ運用

`manifest/bootstrap/`は初期導入・復旧用です。導入後は専用Application `argocd`でArgo CD自身を管理し、手動で同期します。`manifest/platform/`と`manifest/base/`はArgo CDが自動同期します。SecretはSealed Secretsで管理し、平文や秘密鍵をリポジトリへ保存しません。

## 初期セットアップ

```bash
cd k8s
kubectl apply -k manifest/platform/sealed-secrets
kubectl wait --for=condition=Established crd/sealedsecrets.bitnami.com --timeout=5m
kubectl rollout status deployment/sealed-secrets-controller -n kube-system --timeout=5m

# クラスタ再構築時のみ、Applicationを適用する前に秘密鍵を復元する
kubectl apply -f /path/to/sealed-secrets-key.yaml
kubectl rollout restart deployment/sealed-secrets-controller -n kube-system

kubectl apply --server-side -k manifest/bootstrap/argocd
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=5m
kubectl apply -f manifest/bootstrap/applications/argocd.yaml
kubectl apply -f manifest/bootstrap/applications/home-server-platform.yaml
kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/home-server-platform -n argocd --timeout=10m
kubectl wait --for=jsonpath='{.status.health.status}'=Healthy application/home-server-platform -n argocd --timeout=10m
kubectl apply -f manifest/bootstrap/applications/home-server.yaml
```

`manifest/platform`と`manifest/base`はArgo CDが同期するため、通常は手動で適用しません。

## Argo CD自身の更新・復旧

`./manifest/update-upstream-manifests.sh`でupstreamを更新し、差分を確認してmainへマージします。その後、Argo CD UIでApplication `argocd`をRefreshし、差分を確認してSyncします。Pruneは選択しません。

Application `argocd`は自動同期・自動pruneを無効にし、削除連動のfinalizerを付けません。Applicationを削除する場合は非カスケード削除を選択します。CRDのannotationサイズ制限を避けるため、同期には`ServerSideApply=true`を設定しています。`argocd-secret`の`data`はArgo CDが管理するため、比較・同期の対象から除外します。

Argo CDが停止して同期できない場合は、正常なマニフェストをcheckoutして手動で復旧します。

```bash
kubectl apply --server-side -k manifest/bootstrap/argocd
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=5m
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=5m
```

## Secretの追加・更新

Secretは利用するリソースと同じKustomization配下へ配置します。名前とnamespaceは暗号化後に変更できません。

```bash
read -rsp 'EXAMPLE_KEY: ' secret_value; printf '\n'
kubectl create secret generic example-secret \
  -n app \
  --from-literal=EXAMPLE_KEY="$secret_value" \
  --dry-run=client -o yaml |
kubeseal \
  --controller-name sealed-secrets-controller \
  --controller-namespace kube-system \
  --format yaml \
  >manifest/base/app/example-secret.yaml
unset secret_value
```

生成したファイルを対象の`kustomization.yaml`へ追加し、検証後にコミット・pushします。更新時も同じコマンドで再生成します。

```bash
yamlfmt manifest/base/app/example-secret.yaml
kubectl kustomize manifest/base >/dev/null
kubectl apply --dry-run=client -k manifest/base
kubectl wait --for=condition=Synced sealedsecret/example-secret -n app --timeout=5m
```

Secretを環境変数で利用しているPodには自動反映されないため、必要に応じてDeploymentを再起動します。

## 秘密鍵のバックアップ

```bash
kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml >/secure/path/sealed-secrets-key.yaml
```

すべての世代を安全な場所へ保管し、鍵が追加されたら取り直します。upstreamマニフェストは`./manifest/update-upstream-manifests.sh`で更新します。
