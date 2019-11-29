#!/bin/bash

ShowUsage() {
	echo "$0 scans servers specified in <file> for the presence of trace.axd"
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

HOSTFILE="$1"

echo "$1" | grep -qi -e "^http:" -e "^https:"

if [ $? -eq 0 ]; then
	HOSTENTRIES=`echo "$1" | sed "s|\/$||g"`
else
	HOSTENTRIES=`cat $HOSTFILE | grep -v "^$" | grep -v ":\/\/$" | sed "s|\/$||g"`
fi


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
		TRACE_RESPONSE=`wget --tries=1 --timeout=15 --no-check-certificate -O- $HOSTENTRY/Trace.axd 2>/dev/null`
	else
		TRACE_RESPONSE=`wget --tries=1 --timeout=15 -O- $HOSTENTRY/Trace.axd 2>/dev/null`
	fi

	TRACE_FOUND=0

	if [ ${#TRACE_RESPONSE} -gt 0 ]; then
		# if the response page does not contain "trace localOnly" then there's a good chance the trace page came back
		TRACE_FOUND=`echo "$TRACE_RESPONSE" | grep -iq "trace localOnly"`
		TRACE_FOUND=$?
	fi

	if [ $TRACE_FOUND -gt 0 ]; then
		echo "Trace.axd found: $HOSTENTRY/Trace.axd"
	fi
done


