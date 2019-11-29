#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

IFACE=$1

tcpdump -vv -c 1 -i $IFACE -s 0 port bootps 2>&1 | grep -Eio "Client\-Ethernet\-Address [0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}" | sed "s|Client-Ethernet-Address ||"
