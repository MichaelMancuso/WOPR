#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0 <local listening port> <remote server> [remote port]"
	echo ""
	echo "$0 uses stunnel to proxy http-to-https requests to the specified remote server"
	echo ""
	echo "Note: This must be run as root (sudo)"
	echo ""
}
	
if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

LOCALPORT=$1
REMOTESYSTEM=$2

if [ $# -gt 2 ]; then
	REMOTEPORT=$3
else
	REMOTEPORT="https"
fi

# check to make sure local port is available:
ANYSVCUSINGPORT=`sudo netstat -an -p | grep ":$LOCALPORT"`

if [ ${#ANYSVCUSINGPORT} -gt 0 ]; then
	echo "ERROR: It appears a service is already using port $LOCALPORT.  Please choose a different port"
	echo "$ANYSVCUSINGPORT"
	exit 2
fi

sudo stunnel -c -d $LOCALPORT -r $REMOTESYSTEM:$REMOTEPORT

