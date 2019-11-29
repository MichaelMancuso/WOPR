#!/bin/sh

if [ $# -gt 0 ]; then
	case $1 in
	--help)
		echo "Usage: $0 [--help] [adapter]"
		echo "  --help  This screen"
		echo "  adapter The specific adapter to put in monitoring mode."
		echo "  If no adapter is provided the first wireless adapter "
		echo "  returned from iwconfig is used."
		exit 1
	;;
	esac
fi

echo "Checking for existing monitor mode interfaces..."

if [ $# -gt 0 ]; then
	SPECIFICADAPTER=$1
else
	SPECIFICADAPTER=""
fi

MONINTERFACE=`wireless.showmonitorinterface.sh 2> /dev/null`

if [ ${#MONINTERFACE} -gt 0 ]; then
	# If a monitoring interface already exists, check one was provided
	# on the command line and if it's different.

	if [ ${#SPECIFICADAPTER} -gt 0 ]; then
		echo "$MONINTERFACE" | grep "$SPECIFICADAPTER" > /dev/null

		if [ $? -eq 0 ]; then
			# The adapter is already in monitor mode
			echo "Monitoring interface '$MONINTERFACE' already exists."
	
			exit 0
		fi
	else
		# Nothing specified and an adapter is already in monitor mode.
		echo "Monitoring interface '$MONINTERFACE' already exists."
	
		exit 0
	fi
fi

# Finding wlan interface to use...
# Discover name
if [ ${#SPECIFICADAPTER} -gt 0 ]; then
	WLANINTERFACE=$SPECIFICADAPTER
else
	WLANINTERFACE=`iwconfig 2> /dev/null | grep "ESSID" | grep -Eo "^[a-zA-Z0-9]{3,7}"`
fi

if [ ${#WLANINTERFACE} -eq 0 ]; then
	iwconfig

	echo "ERROR: Unable to find wireless interface to use." >&2
	echo ""
	exit 2
fi

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

echo "Checking for conflicting services..."
# avahi-daemon
TMPRESULT=`ps -A | grep "avahi-daemon"  | wc -l`
if [ $TMPRESULT -gt 0 ]; then
	echo "Stopping avahi-daemon..."
	service avahi-daemon stop
fi

# network manager
TMPRESULT=`ps -A | grep "NetworkManager" | wc -l`

if [ $TMPRESULT -gt 0 ]; then
	echo "Stopping network manager..."
	/etc/init.d/network-manager stop
fi

# wpa_supplicant
TMPRESULT=`ps -A | grep "wpa_supplicant" | wc -l`

if [ $TMPRESULT -gt 0 ]; then
	echo "Killing wpa_supplicant..."
	PROCID=`ps -A | grep "wpa_supplicant" | grep -Eio "^.[0-9]{1,5}" | sed "s| ||g"`
	
	if [ $PROCID -gt 0 ]; then
		kill $PROCID
	else
		echo "Error determining wpa_supplicant process id."
	fi
fi

echo "Setting $WLANINTERFACE into monitor mode..."

echo $WLANINTERFACE | grep "ath[0-9]" > /dev/null

if [ $? -gt 0 ]; then
	# don't try this for atheros cards.  Need to destroy/create
	airmon-ng start $WLANINTERFACE

	if [ $? -eq 0 ]; then
		iwconfig 2> /dev/null | grep -A 1 "^$WLANINTERFACE"
	else
		echo "ERROR: Unable to put $WLANINTERFACE in monitor mode." >&2
		exit 2
	fi
else
	# Atheros card.  Use wireless.setcardmode.sh
	wireless.setcardmode.sh --mode=monitor --interface=$WLANINTERFACE
fi

