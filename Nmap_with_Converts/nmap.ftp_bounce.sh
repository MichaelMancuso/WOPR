#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <ftp bounce host> <target ip> [target ports]"
	echo "target ip can be a metasploit RHOSTS designator.  IP, Range, or CIDR"
	echo "If ports are not specified, 21,22,23,25,80,110,161,443,500, 5060,1720,8080 are checked."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

FTPBOUNCEHOST=$1
TARGET="$2"

if [ $# -gt 2 ]; then
	PORTLIST=`echo "$3" | sed "s| ||g"`
else
	PORTLIST="21,22,23,25,80,110,161,443,500,5060,1720,8080"
fi

msfconsole -x "use auxiliary/scanner/portscan/ftpbounce; set BOUNCEHOST $FTPBOUNCEHOST; set RHOSTS $TARGET; set RPORTS $PORTLIST; set THREADS 5; set FTPUSER anonymous; set FTPPASS anonymous@gmail.com; exploit; exit"

