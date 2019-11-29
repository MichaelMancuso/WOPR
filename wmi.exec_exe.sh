#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password> <full local path to executable>"
	echo "Username should be <DOMAIN>/<User>"
	echo "For Example, if you copy an exe to the user's c:\users\<username> directory:"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser TheirPassword \"c:\Users\<username>\myexe.exe\""

}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"
EXECUTABLE="$4"

# -d 6 is a debug level setting so you can see what's going on
winexe -d 2 -U $USERNAME%$PASSWORD //$TARGET "wmic process call create \"$EXECUTABLE\""

