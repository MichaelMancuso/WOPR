#!/bin/bash

nslookup wpad > /dev/null

if [ $? -gt 0 ]; then
	echo "No DNS WPAD entry found.  Try direct."
	exit 1
fi

RESULTS=`wget -O- http://wpad/proxy.pac 2>/dev/null`

if [ $? -eq 0 ]; then
	echo "Found http://wpad/proxy.pac"
	echo ""
	echo "$RESULTS"
else
	RESULTS=`wget -O- http://wpad/wpad.dat 2>/dev/null`
	
	if [ $? -eq 0 ]; then
		echo "Found http://wpad/wpad.dat"
		echo ""
		echo "$RESULTS"
	else
		echo "No DNS-based WPAD configuration found."
		return 1
	fi
fi

