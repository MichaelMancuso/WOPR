#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target host file>"
	echo "Target host file contains an IP address, one per line, to test for default nortel passwords."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HOSTFILE=$1

if [ ! -e $HOSTFILE ]; then
	echo "ERROR: Unable to find $HOSTFILE"
	exit 2
fi

HOSTLIST=`cat $HOSTFILE | grep -v "^$"`

for CURHOST in $HOSTLIST
do
	# Metasploit couldn't "find" the password prompt.  Switched to hydra.
	hydra -C /opt/wordlists/nortel_default_passwords-colon_sep.txt -M $HOSTFILE telnet
done

