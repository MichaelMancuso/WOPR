#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target IP>"
	echo "$0 will use the arping command to resolve an IP to a mac address"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGETIP="$1"

arping -c 2 $TARGETIP

