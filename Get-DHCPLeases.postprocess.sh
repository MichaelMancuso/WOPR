#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <lease log file>"
	echo "Where log file is the csv file produced by Get-DHCPLeases.ps1"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

LOGFILE=$1

DATA=`cat $LOGFILE | grep "^[0-9]" | cut -f1,2,4`

IFS_BAK=$IFS
IFS="
"

for CURLINE in $DATA; do
	IPADDR=`echo "$CURLINE" | cut -f1`
	SYSNAME=`echo "$CURLINE" | cut -f2`
	MACADDR=`echo "$CURLINE" | cut -f3 | sed "s|\-|:|g"`
	
	if [ ${#SYSNAME} -eq 0 ]; then
			SYSNAME="<None>"
	fi
	
	echo -e "$SYSNAME\tDHCP Lease\t$IPADDR\t$MACADDR"
done

IFS=$IFS_BAK
IFS_BAK=

