#!/bin/bash

ShowUsage() {
	echo "$0 will mount an ISO image at the location specified."
	echo "Usage: $0 <iso filename> <mount location>"
	echo "Where:"
	echo "filename is something like isoimage.iso"
	echo "Mount location specifies where to mount the iso."
	echo "This directory will be created if it does not already exist."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

ISOIMAGE=$1
MOUNTPOINT=$2

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

if [ ! -d $MOUNTPOINT ]; then
	mkdir $MOUNTPOINT
fi

if [ -d $MOUNTPOINT ]; then
	mount -o loop $ISOIMAGE $MOUNTPOINT
else
	echo "ERROR: $MOUNTPOINT does not exist and unable to create $MOUNTPOINT"
	exit 255
fi
