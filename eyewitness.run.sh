#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <input file> <directory for output>"
	echo "Where <input file> is either a file list of URLs, an nmap XML output, or a .nessus scan file."
	echo ""
}

if [ $# -lt 2 ]; then 
	ShowUsage
	exit 1
fi

INPUTFILE=$1
OUTPUTDIR=$2

FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"
USERAGENTSTRING="$FIREFOXUSERAGENTSTRING"

ISXML=`echo "$INPUTFILE" | grep "\.xml$" | wc -l`

if [ $ISXML -eq 0 ]; then
	/opt/eyewitness/EyeWitness.py --all-protocols --user-agent "$USERAGENTSTRING" -f $INPUTFILE -d $OUTPUTDIR
else
	/opt/eyewitness/EyeWitness.py --all-protocols --user-agent "$USERAGENTSTRING" -x $INPUTFILE -d $OUTPUTDIR
fi
