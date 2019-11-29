#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

echo "[`date`] Listening for neighbors.  Press CTL-C to end..."
passive_discovery6 $1 

