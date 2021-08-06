#!/bin/sh

useradd -m ${USER}
echo "${USER}:${PASSWORD}" | chpasswd

wsgidav --host 0.0.0.0 --port 8080 --root /var/wsgidav-root --auth=pam-login #-no-config
