#!/bin/bash

ShowUsage() {
	echo "$0 scans servers specified in <file> for the presence of a /vcms/ directory"
	echo ""
	echo "Usage: $0 <host/URL file>"
	echo "File should specify root URL on each line."
	echo "Example: https://www.myserver.com"
	echo "         http://www.myserver.com/Subdir/"
	echo "Trailing slash is optional"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HOSTFILE=$1

if [ ! -e $HOSTFILE ]; then
	echo "ERROR: File $HOSTFILE cannot be found."
	exit 2
fi

HOSTENTRIES=`cat $HOSTFILE | grep -v "^$" | grep -v ":\/\/$" | sed "s|\/$||g"`

for HOSTENTRY in $HOSTENTRIES
do
	echo "Testing $HOSTENTRY..." >&2
	ISSSL=`echo "$HOSTENTRY" | grep -iq "http:"`
	ISSSL=$?

	if [ $ISSSL -gt 0 ]; then
		ISSSL=1
	fi

	TRACE_RESPONSE=""

	if [ $ISSSL -eq 1 ]; then
		TRACE_RESPONSE=`wget --tries=1 --timeout=15 --no-check-certificate -O- $HOSTENTRY/vcms/ 2>/dev/null`
	else
		TRACE_RESPONSE=`wget --tries=1 --timeout=15 -O- $HOSTENTRY/vcms/ 2>/dev/null`
	fi

	if [ $? -eq 0 ]; then
		echo "Found: $HOSTENTRY/vcms/"
	fi
done


