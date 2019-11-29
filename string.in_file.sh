#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <string> <file>"
	echo "$0 will determine if the specified string is in the specified file."
	echo "if <string> starts with 'file:', strings are loaded from the specified file."
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

if [ ! -e $2 ]; then
	echo "ERROR: $2 does not exist."
	exit 2
fi

TARGET="$1"

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	TARGET=`echo "$TARGET" | sed "s|^file:||"`
	if [ ! -e $TARGET ]; then
		echo "ERROR: Unable to find file $TARGET."
		exit 2
	fi

	echo "[`date`] Reading URLs from $TARGET..."
	TARGETLIST=`cat $TARGET | grep -v "^$"`

IFS_BAK=$IFS
IFS="
"
	for CURTARGET in $TARGETLIST
	do
		grep -Fq "$CURTARGET" $2

		if [ $? -eq 0 ]; then
			echo "$CURTARGET is in $2"
		else
			echo "$CURTARGET is not in $2"
		fi
	done
IFS=$IFS_BAK
IFS_BAK=
else
	grep -Fq "$1" $2

	if [ $? -eq 0 ]; then
		echo "$1 is in $2"
	else
		echo "$1 is not in $2"
	fi
fi


