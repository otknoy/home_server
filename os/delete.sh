#!/bin/bash

delete_vm() {
    name=$1

    # delete vm
    virsh destroy ${name}; virsh undefine ${name} --remove-all-storage
}

remove_device_from_tailnet() {
    name=$1
    id=$(
	curl -s \
	     -H "Authorization: Bearer $(cat ./keys/api_access_token)" \
	     "https://api.tailscale.com/api/v2/tailnet/otknoy@gmail.com/devices" \
	    | jq -r ".devices[] | select(.hostname == \"${name}\") | .id"
      )
    echo $id

    curl -s -X DELETE -H "Authorization: Bearer $(cat ./keys/api_access_token)" https://api.tailscale.com/api/v2/device/${id}
}

virsh list --all
delete_vm $1
virsh list --all

remove_device_from_tailnet $1
