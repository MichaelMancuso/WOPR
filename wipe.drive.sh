#!/bin/bash

ShowUsage() {
	echo "Usage: wipe.drive.sh <device>"
	echo "ex: $0 /dev/sdb"
	echo "$0 will wipe the partition with 2 passes, then overwrite with 0's on a 3rd pass."
}

shred -n 2 -z -v $1

