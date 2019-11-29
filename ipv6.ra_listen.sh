#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

echo "[`date`] Listening for router advertisements.  Press CTL-C to end..."
while true; do dump_router6 $1; done
