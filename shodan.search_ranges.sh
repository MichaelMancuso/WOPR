#!/bin/bash

ShowUsage() {
	echo "Usage: $0 --key=<Shodan API Key> --file=<input file> [--detail] [--gnmap]"
	echo "$0 will expand all of the subnets in the specified file and query each IP against the shodan database.  Input file should be <network>/<prefix> or just IP"
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

APIKEY=""
DUMPJSON=""
GNMAPOUTPUT=""

for i in $*
do
	case $i in
    	--file=*)
		INPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--key=*)
		APIKEY=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--detail)
		DUMPJSON="--detail"
		;;
	--gnmap)
		GNMAPOUTPUT="--gnmap"
		;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done


if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find $INPUTFILE."
	exit 1
fi

TARGETS=`cat $INPUTFILE`

IFS_BAK=$IFS
IFS="
"

for CURENTRY in $TARGETS
do
	echo $CURENTRY | grep -Eq "\/"

	if [ $? -eq 0 ]; then
		IPLIST=`ip.expandprefix.sh $CURENTRY`

		for CURIP in $IPLIST
		do
			shodan.search.sh --key=$APIKEY --ip=$CURIP $DUMPJSON $GNMAPOUTPUT 
		done
	else
		shodan.search.sh --key=$APIKEY --ip=$CURENTRY $DUMPJSON $GNMAPOUTPUT 
	fi
done

IFS=$IFS_BAK
IFS_BAK=

