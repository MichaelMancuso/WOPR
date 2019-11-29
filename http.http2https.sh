#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <remote host> [local port] [remote port]"
	echo ""
	echo "$0 will leverage stunnel command-line parameters to start an http 2 https translator"
	echo "running on the local host to <remote host>:<remote port>"
	echo ""
	echo "If only <remote host> is specified, local port=80, remote port=443"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

REMOTEHOST=$1
LOCALPORT=80
REMOTEPORT=443

if [ $# -gt 1 ]; then
	LOCALPORT=$2
fi

if [ $# -gt 2 ]; then
	REMOTEPORT=$3
fi

stunnel -c -r $REMOTEHOST:$REMOTEPORT -d 127.0.0.1:$LOCALPORT

