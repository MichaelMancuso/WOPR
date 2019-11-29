#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface> [limit to this many packets]"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

IFACE=$1

if [ $# -gt 1 ]; then
	COUNTPARAM="-c $2"
else
	COUNTPARAM = ""
fi

tcpdump $COUNTPARAM -vv -i $IFACE -s 0 port bootps

