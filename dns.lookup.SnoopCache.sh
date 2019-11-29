#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <resource name> <Server IP>"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

RESOURCE="$1"
DNSSERVER="$2"

dig @$DNSSERVER $RESOURCE A +norecurse | grep "ANSWER:" | grep -o "ANSWER: \w," | sed "s|[1-9],|\'$RESOURCE\' in cache|" | sed "s|0,|\'$RESOURCE\' Not in cache|" | sed "s|,||g" | sed "s|ANSWER: ||" 2>/dev/null


