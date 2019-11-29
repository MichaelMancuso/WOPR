#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <nmap group file>"
	echo "$0 will take the nmap output of an smb-enum-groups script and reformat it into a more useable format."
	echo "The input file to this script should be the .nmap file from output such as a redirect or a -oN or -oA output."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

NMAPFILE="$1"

if [ ! -e $NMAPFILE ]; then
	echo "ERROR: cannot find $NMAPFILE"
	exit 2
fi

GROUPENTRIES=`cat $NMAPFILE | grep "RID:" | grep -v "<empty>" | sed 's/|   //g'`
GROUPEMPTYENTRIES=`cat $NMAPFILE | grep "RID:" | grep "<empty>" | sed 's/|   //g'`

IFS_BAK=$IFS
IFS="
"

for CURENTRY in $GROUPENTRIES
do
	CURENTRY=`echo "$CURENTRY" | sed 's| (.*)||'`
	GROUPNAME=`echo "$CURENTRY" | grep -Pio ".*?:" | sed "s|:||"`
	MEMBERS=`echo "$CURENTRY" | sed 's| (.*)||' | sed "s|.*:||" | tr ',' '\n' | sort -f | sed "s|^ |\t|g"`
	
	echo "$GROUPNAME"
	echo "$MEMBERS"
done

echo ""
echo "Empty Groups:"
for CURENTRY in $GROUPEMPTYENTRIES
do
	CURENTRY=`echo "$CURENTRY" | sed 's| (.*)||'`
	GROUPNAME=`echo "$CURENTRY" | grep -Pio ".*?:" | sed "s|:||"`
	echo "$GROUPNAME"
done

IFS=$IFS_BAK
IFS_BAK=

