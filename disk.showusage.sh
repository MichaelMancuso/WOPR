#!/bin/bash

DIRECTORY="."

if [ $# -gt 0 ]; then
	DIRECTORY=$1
fi

CONTENTS=`ls -1 $DIRECTORY`

for DIRENTRY in $CONTENTS
do
	if [ -d $DIRENTRY ]; then
#		SPACE=`du -ch $DIRENTRY 2>/dev/null | grep "total$" | sed "s|\stotal||"`
		SPACE=`du -ch $DIRENTRY 2>/dev/null | grep "total$" | grep -Eio "^[0-9\.]{1,}[KMG ]" | head -1`
		if [ ${#SPACE} -eq 0 ]; then
				SPACE=0
		fi
		
		if [ ${#DIRENTRY} -gt 0 ]; then
			echo "$DIRENTRY   $SPACE"
		fi
	fi
done
