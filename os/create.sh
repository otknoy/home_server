#!/bin/bash
VM_NAME=$1

# https://cloud-images.ubuntu.com/noble/
# wget https://cloud-images.ubuntu.com/noble/20241004/noble-server-cloudimg-amd64.img -O ./temp/ubuntu-server-24.04-cloudimg-amd64.img

cp ./temp/ubuntu-server-24.04-cloudimg-amd64.img ${VM_NAME}.img
qemu-img resize ${VM_NAME}.img 32G

# meta-data
cat - <<EOF > ./temp/cloud-init/meta-data
#meta-data
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF
# user-data
cat - <<EOF > ./temp/cloud-init/user-data
#cloud-config
hostname: ${VM_NAME}
password: test
chpasswd:
  expire: False
ssh_pwauth: False
package_upgrade: true

users:
  - default
  - name: otknoy
    passwd: $6$rounds=4096$.0Ick2N9HreFULS/$/1/XD4tNxJOD4iVB0MvrK0BOPLcsk/CkHSkWWj0NWqBpC7GmLcV8z4UElX1D9.HrWHZ.z.dIUQeHOFW5DJirk0
    lock_passwd: false
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

runcmd:
  # install tailscale https://tailscale.com/kb/1293/cloud-init
  # One-command install, from https://tailscale.com/download/
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  # Set sysctl settings for IP forwarding (useful when configuring an exit node)
  - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  # Generate an auth key from your Admin console
  # https://login.tailscale.com/admin/settings/keys
  # and replace the placeholder below
  - ['tailscale', 'up', '--authkey=$(cat ./keys/tskey)', '--advertise-tags=tag:server']
  # (Optional) Include this line to make this node available over Tailscale SSH
  - ['tailscale', 'set', '--ssh']
EOF
# 
cloud-localds ${VM_NAME}_user-data.img ./temp/cloud-init/user-data ./temp/cloud-init/meta-data

virt-install \
    --virt-type kvm \
    --name ${VM_NAME} \
    --os-variant=ubuntu24.04 \
    --vcpus=4 \
    --memory=16384 \
    --disk ./${VM_NAME}.img \
    --disk ./${VM_NAME}_user-data.img,device=cdrom \
    --import \
    --nographics \
    --noautoconsole

    # --network bridge=br0,model=virtio \

  # --name ubuntu001 \
  # --cpu host \
  # --disk size=2,format=qcow2 \
  # --disk path=$PWD/user-data.img,device=cdrom \
  #
  # --virt-type kvm

virsh list --all
