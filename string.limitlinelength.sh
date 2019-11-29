#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <input file> <max length>"
	echo "Takes input file and removes all lines greater than <max length>"

	exit 1
fi

cat $1 | awk "length <= $2"


