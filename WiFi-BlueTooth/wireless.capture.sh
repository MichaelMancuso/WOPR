#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <channel> [bssid]"
	echo "Where:"
	echo "<channel> = channel to capture on."
	echo "[bssid]   = optional access point filter."
	echo " "
	echo "Note: This will start capture, but the script wireless.force_wep.sh or wireless.wpa_capture_handshake should be used to force AP's and/or clients to generate iv's"
	exit 1
fi

CHANNEL=$1

if [ $# -gt 1 ]; then
	BSSID=$2
else
	BSSID=""
fi

# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ ${#MONINTERFACE} -gt 0 ]; then
	echo "Capturing on $MONINTERFACE..."

	if [ ${#BSSID} -gt 0 ]; then
		airodump-ng --channel $CHANNEL --write ch$CHANNEL $MONINTERFACE --bssid $BSSID
	else
		airodump-ng --channel $CHANNEL --write ch$CHANNEL $MONINTERFACE
	fi
else
	if [ $VERBOSE -eq 1 ]; then
		echo "ERROR: No monitoring interface configured."
	fi
fi

