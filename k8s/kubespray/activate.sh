#!/bin/sh
# https://kubespray.io/#/?id=quick-start

KUBESPRAY_VERSION=v2.23.0
PRIVATE_KEY=${HOME}/.ssh/id_ed25519

docker run --rm -it \
       --net host \
       --mount type=bind,source="$(pwd)"/inventory/mycluster,dst=/kubespray/inventory/mycluster \
       --mount type=bind,source=${PRIVATE_KEY},dst=/root/.ssh/`basename ${PRIVATE_KEY}` \
       quay.io/kubespray/kubespray:${KUBESPRAY_VERSION} bash

# eval `ssh-agent`
# ssh-add

# ansible -i inventory/mycluster/inventory.ini all --user otknoy -m ping
# ansible-playbook -i inventory/mycluster/inventory.ini --user otknoy --become --become-user=root --private-key=id_ed25519 cluster.yml -vv
