#!/bin/sh

ifconfig tap0 10.1.71.1 netmask 255.255.255.0
ifconfig tap0 up
iptables -t nat -A POSTROUTING -s 192.1.71.0/24 -o wlan0 -j MASQUERADE
