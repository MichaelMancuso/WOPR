#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <hostname> [stunnel/proxy] [port]"
	echo "$0 will send a TRACE / request to the host using the HOST: <hostname> parameter"
	echo "if stunnel/proxy is provided, the specified hostname will be provided but netcat will connect to the proxy"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

which nc > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to find netcat (nc) in the path."
	exit 2
fi

HOSTNAME=$1

echo "" > ~tracetest.txt
echo "TRACE / HTTP/1.1" >> ~tracetest.txt
echo "Host: $HOSTNAME" >> ~tracetest.txt
echo "" >> ~tracetest.txt
echo "" >> ~tracetest.txt
echo "" >> ~tracetest.txt
echo "" >> ~tracetest.txt
echo "" >> ~tracetest.txt

CONNECTTARGET=$HOSTNAME

CONNECTPORT=80
if [ $# -gt 1 ]; then
	CONNECTPORT=$2
fi


if [ $# -gt 2 ]; then
	CONNECTTARGET=$2
	CONNECTPORT=$3
fi


nc -w 2 $CONNECTTARGET $CONNECTPORT < ~tracetest.txt
rm ~tracetest.txt
