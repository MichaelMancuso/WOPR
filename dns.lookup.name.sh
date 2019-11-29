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

RESULTS=`nslookup $DOMAIN $DNSSERVER | grep -e "^Name" -e "^Address:" | grep -v "#53" | tr '\n' '\t' | sed "s|Name:\s||" | sed "s|Address:\s||" | sed "s|\sName:\s|\n|g" | sed "s|\sAddress:\s|\t|g"`

if [ ${#RESULTS} -gt 0 ]; then
	echo "$RESULTS"
	echo ""
else
	echo "Could not find $DOMAIN"
	exit 10
fi
