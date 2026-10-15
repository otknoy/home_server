---
name: update-upstream-pr
description: home_server 専用。update-upstream-manifests.sh を変更する PR を探して選択し、upstream 生成・commit・push・CI 確認・merge・Argo CD 同期と実機の更新確認まで行う。通常のイメージタグ更新 PR や Talos 更新は対象外。
---

# upstream 更新 PR の反映

対象リポジトリは `otknoy/home_server`。以下のパスはリポジトリルート基準。`git rev-parse --show-toplevel` と origin を確認し、リポジトリの指示と `k8s/README.md` を読む。

更新実行を依頼されたら、選択された PR の commit・push・merge・必要な Argo CD Sync・実機確認までを依頼範囲として進め、段階ごとの同じ許可は取り直さない。調査のみ、マージ保留などユーザーの指定を優先する。実行環境の権限承認は別途遵守する。

## 1. PR を探して選ぶ

- `gh pr list --repo otknoy/home_server --state open` で候補を取得し、全件を取得できるよう件数上限・ページネーションを確認する。各 PR の変更ファイルを調べ、`k8s/manifest/update-upstream-manifests.sh` を含むものだけを抽出する。タイトルや Renovate の作者名だけでは判定しない。
- 番号・URL・対象アプリ・更新前後のバージョン・CI 状況を提示し、毎回対象を選んでもらう。既に番号や URL が指定されていれば再選択は不要。候補がなければ報告して終了する。
- 複数選択された場合は選択順に、各 PR の実機確認を終えてから次へ進む。失敗したら残りの処理も停止する。

## 2. ブランチと実機を確認

- `git status --short` で既存変更と未追跡ファイル、現在のブランチを記録する。PR の base/head、HEAD SHA、変更一覧と差分を読む。スクリプトのタグ以外の処理変更も実行前に確認する。
- PR の head を fetch し、そのブランチへ `git switch` する。既存の同名ブランチや未 push コミットを上書きしない。既存変更を自動 stash・削除・commit しない。切り替え、整形または生成先と衝突する場合は停止して報告する。
- 競合・想定外の base・変更対象外の修正が混在する場合は内容を解決するまで実行・マージしない。無関係な変更の修復はこのスキルに含めない。
- `kubectl config current-context` と Application の接続先を確認し、更新対象のワークロード、Pod のイメージ・imageID・Ready、Application の revision・同期状態・正常性を記録する。Secret 本文や kubeconfig は出力しない。
- 接続不能または更新対象に既存の異常がある場合は、マージ前に停止して報告する。

## 3. 生成・バージョン固定・検証

- PR のスクリプト差分から更新するタグ変数と生成先を特定する。`yamlfmt .` を変更前後に実行する。変更前の整形で既存ファイルに差分が生じた場合は、その差分を更新コミットに混入させず、先に報告して停止する。
- リポジトリルートで `./k8s/manifest/update-upstream-manifests.sh` を実行する。このスクリプトは対象アプリ以外の upstream も再取得し、ディレクトリを置換するため、生成先の未追跡ファイルにも注意する。
- 失敗時は部分的な生成結果を commit・push しない。成功時も差分全体を調べ、選択した更新と無関係な差分はコミットしない。元からの変更と区別できない場合は削除・復元せず停止する。
- 生成済み YAML だけでなく Kustomize の展開結果を確認する。`stable`・`latest` などの可変タグが残る場合は、upstream 本体の手編集ではなく対象 Kustomization の `images` またはパッチで PR のバージョンを固定する。既存の固定タグが旧版に取り残されていないかも確認する。
- Tailscale では Operator の image と `RELATED_IMAGE_PROXY_IMAGE` など関連する proxy イメージ指定を確認する。環境変数内のイメージは `images` だけでは変更されないため、必要なパッチを使う。付随コンポーネントのバージョンを機械的に同じ値にせず、そのリリースの公式マニフェスト・資料で対応を確認する。
- `git diff --check`、`yamlfmt -lint .`、影響範囲の `kubectl kustomize` と `kubectl apply --dry-run=client -k` を実施する。platform の変更は `k8s/manifest/platform`、Argo CD 自身は `k8s/manifest/bootstrap/argocd` を検証し、base に影響する場合は `k8s/manifest/base` も検証する。dry-run の接続・CRD 不足などは成功扱いせず、未検証として報告し停止する。
- 関連ファイルだけを明示的に `git add` し、staged diff を確認して `Update <app> upstream manifests to <version>` のような件名で commit する。差分がなければ空 commit は作らず、目的のバージョンが既に生成物へ反映済みか確認する。

## 4. push・CI・merge

- PR の head ブランチへ通常の push を行う。force push はしない。リモートが進んで push が拒否されたら、再取得して差分を確認し、無条件の上書きや再試行をしない。
- push 後の HEAD SHA を記録し、`gh pr checks` と PR のチェック一覧で、その HEAD に対する必須 CI と実行された CI の成功を確認する。CI が存在しない・未開始・失敗・キャンセル・必須チェックが skipped の場合は成功とみなさない。
- CI 待機の上限は 30 分。短い間隔の確認を使い、待機中も進捗を報告する。失敗・タイムアウト時は内容を報告して停止する。
- マージ直前に HEAD SHA、base、差分、競合・レビュー要件・チェック状態を再確認する。HEAD が変わったら再レビュー・再検証する。
- `gh pr merge <番号> --squash --match-head-commit <確認済みSHA>` でマージする。保護ルールを迂回する admin オプションや未検証の自動マージは使わない。
- GitHub の状態が `MERGED` であることと merge commit SHA を取得する。

## 5. 同期と実機更新を確認

`k8s/manifest/bootstrap/applications/` の最新定義で対象 Application と source を確認する。通常の対応は以下。

| 更新範囲 | Application（namespace: argocd） | 同期方法 |
| --- | --- | --- |
| `k8s/manifest/platform` | `home-server-platform` | 自動同期を待つ |
| `k8s/manifest/bootstrap/argocd` | `argocd` | Refresh 後、差分を確認して手動 Sync |

- platform に通常の `kubectl apply` は行わない。Argo CD 自身の更新は UI または利用可能な Argo CD CLI/API で、対象 Application だけを prune なし・force なしで Sync する。既存の ServerSideApply などの syncOptions を維持し、自動同期設定は変更しない。同期手段が利用できなければ、マージ済み・同期未完了として報告する。
- Application の反映 revision が merge commit、またはそれを含む後続コミットであることを確認する。古い revision の `Synced` / `Healthy` だけでは完了にしない。
- Application の `Synced` / `Healthy` に加え、影響する Deployment・StatefulSet・DaemonSet の rollout 完了、期待するイメージ指定、Pod の Ready を確認する。必要に応じて実行バイナリのバージョンや imageID を照合する。既存 Pod が Ready なだけでは更新成功と判定しない。
- Tailscale では存在する関連 proxy ワークロードも確認する。変更前後の記録と展開結果から対象を特定し、無関係な Pod や正常終了済み Job を異常扱いしない。
- 同期・rollout 待機は合計 15 分を目安に上限を設ける。失敗・タイムアウト時は Application conditions、対象ワークロード・Pod の状態やイベントを調べて報告し、次の PR へ進まない。自動 rollback、強制適用、無条件の再試行は行わない。
- 最後に PR URL、merge commit、更新前後のバージョン、CI、反映 revision、実機確認結果と限界を簡潔に報告する。マージ成功と実機更新成功は区別する。
