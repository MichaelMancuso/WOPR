#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <port>"
	echo "Where <port> is the port to listen on."
	echo "For WOPR this should be 5222 which maps to 173.161.171.73:443"
	echo ""
}

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

LISTENPORT=$1

ncat -p $LISTENPORT -l -C -k
