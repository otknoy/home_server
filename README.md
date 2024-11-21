# home_server

# requirements

- docker
- docker-compose

# tools

### yamlfmt

https://github.com/google/yamlfmt

```
$ yamlfmt .
```

# memo

## iscsi
```
// iqn.2000-01.com.synology:DS224plus.pvc-7c86c181-e581-4567-ac2c-66b7e54318d4

sudo iscsiadm -m discovery --type sendtargets --portal 192.168.0.100

sudo iscsiadm -m node -T iqn.2000-01.com.synology:DS224plus.pvc-7c86c181-e581-4567-ac2c-66b7e54318d4 -p 192.168.0.100 -l

sudo iscsiadm -m node --logout all
```
