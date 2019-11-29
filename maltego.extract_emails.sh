#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <XML file>"
	echo ""
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

XMLFILE="$1"

if [ ! -e $XMLFILE ]; then
	echo "ERROR: Unable to find $XMLFILE"
	exit 2
fi

XMLDOC=`cat $XMLFILE`

IFS_BAK=$IFS
IFS="
"

HASEMAIL=0
HASURLS=0

CUREMAIL=""

echo "email,URL,Description"

for curLine in $XMLDOC
do
	if [ $HASEMAIL -eq 1 ]; then
		CUREMAIL=`echo "$curLine" | grep -Eio ">.*?<" | sed "s|<||g" | sed "s|>||g"`
		HASEMAIL=0	
	else
		if [ $HASURLS -eq 1 ]; then
			TMPURLS=`echo "$curLine" | sed "s|.*<mtg:Value>||g"`
			URLS=`echo "$TMPURLS" | cut -d ' ' -f 1`
			DESCRIPTION=`echo "$TMPURLS" | sed "s|$URLS||" | sed "s|^ ||"`
			HASURLS=0
			echo "$CUREMAIL,\"$URLS\",\"$DESCRIPTION\""
		else
			echo "$curLine" | grep -q "name=\"email\""

			if [ $? -eq 0 ]; then
				HASEMAIL=1		
			fi

			echo "$curLine" | grep -q "name=\"URLS\""

			if [ $? -eq 0 ]; then
				HASURLS=1
			fi
		fi
	fi
done

IFS=$IFS_BAK
IFS_BAK=

