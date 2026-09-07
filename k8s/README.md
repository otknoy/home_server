# Kubernetes クラスタ初期セットアップ

`manifest/init/secret.yaml` を安全な保管場所から復元後、`k8s/` ディレクトリで実行します。

```bash
# ブートストラップコンポーネントを導入する
kubectl kustomize manifest/init
kubectl apply -k manifest/init

# Argo CD の Application CRD を待ってから、base の同期を開始する
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=5m
kubectl apply -f manifest/init/argocd/home-server.yaml

# Argo CD と base の同期状態を確認する
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=5m
kubectl wait --for=jsonpath='{.status.sync.status}'=Synced application/home-server -n argocd --timeout=10m
kubectl get application home-server -n argocd
kubectl get pods -A
```

`base` は Argo CD が同期するため、手動で適用しません。
