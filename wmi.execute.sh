#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password> <WMI Query>"
	echo "Query can be something like: 'Select * from Win32_Process'"
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"
QUERY="$4"

wmic -U $USERNAME%$PASSWORD //$TARGET "$QUERY"
