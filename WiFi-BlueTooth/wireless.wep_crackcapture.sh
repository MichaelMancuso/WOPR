#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage $0 <.cap file>"
	echo "Where <.cap file> was captured via airodump or wireless.wep_capture_ivs.sh"
	echo "Note: This leverages aircrack-ptw to crack.  If this fails,"
	echo "aircrack-ng <cap file> can be tried, however around 5000 IV's"
	echo "will have to have been captured."
	exit 1
fi

if [ -e /usr/bin/aircrack-ptw ]; then
	aircrack-ptw $1
else
	echo "Unable to locate /usr/bin/aircrack-ptw required for cracking."
	echo "Please download and install aircrack-ptw (note this is not "
	echo "part of the aircrack-ng package."
fi



