#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <ip or /prefix subnet>"
	echo "$0 will call nbtscan to use netbios lookups to resolve the specified IP's name."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"

echo "$TARGET" | grep -E "\/"

if [ $? -eq 0 ]; then
	# A range was specified
	nbtscan -r $TARGET
else
	ntbscan $TARGET
fi

