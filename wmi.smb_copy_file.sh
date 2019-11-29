#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password> <full local path to source executable> <destination path>"
	echo "Username should be <DOMAIN>/<User>"
	echo ""
	echo "Destination Path should be something like /Users/<username>"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser TheirPassword /opt/myexes/myexe.exe /Users/<username> myexe.exe"
	echo "Note that this is currently set up to only key off of the c$ share"
}

if [ $# -lt 6 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"
EXECUTABLE="$4"
EXEDEST="$5"
EXEDESTNAME="$6"

smbclient //$TARGET/c$ -U $USERNAME%$PASSWORD -c "cd $EXEDEST;put $EXECUTABLE $EXEDESTNAME"

