#!/bin/sh
MOD=ath9k
IFACE=wlan0
WPASUP="wpa_supplicant -B -Dnl80211,wext -i$IFACE -c/etc/wpa_supplicant.conf"
DHC="dhcpcd -dt 0 $IFACE"

IFCON () {
  ifconfig $IFACE $1 || ip link set dev $IFACE $1
}

wifi_up () {
  modprobe $MOD
  IFCON up
  $WPASUP
  $DHC
}

wifi_down () {
  pkill -f "$WPASUP"
  pkill -f "$DHC"
  IFCON down
  modprobe -r $MOD
}

wifi_reload () {
  wifi_down
  sleep 2
  wifi_up
}

case "$1" in
  enable|on|start|up)
    wifi_up
    exit
    ;;

  disable|off|stop|down)
    wifi_down
    exit
    ;;

  restart|reload)
    wifi_reload
    exit
    ;;
esac

exit 1
