#!/bin/sh

if [ $# -lt 3 ]; then
	echo "Usage $0 <SSID> <password> <.cap file>"
	echo "Where <.cap file> was captured via airodump or wireless.capture.sh"
	echo "NOTE: A <.capfile -dec> version will be generated when run.  Any previous -dec file will be overwritten so if using for multiple SSID's copy the dec file first."

	exit 1
fi

if [ ! -e $3 ]; then
	echo "ERROR: Unable to find capture file $3"
	exit 1
fi

airdecap-ng -e '$1' -p '$2" $3

