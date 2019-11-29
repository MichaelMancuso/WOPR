#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <dc ip>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"

rpcclient -U "Guest" -N -c "lsaquery" $TARGET

