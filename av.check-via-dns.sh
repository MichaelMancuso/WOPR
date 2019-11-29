#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <DNS Server IP>"
	echo ""
}

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

DNSSERVER="$1"

if [ ! -e /opt/av_check/av_servers.txt ]; then
	echo "ERROR: Unable to find /opt/av_servers.txt list."
	exit 1
fi

AVRECORDS=`cat /opt/av_check/av_servers.txt`

for RESOURCE in $AVRECORDS
do
	HASRECORD=`dig @$DNSSERVER $RESOURCE A +norecurse | grep "ANSWER:" | grep -o "ANSWER: \w," | sed "s|[1-9],|\'$RESOURCE\' in cache|" | sed "s|0,|\'$RESOURCE\' Not in cache|" | sed "s|,||g" | sed "s|ANSWER: ||" 2>/dev/null | grep -v "Not in cache" | wc -l`
	if [ $HASRECORD -gt 0 ]; then
		echo "Found: $RESOURCE"
	fi
done


