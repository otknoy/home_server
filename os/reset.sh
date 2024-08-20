#!/bin/bash

delete_vm() {
    name=$1

    # delete vm
    virsh destroy ${name}; virsh undefine ${name} --remove-all-storage
    # rm ${name}*.img 

    # remove devices from tailscale
    # id=${name}
    # curl -X DELETE "https://api.tailscale.com/api/v2/device/${id}" -u "$(cat ./keys/tskey):"
    # sleep 0.1
}

virsh list --all

delete_vm ubuntu-server001
# delete_vm ubuntu-server002
# delete_vm ubuntu-server003

virsh list --all
