#!/bin/bash

which iftop > /dev/null

if [ $? -gt 0 ]; then
	apt-get install iftop
fi

which iftop > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Please apt-get install iftop first."
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 <interface>"
	exit 2
fi

iftop -i $1

