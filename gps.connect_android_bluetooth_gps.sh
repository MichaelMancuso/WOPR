#!/bin/bash

# See this for reference:
# http://www.jillybunch.com/sharegps/nmea-bluetooth-linux.html

# You can also use the command 'sdptool browse <bluetooth mac> to see capabilities.

ShowUsage() {
	echo "Usage: $0 <bluetoothmac>"

	echo "Bluetooth device scan:"
	hcitool scan
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

# BLUETOOTHMAC="20:7C:8F:C4:62:AB"
BLUETOOTHMAC="$1"

rfcomm connect /dev/rfcomm1 $BLUETOOTHMAC 5

