# memo

## debian (localhost) に node-exporter をインストールする

```
$ sudo apt install prometheus-node-exporter
```

### 設定の変更

デフォルトの設定だと、`node_filesystem_*` でマウントポイント `/mnt` のディスクが無視されているので設定ファイルを修正して再起動する


```
--collector.filesystem.ignored-mount-points="^/(dev|proc|run|sys|mnt|media|var/lib/docker/.+)($|/)"
```
`mnt` を削除する


```
$ sudo vi /etc/default/prometheus-node-exporter
```

```
ARGS="--log.level=\"info\" --collector.filesystem.ignored-mount-points=\"^/(dev|proc|run|sys|media|var/lib/docker/.+)($|/)\""
```

node-exporter を再起動する

```
$ sudo systemctl restart prometheus-node-exporter
```
