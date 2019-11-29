#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <input file>"
	echo "$0 will remove any leading and trailing 0's from the string in the specified file."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi


FILENAME=$1

if [ ! -e $FILENAME ]; then
	echo "ERROR: $FILENAME does not exist."
	exit 2
fi

cat $FILENAME | grep -Eio "1.*" | sed 's/0*$//'

