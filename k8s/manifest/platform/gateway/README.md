# Gateway API cutover

`home-server` の Envoy Gateway は、LAN の `192.168.0.128` と Tailscale の
`otknoy-k8s` を ingress-nginx から引き継ぐ。Git の変更を `main` に反映する前に
旧 Service を削除すると、Argo CD が旧構成を再同期する可能性がある。

1. Envoy Gateway の CRD とコントローラーを導入し、別の MetalLB IP
   （初回検証では `192.168.0.129`）で Gateway と HTTPRoute を適用する。
2. 一時 IP で `/`、`/grafana/`、`/prometheus/`、`/alertmanager/`、
   `/pushgateway/` と各配下のページを確認する。Gateway の `Programmed`、
   HTTPRoute の `Accepted` と `ResolvedRefs` が `True` であることも確認する。
3. このリポジトリの変更を `main` に反映し、Argo CD の platform と base の
   同期を確認する。Envoy の Service はまだ旧 Service と同じ IP を取得できない。
   `prune: false` なので旧リソースは残る。
4. `kubectl delete svc ingress-nginx-controller -n ingress-nginx` で旧 Service の
   MetalLB IP と Tailscale 名を解放する。Envoy の Service に
   `192.168.0.128` が割り当てられ、Tailscale に `otknoy-k8s` が再登録される
   まで待つ。この間は短時間の接続断が生じる。
5. LAN と Tailscale の両方で5経路を再確認する。正常なら旧5 Ingress と
   ingress-nginx の残存リソースを削除する。

```sh
kubectl delete ingress web-dashboard-ing -n app
kubectl delete ingress alertmanager-ing grafana-ing prometheus-ing pushgateway-ing -n monitoring
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
kubectl delete ingressclass nginx
kubectl delete clusterrole ingress-nginx ingress-nginx-admission
kubectl delete clusterrolebinding ingress-nginx ingress-nginx-admission
kubectl delete namespace ingress-nginx
```

削除後に `kubectl get ingress -A` で nginx クラスの Ingress が残っていないこと、
`kubectl get svc -A` で `192.168.0.128` が Envoy の Service に割り当てられた
ことを確認する。Tailscale 専用の Ingress は残す。

切り戻す場合は Envoy の Service から `192.168.0.128` と Tailscale の公開設定を
外し、移行前の ingress-nginx マニフェストを再適用する。
