#!/bin/sh
set -e

echo start samba

# set user and password
grep ${USER}: /etc/passwd > /dev/null || \
    useradd ${USER}; \
    printf '%s\n%s\n' "$PASSWORD" "$PASSWORD" | pdbedit -a -t -u "$USER"

nmbd restart --daemon
smbd restart --daemon

tail -f /dev/null
