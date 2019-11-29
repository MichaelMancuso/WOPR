#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <input file> [--printoriginal] [--addcount]"
	echo "$0 will print line lengths for each line in file."
	echo "--printoriginal will output <line length>:<original line>"
	echo "--addcount will add <# of 1's> and <# of 0's> to the output as: <line length>:<# of 1's>:<# of 0's>.  This can be combined with --printoriginal."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

PRINTORIGINAL=0
ADDCOUNT=0

for i in $*
do
	case $i in
    	--printoriginal)
		PRINTORIGINAL=1
		;;
	--addcount)
		ADDCOUNT=1
		;;
	*)
		FILENAME="$i"
		;;
	esac
done

if [ ! -e $FILENAME ]; then
	echo "ERROR: $FILENAME does not exist."
	exit 2
fi

FILELINES=`cat $FILENAME`

for CURLINE in $FILELINES
do
	if [ $PRINTORIGINAL -eq 0 ]; then
		if [ $ADDCOUNT -eq 0 ]; then
			echo "${#CURLINE}"
		else
			NUMONES=`echo "$CURLINE" | tr -d -c '1' | awk '{ print length; }'`
			NUMZEROS=`echo "$CURLINE" | tr -d -c '0' | awk '{ print length; }'`
			echo "${#CURLINE}:$NUMONES:$NUMZEROS"
		fi
	else
		if [ $ADDCOUNT -eq 0 ]; then
			echo "${#CURLINE}:$CURLINE"
		else
			NUMONES=`echo "$CURLINE" | tr -d -c '1' | awk '{ print length; }'`
			NUMZEROS=`echo "$CURLINE" | tr -d -c '0' | awk '{ print length; }'`
			echo "${#CURLINE}:$NUMONES:$NUMZEROS:$CURLINE"
		fi
	fi
done

