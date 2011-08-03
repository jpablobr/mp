# Reset firewall
iptables -F

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow all outbound
iptables -A OUTPUT -j ACCEPT

# Allow already established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow needed ICMP things
for t in echo-request echo-reply destination-unreachable time-exceeded parameter-problem; do
  iptables -A INPUT -p icmp --icmp-type "$t"
done

# Allow inbound to alternate HTTP port
# iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# dropbox
iptables -A INPUT -p tcp --dport 17500 -j ACCEPT
iptables -A INPUT -p udp --dport 17500 -j ACCEPT

# Disallow anything else, and log it
iptables -A INPUT -j DROP
