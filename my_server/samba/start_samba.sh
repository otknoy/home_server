#!/bin/sh
set -e

echo start samba

# set user and password
grep ${USER}: /etc/passwd > /dev/null || \
    useradd ${USER}; \
    echo -e ${PASSWORD}'\n'${PASSWORD} | pdbedit -a -u ${USER}

nmbd restart --daemon
smbd restart --daemon

tail -f /dev/null
