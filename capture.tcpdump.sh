#!/bin/sh
ShowUsage() {
	echo "Usage: $0 --src=<src cidr or host> --output=<outputfile>"
	echo ""
	echo "$0 runs tcpdump and writes output to <outputfile>.  Size is capped at "
	echo "65535 packets."
	echo ""
	echo "Parameters:"
	echo "--src     Specify either host (e.g. 10.1.1.1) or CIDR (e.g. 10.1.1.0/24) to capture"
	echo "--output  File to write output to."
	echo ""
}

if [ $# -eq 0 ]; then
	if [ "$(id -u)" != "0" ]; then
		echo ""
		echo "IMPORTANT: This script must be run as root.  Please use sudo $0 to run."
		echo ""
	fi
	ShowUsage
	exit 1
fi

#  Must be superuser
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

CAPINTERFACE="eth1"
SRC=""
OUTPUTFILE=""
MAXSIZE=0

for i in $*
do
	case $i in
    	--src=*)
		SRC=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		grep -E "\/" > /dev/null
		
		if [ $? -eq 0 ]; then
			# CIDR
			SRC=`echo "src net $SRC"`
		else
			# host
			SRC=`echo "src $SRC"`
		fi
		;;
    	--output=*)
			OUTPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
		--help)
			ShowUsage
			exit 1
		;;
	esac
done

if [ ${#OUTPUTFILE} -eq 0 ]; then
	echo "ERROR: Please provide an output file name."
	exit 2
fi

# -A print each packet in ASCII [Not used on this capture]
# -i use specified interface
# -vv store whole packet
# -s 0  Don't truncate packet
# -w write to file
# -c stop after 65535 (safety cap)
tcpdump -S -i $CAPINTERFACE -vv -s 0 -w $OUTPUTFILE -c 65535 $SRC
