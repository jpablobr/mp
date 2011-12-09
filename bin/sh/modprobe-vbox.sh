#!/bin/sh

VBOXMOD="\
vboxnetflt
vboxpci
vboxnetadp
vboxdrv\
"

vmm_add () {
  for MOD in $VBOXMOD; do
    modprobe $MOD
  done
}

vmm_rem () {
  for MOD in $VBOXMOD; do
    modprobe -r $MOD
  done
}

if [ "$1" ]; then
  vmm_$1
  exit $?
else
  vmm_add
fi
