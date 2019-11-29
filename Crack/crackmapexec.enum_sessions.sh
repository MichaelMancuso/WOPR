#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <domain> <username> <password> <target(s)>"
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

DOMAIN="$1"
USERNAME="$2"
PASSWORD="$3"
TARGETS="$4"

crackmapexec -d $DOMAIN -u $USERNAME -p $PASSWORD --sessions $TARGETS

