#!/bin/ash

echo start samba

# set user and password
adduser -D ${USER}
echo -e ${PASSWORD}'\n'${PASSWORD} | pdbedit -a -u ${USER}

nmbd restart --daemon
smbd restart --daemon

tail -f /dev/null
