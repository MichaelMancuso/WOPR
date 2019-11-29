#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <Target IP> [snmp community file]"
	echo "Note: If <target IP> is specified as file:<file> then targets will be read from that file.  This file should be in nmap input format."
	echo ""
	exit 1
fi

TARGET=$1
FILENAME=/opt/wordlists/SnmpStrings.txt
if [ $# -gt 1 ]; then
	FILENAME=$2
fi

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

	if [ ! -e $NETFILE ]; then
		echo "ERROR: Unable to find file '$NETFILE'"
		exit 2
	fi

	nmap -Pn -sU -p 161 --script=+snmp-brute -iL $NETFILE --script-args snmplist=$FILENAME

else
	nmap -Pn -sU -p 161 --script=+snmp-brute $TARGET --script-args snmplist=$FILENAME
fi

