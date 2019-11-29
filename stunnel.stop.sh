#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0"
	echo ""
	echo "$0 Stops any listening stunnel services."
	echo ""
	echo "Note: This must be run as root (sudo)"
	echo ""
}
	
if [ $# -gt 0 ]; then
	ShowUsage
	exit 1
fi

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

pkill stunnel4

