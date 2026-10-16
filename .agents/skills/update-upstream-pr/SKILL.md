---
name: update-upstream-pr
description: home_server 専用。update-upstream-manifests.sh を変更する PR の選定・生成・マージ・Argo CD 反映確認を行う。通常のイメージタグ更新や Talos 更新は対象外。
---

# upstream 更新 PR の反映

対象は `otknoy/home_server`。リポジトリルートと origin を確認し、リポジトリの指示と `k8s/README.md` を読む。以下のパスはルート基準。
更新依頼には commit・push・merge・同期・実機確認までを含め、段階ごとの許可は取り直さない。ユーザーが指定した範囲と実行環境の権限承認に従う。

## 1. PR を選ぶ

- open PR を全件調べ、変更ファイルに `k8s/manifest/update-upstream-manifests.sh` を含むものを抽出する。
- 番号・URL・対象アプリ・更新前後のバージョン・CI を提示して選んでもらう。番号や URL が指定済みなら再選択は不要。複数なら選択順に、各 PR の反映確認まで完了してから次へ進む。

## 2. 更新と検証

- 作業ツリーと PR の base/head・SHA・差分を確認して head ブランチへ切り替える。既存変更や未 push コミットを保護し、競合・対象外の変更・生成先との衝突があれば停止する。
- kubectl context と Application の接続先を確認し、対象の同期 revision・正常性・ワークロード・Pod のイメージ/imageID・Ready を記録する。接続不能や既存異常があれば停止する。
- `yamlfmt .` の後、ルートで `./k8s/manifest/update-upstream-manifests.sh` を実行し、再度整形する。スクリプトは他アプリも再取得し生成先を置換する。事前整形で差分が生じた場合、生成失敗、無関係な差分を既存変更と区別できない場合は停止する。
- イメージ指定は関連コンポーネントや環境変数も含めて公式マニフェストに従う。`stable`・`latest` を独自に固定せず、環境固有の設定は維持する。既存のイメージ上書きは差異を報告する。
- `git diff --check`、`yamlfmt -lint .`、影響する Kustomization の `kubectl kustomize` と `kubectl apply --dry-run=client -k` を実行する。検証先は platform、Argo CD 自身なら bootstrap/argocd、base に影響すれば base も含める。失敗・未検証なら停止する。
- 差分全体を確認し、対象の更新だけを明示的に stage・commit する。空 commit や部分的な生成結果の commit は行わない。

## 3. push とマージ

- PR ブランチへ通常の push を行い、その HEAD の CI 成功を確認する。CI 不在・未開始・失敗を成功扱いせず、待機は最大30分とする。
- HEAD・base・差分・競合・レビュー要件・チェックを再確認し、`gh pr merge <番号> --squash --match-head-commit <確認済みSHA>` でマージする。HEAD が変われば再検証する。force push や保護ルールの迂回は行わない。
- `MERGED` と merge commit SHA を確認する。

## 4. 反映確認

- 最新の `k8s/manifest/bootstrap/applications/` で対象 Application と source を確認する。platform は `home-server-platform` の自動同期を待ち、通常の `kubectl apply` は行わない。
- Argo CD 自身は Application `argocd` を Refresh・差分確認後、CLI/API/UI で prune・force なしの手動 Sync を行う。既存の syncOptions を維持する。同期手段がなければ未完了として報告する。
- merge commit を含む revision の `Synced` / `Healthy`、対象 Pod の Ready・イメージ指定、変更したワークロードの rollout を確認する。Tailscale は関連 proxy も含める。
- 可変タグでは取得元タグと実行バージョンを同一視しない。Pod template が変わらず再作成されない場合もあるため、更新のためだけのタグ変更や再起動は行わず、確認できた実行バージョン/imageID と限界を報告する。
- 同期・rollout は合計最大15分待つ。失敗・タイムアウト時は conditions・対象 Pod・イベントを調べて停止する。自動 rollback や強制適用は行わない。
- PR URL・merge commit・更新前後のバージョン・CI・反映 revision・実機の状態を簡潔に報告する。マージ、マニフェスト反映、実行バイナリ更新の成否を区別する。
