#!/bin/sh 

modload () {
  modprobe tun bridge
}

mkbr () {
  brctl addbr "$1"
}

rmbr () {
  brctl delbr "$1"
}

statbr () {
  brctl show
}

mkswitch () {
  EXT_IFACE="$1"
  CTL="$2"

  vde_switch -daemon -tap tap0 -mod 777 -s "/var/run/vde.ctl/$CTL"
  sysctl net.ipv4.ip_forward=1
  iptables -t nat -A POSTROUTING -s 172.16.15.0/24 -o $EXT_IFACE -j MASQUERADE &&\
  ip addr add 172.16.15.254 dev tap0
}

