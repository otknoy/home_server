# Gateway API cutover

`home-server` の Envoy Gateway は、一時 IP `192.168.0.129` で ingress-nginx と
並行稼働する。旧 Service が `otknoy-k8s` を使っている間は、Envoy の Service を
Tailscale に公開しない。旧 Service を削除してから `cutover/` を適用し、LAN の
`192.168.0.128` と Tailscale 名を引き継ぐ。

1. この変更を `main` に反映し、Argo CD が Envoy Gateway と HTTPRoute を
   適用したことを確認する。`prune: false` なので旧リソースは残り、Application
   全体は `OutOfSync` のままになる場合がある。
2. 一時 IP で `/`、`/grafana/`、`/prometheus/`、`/alertmanager/`、
   `/pushgateway/` と各配下のページを確認する。Gateway の `Programmed`、
   HTTPRoute の `Accepted` と `ResolvedRefs` が `True` であることも確認する。
3. `kubectl delete svc ingress-nginx-controller -n ingress-nginx` で旧 Service の
   MetalLB IP と Tailscale 名を解放する。`kubectl get statefulset -n tailscale`
   で旧 ingress-nginx 用 proxy の削除を確認してから
   `kubectl apply -k k8s/manifest/platform/gateway/cutover` を実行する。
   この間は短時間の接続断が生じる。
4. Envoy の Service に `192.168.0.128` が割り当てられ、Tailscale に
   `otknoy-k8s` が登録されたら、LAN と Tailscale の両方で5経路を再確認する。
5. `platform/kustomization.yaml` の参照先を `./gateway/cutover` に変更して
   `main` に反映する。実クラスタと Git の設定が一致したら旧5 Ingress と
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
