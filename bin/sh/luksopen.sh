#!/bin/sh

luksopen_mount () {
  BASE="$(basename "$1" .img)"
  DEV="$(egrep -o "^/dev/mapper/$BASE" /etc/fstab)"
  if [ -s "$1" -a -n "$DEV" -o -d "$2" ]; then
    cryptsetup luksOpen "$1" "$BASE"
    if [ -n "$DEV" ]; then
      mount "$DEV"
    else
      mount "/dev/mapper/$BASE" "$2"
    fi
  fi
}

luksopen_umount () {
  DEV="/dev/mapper/$1"
  egrep -qo "^$DEV" /etc/mtab
  if [ "$?" = 0 ]; then
    umount "$DEV"
    cryptsetup luksClose "$DEV"
  fi
}

case "$1" in
  mount)
    luksopen_mount $2 $3
    exit 0
    ;;
  umount)
    luksopen_umount $2
    exit 0
    ;;
esac

exit 1
