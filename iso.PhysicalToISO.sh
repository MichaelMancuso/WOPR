#!/bin/bash

ShowUsage() {
	echo "$0 will copy a physical disk to an ISO image using dd."
	echo "Usage: $0 <output iso filename> [source device]"
	echo "Where:"
	echo "output filename is something like isoimage.iso"
	echo "Source Device could be cdrom, dvd, etc. Whatever is provided"
	echo "       here will be appended to dev as /dev/<source device>"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

SOURCEDEVICE="cdrom"
ISOIMAGE=$1

if [ $# -gt 1 ]; then
	SOURCEDEVICE=$2
fi

dd if=/dev/$SOURCEDEVICE of=$ISOIMAGE
