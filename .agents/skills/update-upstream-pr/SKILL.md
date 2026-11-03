---
name: update-upstream-pr
description: home_server 専用。取得元更新 PR でマニフェストを再生成し、検証してマージする。通常のイメージタグ更新や Talos 更新は対象外。
---

# upstream 更新 PR

対象は `otknoy/home_server`。リポジトリの指示と `k8s/README.md` を確認し、既存変更を保護する。
生成結果は元 PR に含め、別 PR は作らない。実機反映の確認は別途依頼された場合に行う。

## 1. PR を選ぶ

open PR のうち `k8s/manifest/update-upstream-manifests.sh` を変更するものを調べ、番号・URL・更新前後のバージョン・CI を提示して選んでもらう。指定済みなら再選択しない。複数なら順番に処理する。

## 2. 元 PR で再生成する

- PR の base/head・差分と作業ツリーを確認し、head ブランチへ切り替える。
- ルートで `yamlfmt .`、`./k8s/manifest/update-upstream-manifests.sh`、`yamlfmt .` を順に実行する。スクリプトは他アプリの生成先も置換するため、既存ファイルとの衝突・事前整形の差分・生成失敗・無関係な差分があれば停止する。
- 公式のイメージ指定（`stable` など）と環境固有の設定を維持する。

## 3. 検証してマージする

- 差分全体を確認し、`git diff --check`、`yamlfmt -lint .`、影響する Kustomization の `kubectl kustomize` と `kubectl apply --dry-run=client -k` を実行する。接続先を確認し、platform、Argo CD 自身なら bootstrap/argocd、base に影響すれば base を検証する。
- 対象の生成結果のみ commit・通常 push する。生成差分がなければ空 commit は作らない。
- PR 本文に更新内容・運用上の影響・検証結果を反映する。競合・レビュー要件・最新 HEAD の CI を確認し、問題がなければ `gh pr merge <番号> --squash --match-head-commit <確認済みSHA>` でマージする。HEAD が変われば再検証する。
- CI は最大30分待ち、失敗・未実施を成功扱いしない。検証に失敗した場合はマージしない。
- PR の URL、merge commit、更新前後のバージョン、検証結果を報告する。取得元タグの変更と実行バイナリの更新は区別する。
