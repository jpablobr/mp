#!/bin/sh
# Source: http://blog.ksplice.com/2011/01/solving-problems-with-proc/
#
# This program checks the Kernel to find which programs are most likely to be
# killed by the kernel when the system runs out of memory

echo "     Score    Pid Command";
for procdir in $(find /proc -maxdepth 1 -regex '/proc/[0-9]+'); do
  printf "%10d %6d %s\n" \
  "$(cat $procdir/oom_score)" \
  "$(basename $procdir)" \
  "$(cat $procdir/cmdline | tr '\0' ' ' | head -c 100)"
done 2>/dev/null | sort -nr | head -n 20
