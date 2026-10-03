# image-crawler

Deployment が起動時と 6 時間ごとに巡回し、`image-crawler-data` PVC の `/data` に画像を保存します。

## データの保持

稼働中の PVC は `nfs-client` を使用していますが、紐づく PV
`pvc-07ad95c2-d4a8-41d8-b013-48b07124963d` は `Retain` に変更しています。
PVC の `storageClassName` は変更できないため、既存 PVC は再作成しません。

新規環境で導入する場合は、`pvc.yaml` の `storageClassName` を
`nfs-client-retain` に変更してから適用してください。

PVC を削除した場合、PV は `Released` になり、データは NFS に残ります。
同名 PVC の再作成では自動で再接続されません。保存先を確認し、既存 PV の
`claimRef` と新しい PVC の `volumeName` を使って手動で再接続してください。
保持された保存先への意図しない接続を避けるため、復旧前に PVC を作り直さないでください。
