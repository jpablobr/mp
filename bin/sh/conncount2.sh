#!/bin/sh
# Usage: conncount
# Prints the current connects by IP

for IP in $(grep 0x /proc/net/arp | cut -d' ' -f1); do 
  echo -e "$(grep ${IP} /proc/net/arp | sed -ne 's/  */ /gp' | cut -d' ' -f4) ${IP} connection count: $(grep -c ${IP} /proc/net/ip_conntrack)"
done
