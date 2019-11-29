#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <output path> <Base URL>"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

OUTPUTPATH=$1
BASEURL=$2
SKIPEXE=""

if [ -e /usr/share/skipfish/skipfish ]; then
	SKIPEXE="/usr/share/skipfish/skipfish"
else
	SKIPEXE="/usr/bin/skipfish"
fi

echo "$OUTPUTPATH" | grep -q "^\/"

if [ $? -gt 0 ]; then
	# relative path.  Append to pwd
	CURDIR=`pwd`
	OUTPUTPATH=`echo "$CURDIR/$OUTPUTPATH"`
fi

if [ ! -d $OUTPUTPATH ]; then
	echo "Creating directory $OUTPUTPATH..."
	mkdir -p $OUTPUTPATH
fi

echo "[`date`] Running skipfish -O -b f -o $OUTPUTPATH $BASEURL"
cd /usr/share/skipfish
# -O Don't submit any forms
# -Y Don'f fuzz extensions in directory brute force
# -b f   Simulate a firefox browser
# -W <file> default wordlist file
$SKIPEXE -O -Y -b f -W /usr/share/skipfish/dictionaries/default.wl -o $OUTPUTPATH $BASEURL
echo "[`date`] Done"


