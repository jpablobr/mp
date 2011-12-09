#!/bin/sh
DEV=wlan0

[ -n "$(ip route show 0.0.0.0/0)" ] && [ "$(ping -nc1 -w1 $(ip route show 0.0.0.0/0 | cut -d' ' -f3) >/dev/null 2>&1)" ] && exit 0
ifconfig $DEV down || ip link set dev $DEV down
pkill wpa_supplicant
pkill dhcpcd
ifconfig $DEV up || ip link set dev $DEV up
wpa_supplicant -B -Dnl80211,wext -iwlan0 -c/etc/wpa_supplicant.conf
dhcpcd -dt 0 wlan0
