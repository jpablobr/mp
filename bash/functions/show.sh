#!/bin/sh
# show.sh
# Show stuff helper
# Author: José Pablo Barrantes R. <xjpablobrx@gmail.com>
# Created: 18 Mar 2011
# Version: 0.1.0

##############################################################################->
# - General

alias s-open-ports='nmap -sS -O 127.0.0.1'
alias s-open-hidden-ports='netstat -nap'
alias s-open-hidden-ports-short='lsof -i -n -P'

s-service-network() {
    if [[ "$1" = "h" ]]; then
	      cat <<- -EOF-
    network connections, routing tables, interface statistics,
    masquerade connections ,and multicast memberships for a given service.
-EOF-
    else
        netstat -atnp | grep "$1"
    fi
}

s-my-public-ip() {
    HAVE_CURL=$(command -v curl)
    HAVE_WGET=$(command -v wget)

    if [[ "$1" = "h" ]]; then
	      cat <<- -EOF-
Prints local public IP.
-EOF-
    else
        if [[ HAVE_CURL ]]; then
            wget -q -O - checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
        elif [[ HAVE_WGET ]]; then
            curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
        fi
    fi
}
