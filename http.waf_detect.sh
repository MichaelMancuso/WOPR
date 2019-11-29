#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <url>"
	echo "$0 will attempt to identify any web app firewall (WAF) protecting the specified URL."
	echo "If <url> starts with file: URLs will be read from the specified file."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
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

	for CURTARGET in $TARGETLIST
	do
		echo "[`date`] Testing $CURTARGET..."
		wafw00f $CURTARGET
	done
else
	wafw00f $TARGET
fi

echo "[`date`] Done."

