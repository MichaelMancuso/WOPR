#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <domain name> [Server IP]"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

DOMAIN="$1"
DNSSERVER=""

if [ $# -gt 1 ]; then
	DNSSERVER="$2"
fi

if [ ${#DOMAIN} -eq 0 ]; then
	echo "No domain name provided."
	echo ""

	ShowUsage
	exit 2
fi

nslookup -type=NS $DOMAIN $DNSSERVER

