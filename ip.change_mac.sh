#!/bin/sh

ShowUsage() {
	echo "$0 <interface> <mac address>"
	echo "Sets the ethernet mac address for the specified interface to <mac address>"
	echo "<mac address>   6-byte colon separated ethernet mac address (e.g.: 01:02:03:04:05:06)"
	echo ""
	echo "Note: If the interface is a wireless interface (especially madwifi)"
	echo "macchanger will need to be installed (apt-get install macchanger)"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

INTERFACE=$1
MACADDRESS=$2

# Validate interface
ifconfig -a | grep -i "^$INTERFACE" > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to find $INTERFACE.  Please check ifconfig -a"
	exit 2
fi

# Validate mac

NUMENTRIES=`echo "$MACADDRESS" | grep -o ":" | wc -l`

if [ $NUMENTRIES -ne 5 ]; then
	echo "ERROR: Mac address $MACADDRESS does not appear to be appropriately"
	echo "colon-separated (6 octets, 5 colons).  Please check and try again."

	exit 3
fi

NUMENTRIES=`echo "$MACADDRESS" | grep -Po "[A-Fa-f0-9]{2,2}" | wc -l`

if [ $NUMENTRIES -ne 6 ]; then
	echo "ERROR: Mac address $MACADDRESS does not appear to be in an appropriate"
	echo "format (6 octets, 5 colons).  Please check and try again."

	exit 3
fi

# Check if wireless wifi[0-9] or ath[0-9] interface

ISWIRELESS=0

echo "$INTERFACE" | grep -i "ath[0-9]" > /dev/null

if [ $? -eq 0 ]; then
	ISWIRELESS=1
else
	echo "$INTERFACE" | grep -i "wifi[0-9]" > /dev/null

	if [ $? -eq 0 ]; then
		ISWIRELESS=1
	fi
fi

if [ $ISWIRELESS -eq 0 ]; then
	ifconfig $INTERFACE down
	ifconfig $INTERFACE hw ether $MACADDRESS
	ifconfig $INTERFACE up
else
	# First check for macchanger
	macchanger --help > /dev/null

	if [ $? -gt 0 ]; then
		echo "ERROR: Unable to find macchanger.  Please install (apt-get install macchanger)"
		exit 2
	fi

	wlanconfig $INTERFACE destroy
	ifconfig wifi0 down
	macchanger --mac=$MACADDRESS wifi0
	wlanconfig ath0 create wlandev wifi0 wlanmode managed -uniquebssid
	ifconfig $INTERFACE up
fi

