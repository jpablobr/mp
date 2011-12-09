#!/bin/sh
MP="$2"
RM="$1"

grep -q $MP /etc/mtab ||\
sshfs $RM $MP
