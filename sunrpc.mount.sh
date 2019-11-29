#!/bin/bash

if [ $# -lt 3 ]; then
	echo "Usage: $0 <target> <remote directory> <local mount point>"
	echo "Where:"
	echo "<target> is the IP address of the remote system"
	echo "<remote directory> is the directory identified from showmount or sunrpc.showmountpoints.sh"
	echo "<local mount point> is the local directory to attach the remote directory to"
	echo ""

	exit 1
fi

TARGET=$1
REMOTEDIR=$2
LOCALMOUNT=$3

if [ ! -d $LOCALMOUNT ]; then
	echo "ERROR: $LOCALMOUNT does not exist."
	exit 255
fi

mount -o nolock,vers=3 -t nfs $TARGET:$REMOTEDIR $LOCALMOUNT

