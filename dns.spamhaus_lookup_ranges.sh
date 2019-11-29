#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <subnet input file>"
	echo "$0 will expand all of the subnets in the specified file and query each IP against the spamhaus blacklist.  Input file should be <network>/<prefix> or just IP"
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE="$1"

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find $INPUTFILE."
	exit 1
fi

TARGETS=`cat $INPUTFILE`

IFS_BAK=$IFS
IFS="
"

for CURENTRY in $TARGETS
do
	echo $CURENTRY | grep -Eq "\/"

	if [ $? -eq 0 ]; then
		IPLIST=`ip.expandprefix.sh $CURENTRY`

		for CURIP in $IPLIST
		do
			dns.spamhaus_lookup.sh $CURIP
		done
	else
		dns.spamhaus_lookup.sh $CURENTRY
	fi
done

IFS=$IFS_BAK
IFS_BAK=

