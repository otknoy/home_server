# kubespray

- https://github.com/kubernetes-sigs/kubespray
- https://kubespray.io/#/
- ingress
  - https://kubespray.io/#/docs/ingress/metallb
  - https://kubespray.io/#/docs/ingress/ingress_nginx
- tailscale k8s-operator
  - https://tailscale.com/kb/1236/kubernetes-operator


```sh
# ansible-playbook --check --diff -i inventory/mycluster/inventory.yaml cluster.yaml

# ansible-playbook -i inventory/mycluster/inventory.yaml cluster.yaml
```


## memo

- `apt -install`
  - `nfs-common`
  - `open-iscsi`
- apply secrets
- apply tailscale-operator
- add tailscale annotation to ingress-nginx service
