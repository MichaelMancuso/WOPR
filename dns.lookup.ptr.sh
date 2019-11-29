#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <IP Address> [Server IP]"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

IPADDRESS="$1"
DNSSERVER=""

if [ $# -gt 1 ]; then
	DNSSERVER="$2"
fi

if [ ${#IPADDRESS} -eq 0 ]; then
	echo "No IP address provided."
	echo ""

	ShowUsage
	exit 2
fi

nslookup  -type=PTR $IPADDRESS $DNSSERVER | grep "name"

