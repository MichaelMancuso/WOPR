#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <input file>"
	echo "$0 will take an input file with multiple domains and query for site links using google.searchsitelinks.sh.  Each domain will have their output written to <domain>.google.txt"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE=$1

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find $INPUTFILE"
	exit 2
fi

DOMAINLIST=`cat $INPUTFILE`

for CURDOMAIN in $DOMAINLIST
do
	google.searchsitelinks.sh $CURDOMAIN > $CURDOMAIN.google.txt
	sleep 3s
done




