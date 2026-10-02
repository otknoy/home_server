---
name: update-talos-k8s
description: home_server 専用の Talos / Kubernetes 更新。互換性を調べて候補を提示し、ユーザーの選択後に Makefile を更新する。実クラスタ更新を依頼された場合は、正常性確認・PR 作成・CI 確認・マージまで行う。
---

# Talos / Kubernetes の更新

対象は `k8s/talos/Makefile`。Renovate は追加しない。ユーザーが指定した作業範囲を優先する。

## 1. 現状と公式情報を確認

- リポジトリの指示、差分、Makefile、`k8s/talos/README.md`、関連パッチを読む。設定値と実機の稼働バージョンを区別する。
- 指定バージョンまたは公開済み安定版について、実行時に公式のサポート範囲・更新手順・変更点を確認する。各更新段階の互換性、中間バージョン、更新順序を確認し、必要に応じて CLI、schematic の拡張機能、廃止 API への影響を調べる。互換性が不明な候補は採用しない。

参照: [Talos 文書](https://docs.siderolabs.com/talos/)（旧版は [talos.dev](https://www.talos.dev/)）、[Talos リリース](https://github.com/siderolabs/talos/releases)、[Kubernetes リリース](https://github.com/kubernetes/kubernetes/releases)、[version skew policy](https://kubernetes.io/releases/version-skew-policy/)。

## 2. 候補を提示して選択を待つ

更新後の組み合わせ、現状との差、互換性の根拠 URL、更新経路、注意点・未確認事項を表で比較する。推奨理由と更新見送りの選択肢も示す。

選択の回答が来るまで、編集・設定生成・クラスタ変更を行わない。具体的な更新先が既に選択済みなら、調査結果を示して同じ選択を再度求めない。非対応なら代替候補を提示する。調査のみ・見送りなら変更しない。

## 3. 選択した更新を実施

- Makefile の選択対象だけを変更し、Talos の `v` 付き、Kubernetes の `v` なし表記と既存 schematic を維持する。`make -n -C k8s/talos upgrade` / `upgrade-k8s` と `git diff --check` で検証する。
- `make generate` は secrets を使い `--force` で設定を書き出す。`make validate` も生成と実機接続を伴うため、ローカル検証として実行せず、依頼範囲に含まれる場合だけ入力・出力先・接続先を確認して実行する。
- 実クラスタ更新は明示的に依頼された場合だけ行う。実機の接続先・全対象ノード・バージョン・health・Pod 状態を確認し、etcd バックアップと復旧方法を準備する。単一ノードでは停止時間を説明し、実機状態に合う更新経路を一段階ずつ進める。
- 各段階で実際のバージョン、`talosctl health` の全項目、ノード Ready とスケジュール再開、更新前に Ready だった稼働ワークロードの復帰を確認する。完了済み Job は異常扱いしない。必要に応じてサービス疎通も確認する。異常時は次段階へ進まず、状態と復旧方針を報告する。無条件の再試行・ダウングレードは行わない。

## 4. 正常性と CI を確認してマージ

依頼された実クラスタ更新が正常に完了したら、追加確認を求めず、作業ブランチで関連差分だけをコミット・push し、main 向け PR を作成または更新する。PR に目的、更新前後のバージョン、影響対象、公式根拠、検証コマンドと実機確認結果・限界を記載する。最終 HEAD の必須 CI とマージ可否を確認し、成功した確認済み HEAD を指定して squash merge する。HEAD が変わったら再確認し、保護ルールを迂回しない。

実機の異常、必須確認の未完了、CI 失敗があればマージしない。ユーザーが PR 作成まで・マージ保留などを指定した場合は従う。GitHub の MERGED を確認後、ローカル main を fast-forward で更新する。

最後にバージョン、検証結果、未確認事項、PR URL と CI・マージ結果を報告する。ファイル編集と実クラスタ更新の完了を区別する。
