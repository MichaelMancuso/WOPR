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

FOUNDRECORD=0

RESULT=`nslookup  -type=TXT $DOMAIN $DNSSERVER | grep "spf1" | sed "s|\t||g"`

if [ ${#RESULT} -gt 0 ]; then
	echo "TXT Record:"
	echo "$RESULT"
	
	FOUNDRECORD=1
fi

RESULT=`nslookup  -type=SPF $DOMAIN $DNSSERVER`
HASRESULT=`echo "$RESULT" | grep -i "No answer" | wc -l`

if [ $HASRESULT -eq 0 ]; then
	echo "DNS 'SPF' Record:"
	echo "$RESULT"
	FOUNDRECORD=1
fi

if [ $FOUNDRECORD -eq 0 ]; then
	# No record
	echo "No DNS SPF 'TXT' or 'SPF' records found."
	exit 3
fi
