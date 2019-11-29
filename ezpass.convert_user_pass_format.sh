#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <input file>"
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE="$1"

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find file '$INPUTFILE'"
	exit 2
fi

LINES=`cat $INPUTFILE | grep "\(.*\)"`

IFS_BAK=$IFS
IFS="
"

for CURLINE in $LINES; do
	PASSWORD=`echo "$CURLINE" | grep -Po "^.*? " | sed "s| ||g"`
	USERNAME=`echo "$CURLINE" | grep -Eio "\(.*\)" | sed "s|^(||" | sed "s|)$||" | sed "s|@.*||"`

	if [ ${#USERNAME} -gt 0 ]; then
		echo "$USERNAME $PASSWORD"
	fi
done

# Change whitespace back
IFS=$IFS_BAK
IFS_BAK=

