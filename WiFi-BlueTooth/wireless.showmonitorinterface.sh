#!/bin/sh

MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

VERBOSE=0

if [ $# -gt 0 ]; then
	case $1 in
	--help)
		echo "Usage: $0 [--help] [-v]"
		echo "   -v     Display readable messages (verbose)"
		echo "  --help  This screen"
		exit 1
	;;
	-v)
		VERBOSE=1
	;;
	esac
fi

if [ $VERBOSE -eq 1 ]; then
	echo "Checking for existing monitor mode interfaces..."
fi

if [ ${#MONINTERFACE} -gt 0 ]; then
	if [ $VERBOSE -eq 1 ]; then
		echo "Monitoring interface(s):"
	fi

	echo $MONINTERFACE
else
	echo "ERROR: No monitoring interfaces configured." >&2

	exit 2
fi


