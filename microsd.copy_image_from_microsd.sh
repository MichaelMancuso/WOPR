#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <MicroSD device> <image file> "
	echo "For the MicroSD device use fdisk -l.  Should look something like /dev/sdc"
	echo "NOTE: You must unmount all mounted microSD partitions first with umount"
	exit 1
fi

IMAGEFILE=$2
DEVICE=$1

if [ -e $IMAGEFILE ]; then
	read -r -p "This will COMPLETELY OVERWRITE $IMAGEFILE.  Are you sure? [y/N] " response
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
fi

ISMOUNTED=`mount -l | grep $DEVICE | wc -l`

if [ $ISMOUNTED -gt 0 ]; then
	read -r -p "Check that all $DEVICE partitions are unmounted.  Ready to continue? [y/N] " response
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
fi

echo "[`date`] Reading $IMAGEFILE from $DEVICE..."
sudo dd if=$DEVICE of=$IMAGEFILE bs=4M oflag=sync status=noxfer
echo "[`date`] Done."
