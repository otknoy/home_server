# メトリクスの収集量削減

保存期間は2年のまま、未使用の系列と不要なラベル、収集頻度を減らす。

## 変更内容

- API Server の8種類のヒストグラムについて、`config/prometheus.yml` の `metric_relabel_configs` に列挙した `_bucket` のみ保存対象から外す。`_sum`・`_count` は残す。対象のヒストグラムの分位点は新しいデータでは計算できなくなる。
- API Server、kubelet、cAdvisor、SNMP exporter 自身は60秒収集にする。kube-state-metrics は既存の60秒を維持する。
- その他は30秒を維持する。温湿度の検知速度と node-exporter の短い計算窓を維持するため、全ジョブ一律の延長はしない。60秒収集では短時間のピークが見えにくくなり、異常検知も遅くなる可能性がある。
- Node のラベルはホスト名、Pod・Service のラベルは設定に列挙したアプリケーション識別用に限定する。`namespace`・`pod`・`service`・`instance` は維持する。ラベルの限定は系列数の大幅削減より、ラベル量と更新時の系列増加を抑える目的で行う。

## 調査時の状態

2026-10-23 の適用前の実測値。実行時刻や Pod の入れ替わりで値は変動する。

| 項目 | 系列数 |
| --- | ---: |
| Head 全体 | 64,953 |
| API Server の現在の系列 | 40,131 |
| 除外対象のバケット | 29,782 |

除外対象は Head 全体の約46%に相当する。Head と瞬間クエリでは集計期間が異なるため、削減率は目安。リポジトリ内のダッシュボード・アラートに対象バケットへの参照はなく、稼働中の Grafana のダッシュボード一覧もリポジトリの構成と一致していた。同じ scrape URL の重複はなかった。

同日の約6時間の試験では、Head 系列数は約65,000から35,000、取り込み量は約2,098件/秒から721件/秒に減少した。メモリの1時間平均は約1.63 GiBから436 MiBに減少したが、再起動の影響も含む。直近5時間の全収集先は正常で、アラート評価・TSDB 圧縮のエラーはなく、主要な CPU・温度クエリはデータを継続取得できた。

## 検証と適用後の確認

```sh
yamlfmt -lint k8s/manifest/base/monitoring/prometheus/config/prometheus.yml
docker run --rm --entrypoint /bin/promtool \
  -v "$PWD/k8s/manifest/base/monitoring/prometheus/config:/etc/prometheus:ro" \
  prom/prometheus:v3.15.1-distroless check config --syntax-only /etc/prometheus/prometheus.yml
kubectl kustomize k8s/manifest/base > /tmp/home-server-base-rendered.yaml
kubectl apply --dry-run=client -k k8s/manifest/base
```

通常の GitOps 経由で反映後、以下を適用前と比較する。

```promql
# ジョブ別の現在の系列数
count by (job) ({__name__!=""})

# 取り込み量、Head 系列数、メモリ、保存ブロック容量
rate(prometheus_tsdb_head_samples_appended_total[5m])
prometheus_tsdb_head_series
process_resident_memory_bytes{job="prometheus"}
prometheus_tsdb_storage_blocks_bytes

# 収集の正常性と保存前フィルタリング後のサンプル数
up
scrape_samples_post_metric_relabeling
```

反映後10分程度で収集の正常性、ジョブ別系列数、取り込み量、Grafana の表示とアラート式の評価を確認する。古い系列が Head からなくなるまで数時間待ち、メモリも比較する。保存容量は既存の2年分が残るため直ちには減らない。日単位の増加量を数日比較する。

障害時は今回の設定差分を戻し、通常の GitOps 経由で再反映する。既存履歴の手動削除はしない。除外中のバケットの履歴と、60秒収集中の30秒間隔のデータは後から復元できない。
