#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <URL> <destination directory>"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

URL="$1"
TARGETDIR=$2

if [ ! -e $TARGETDIR ]; then
	echo "ERROR: Unable to find target directory '$TARGETDIR'"
	exit 2
fi

cd $TARGETDIR

httrack --user-agent "Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20130401 Firefox/21.0" --mirror $URL

