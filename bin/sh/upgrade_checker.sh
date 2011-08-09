#!/usr/bin/env bash

# grab the package names in a single line.
PACKAGES=$(sudo apt-get upgrade -s | grep ^Inst | cut -f2 -d ' ' | tr '\n' ' ')

# get the number of packages that need updating.
NUM_PKGS=$(echo "$PACKAGES" | grep -o ' ' | wc -l)

if [ $NUM_PKGS > 0 ]; then
   echo "$NUM_PKGS have updates available" |  \
   mail -s "$NUM_PKGS have updates available" \
   xjpablobrx@gmail.com && exit 0;
fi
0;