#!/bin/bash


ShowUsage() {
	echo "Usage: $0 <tty>"
	echo "Example: $0 rfcomm1"

	echo ""
	echo "Note: gpsd must be stopped to run this."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TTYDEV="$1"

gpspipe -r /dev/$TTYDEV
