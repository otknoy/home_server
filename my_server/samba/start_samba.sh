#!/bin/ash

echo start samba

nmbd restart --daemon
smbd restart --daemon

tail -f /dev/null
