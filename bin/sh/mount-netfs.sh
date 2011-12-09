#!/bin/sh
MP="$1"
RM="$2"

grep -q $MP /etc/mtab ||\
pingchk.sh $RM &&\
mount $MP
