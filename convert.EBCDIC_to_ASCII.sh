#!/bin/bash

ShowUsage () {
	echo "$0 <input file> <output file>"
	echo "$0 converts EBCDIC to ASCII"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE=$1
OUTPUTFILE=$2

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Cannot find $INPUTFILE"
	exit 1
fi

dd conv=ascii if=$INPUTFILE of=$OUTPUTFILE
if [ ! -e $OUTPUTFILE ]; then
	echo "ERROR: Unable to generate $OUTPUTFILE"
	exit 2
fi

strings $OUTPUTFILE > $OUTPUTFILE.strings.txt




