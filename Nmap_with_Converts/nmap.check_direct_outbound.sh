#!/bin/bash

# Syntax: [outbound port to check, default=443] [protocol (tcp or udp) default=tcp]
PROTOCOL="TCP"

if [ $# -gt 0 ]; then
	OUTBOUNDPORT=$1

	if [ $# -gt 1 ]; then
		PROTOCOL="$2"
	fi
else
	OUTBOUNDPORT=443
fi

SCANTYPE="-sT"

echo "$PROTOCOL" | grep -iq "udp"

if [ $? -eq 0 ]; then
	SCANTYPE="-sU"
fi

NMAPRESULTS=`nmap -Pn -n -sT -p $OUTBOUNDPORT portquiz.net`
HASOPEN443=`echo "$NMAPRESULTS" | grep "^$OUTBOUNDPORT" | grep "open" | wc -l`

if [ $HASOPEN443 -eq 0 ]; then
	echo "It appears that TCP/$OUTBOUNDPORT is NOT open directly outbound."
	exit 1
else
	echo "It appears that TCP/$OUTBOUNDPORT is allowed outbound."
	exit 0
fi

