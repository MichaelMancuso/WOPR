#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password>"
	echo "Username should be <DOMAIN>/<User>"
	echo ""
	echo "Destination Path should be something like /Users/<username>"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser TheirPassword"
	echo "Note that this is currently set up to only key off of the c$ share"
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"

smbclient //$TARGET/c$ -U $USERNAME%$PASSWORD

