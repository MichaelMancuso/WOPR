#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <image file> <mount location>"
}


if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

IMGFILE=$1
MOUNTLOC=$2

if [ ! -e $IMGFILE ]; then
	echo "ERROR: Unable to find $IMGFILE."
	exit 2
fi

if [ ! -e $MOUNTLOC ]; then
	echo "ERROR: Unable to find $MOUNTLOC"
	exit 3
fi

mount -o loop $IMGFILE $MOUNTLOC


