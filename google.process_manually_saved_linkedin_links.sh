#!/bin/bash

# google.process_manually_saved_linkedin_links.sh

ShowUsage() {
	echo "Usage: $0 <file>"
	echo "Where file simply contains the URLs of linkedin profiles acquired with a google search: \"<company name>\" site:linkedin.com/pub"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

LINKFILE="$1"

if [ ! -e $LINKFILE ]; then
	echo "ERROR: Unable to find $LINKFILE."
	exit 2
fi

NAMES=`cat $LINKFILE | grep -Pio "https://www.linkedin.com.*" | grep -v "\&" | sed "s|http.*pub/||g" | grep -vi "greater"`

IFS_BAK=$IFS
IFS="
"

TMPFILE="/tmp/$LINKFILE.tmp"

if [ -e $TMPFILE ]; then
	rm $TMPFILE
fi

for CURNAME in $NAMES
do
	HASDASH=`echo "$CURNAME" | grep "\-" | wc -l`

	if [ $HASDASH -eq 1 ]; then
		TRUENAME=`echo "$CURNAME" | sed "s|/.*||" | sed "s|-| |g"`
	else
		TRUENAME=`echo "$CURNAME" | sed "s|dir/||g" | sed "s|/| |g"`
	fi

	echo "$TRUENAME" >> $TMPFILE
done

cat $TMPFILE | sort -uf

rm $TMPFILE

IFS=$IFS_BAK
IFS_BAK=

