#!/bin/sh
set -e

echo start samba

# set user and password
useradd ${USER}
echo -e ${PASSWORD}'\n'${PASSWORD} | pdbedit -a -u ${USER}

nmbd restart --daemon
smbd restart --daemon

tail -f /dev/null
