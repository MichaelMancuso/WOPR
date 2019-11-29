#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password> <pid>"
	echo "Username should be <DOMAIN>/<User>"
	echo "This script will kill a running process by process id"
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"
PROCID="$4"

# -d 6 is a debug level setting so you can see what's going on
winexe -d 6 -U $USERNAME%$PASSWORD //$TARGET "wmic process $PROCID delete"

