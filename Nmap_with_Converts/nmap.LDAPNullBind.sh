#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <LDAP Server>"
	echo "This script will do a NULL bind to the specified target and return information."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1

nmap -p 389 --script=ldap-rootdse $TARGET

