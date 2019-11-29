#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <user>@<ssh server>:<directory> <local mount point>"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

sshfs $1 $2 -C


