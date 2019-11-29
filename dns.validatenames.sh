#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <name file>"
	echo "$0 will query each name in the specified name file and validate that it is still"
	echo "a valid DNS entry.  If not it will print the ones that are not."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ "$1" = "--help" ]; then
	ShowUsage
	exit 1
fi

NAMEFILE=$1

if [ ! -e $NAMEFILE ]; then
	echo "ERROR: Unable to find $NAMEFILE"
	exit 2
fi

DNSNAMES=`cat $NAMEFILE`
NUMNAMES=`echo "$DNSNAMES" | grep -v "^$" | wc -l`

echo "[`date`] processing $NUMNAMES names from $NAMEFILE..."
for CURNAME in $DNSNAMES
do
	dns.lookup.name.sh $CURNAME > /dev/null
	
	if [ $? -gt 0 ]; then
		echo "$CURNAME is no longer valid"
	fi
done
echo "[`date`] Done."
