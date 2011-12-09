#!/bin/sh
# chroot-populate (start|stop) PATH
# manages binds and copies of files for a chroot system in Linux

chroot_bindpaths () {
  echo "\
dev
dev/pts
dev/shm
proc
proc/bus/usb
sys
tmp
usr/portage"
}

chroot_copypaths () {
  echo "\
etc/resolv.conf
etc/hosts
etc/localtime"
}

#  cp -pf /etc/passwd "${MOUNT_PATH}/etc" >/dev/null &
#  cp -pf /etc/shadow "${MOUNT_PATH}/etc" >/dev/null &
#  cp -pf /etc/group "${MOUNT_PATH}/etc" >/dev/null &
#  cp -pf /etc/gshadow "${MOUNT_PATH}/etc" >/dev/null &
#  cp -Ppf /etc/localtime "${MOUNT_PATH}/etc" >/dev/null &

chroot_mount () {
  for fp in $(chroot_bindpaths); do
    mount -o bind "/$fp" "$1/$fp" >/dev/null
  done

  for fp in $(chroot_copypaths); do
    cp -pf "/$fp" "$1/$fp" >/dev/null &
  done
}

chroot_umount () {
  for fp in $(chroot_bindpaths | sort -r); do
    umount -f "$1/$fp" >/dev/null
  done
}

## Main
if [ -n "$1" ]; then
  CMD="$1"
  DEV_PATH=""
  MOUNT_PATH=""

  if [ "$CMD" = "mount" ]; then
    chroot_mount "$2"
  elif [ "$CMD" = "umount" ]; then
    chroot_umount "$2"
  fi
fi
# chroot "$2" ${3:-"/bin/bash"}
