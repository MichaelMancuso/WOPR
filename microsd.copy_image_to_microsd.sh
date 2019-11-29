#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <image file> <MicroSD device>"
	echo "For the MicroSD device use fdisk -l.  Should look something like /dev/sdc"
	exit 1
fi

IMAGEFILE=$1
DEVICE=$2

if [ ! -e $IMAGEFILE ]; then
	echo "ERROR: Can't find $IMAGEFILE"
	exit 2
fi

read -r -p "This will COMPLETELY WIPE $DEVICE.  Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        CONTINUE=1
        ;;
    *)
        CONTINUE=0
        ;;
esac

if [ $CONTINUE -eq 0 ]; then
	echo "Exiting."
	exit 0
fi

echo "[`date`] Writing $IMAGEFILE to $DEVICE..."
sudo dd if=$IMAGEFILE of=$DEVICE bs=4M oflag=sync status=noxfer
echo "[`date`] Done."
