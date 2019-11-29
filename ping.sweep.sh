#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <first 3 octets of subnet>"
	echo ""
	echo "$0 will ping each host in the specified subnet and indicate which ones are online."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

SUBNET=`echo "$1" | grep -Eio "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

if [ ${#SUBNET} -eq 0 ]; then
	echo "ERROR: Unable to parse subnet from $1"
	exit 2
fi


echo "[`date`] Starting ping sweep of $SUBNET.0/24..."

for i in `seq 1 255`
do
	HOSTIP=`echo "$SUBNET.$i"`

	ping -c 1 $HOSTIP > /dev/null

	if [ $? -eq 0 ]; then
		echo "$HOSTIP is online"
	fi
done

echo "[`date`] Done."

