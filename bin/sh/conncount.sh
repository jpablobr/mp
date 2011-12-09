#!/bin/sh
# Usage: conncount
# Prints the current connects by IP

for IP in $(grep 0x /proc/net/arp | cut -d ' ' -f1); do 
  echo "${IP} connection count: $(grep -c ${IP} /proc/net/ip_conntrack)"
done
