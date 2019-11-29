#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <address range file> <ip to check>"
	echo "$0 will check the specified IP and make sure it is in one of the ranges specified in the file.  IP addresses in the file should be:"
	echo "<starting IP> <ending IP>"
	echo "ex: 192.168.1.10 192.168.1.25"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

RANGEFILE=$1
IPTOCHECK=$2

if [ ! -e $RANGEFILE ]; then
	echo "ERROR: Unable to find $RANGEFILE"
	exit 3
fi

RANGES=`cat $RANGEFILE | grep -v "^$"`

IFS_BAK=$IFS
IFS="
"
for CURRANGE in $RANGES; do
	MINIP=`echo "$CURRANGE" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
	MAXIP=`echo "$CURRANGE" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tail -1`

	echo "Checking $MINIP to $MAXIP..."
	ip.inrange.sh $MINIP $MAXIP $IPTOCHECK > /dev/null
	
	if [ $? -eq 0 ]; then
		echo "$IPTOCHECK is in the range $MINIP / $MAXIP"
		IFS=$IFS_BAK
		IFS_BAK=
		exit 0
	fi
done

IFS=$IFS_BAK
IFS_BAK=

echo "$IPTOCHECK is not in any of the ranges."
exit 1

