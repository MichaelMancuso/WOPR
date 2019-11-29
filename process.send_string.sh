#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <process id> <text to send>"
	echo "$0 will send the specified string to STDIN of the specified process id"
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

PROCID=$1
STRINGTOSEND="$2"

if [ ! -e /proc/$PROCID/fd/0 ]; then
	echo "[`date`] ERROR: Unable to find the process's STDIN handle.  Process may not be running?"
	exit 2
fi

echo  -n "$STRINGTOSEND" > /proc/$PROCID/fd/0

echo "[`date`] Sent."

