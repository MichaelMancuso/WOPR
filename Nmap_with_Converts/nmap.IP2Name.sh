#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <IP File>"
	echo "$0 will take a list of IP addresses and create a name/ip mapping from them"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

IPFILE=$1

if [ ! -e $IPFILE ]; then
	echo "ERROR: Unable to find $IPFILE"
	exit 2
fi

IPS=`cat $IPFILE | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

for CURIP in $IPS
do
	NSLOOKUPRESULT=`nslookup $CURIP 2>&1`
	echo "$NSLOOKUPRESULT" | grep -q NXDOMAIN
	
	if [ $? -eq 0 ]; then
		# unable to resolve name
		DNSNAME="<Unknown>"
	else
		DNSNAME=`echo "$NSLOOKUPRESULT" | grep -Eio "name =.*" | sed "s|name = ||g" | sed "s|\.$||g"`
	fi
	
	echo -e "$DNSNAME\t$CURIP"
done
