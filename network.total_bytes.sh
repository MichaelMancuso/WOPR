#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <interface>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INTERFACE=$1

# Format can be 2 different outputs.
ISOLDFORMAT=`ifconfig $INTERFACE | grep "RX packets.*bytes" | wc -l`

if [ $ISOLDFORMAT -eq 0 ]; then
	# Ubuntu
        # RX packets:1270205 errors:0 dropped:0 overruns:0 frame:0
        # TX packets:2481405 errors:0 dropped:0 overruns:0 carrier:0
        # collisions:0 txqueuelen:1000 
        # RX bytes:702854659 (702.8 MB)  TX bytes:3585768414 (3.5 GB)

	IFCFG=`ifconfig $INTERFACE`

	RXBYTES=`echo "$IFCFG" | grep "RX bytes" | sed "s|:| |g" | awk '$3 ~ /[0-9.]+/ { print $3 }'`
	TXBYTES=`echo "$IFCFG" | grep "RX bytes" | sed "s|:| |g" | awk '$8 ~ /[0-9.]+/ { print $8 }'`
else
	# Raspbian:
        # RX packets 12343  bytes 2073562 (1.9 MiB)
        # RX errors 0  dropped 18  overruns 0  frame 0
        # TX packets 3050  bytes 635564 (620.6 KiB)
        # TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

	IFCFG=`ifconfig $INTERFACE`

	RXBYTES=`echo "$IFCFG" | grep "RX packets" | awk '$5 ~ /[0-9.]+/ { print $5 }'`
	TXBYTES=`echo "$IFCFG" | grep "TX packets" | awk '$5 ~ /[0-9.]+/ { print $5 }'`
fi

if [ ${#RXBYTES} -eq 0 -o ${#TXBYTES} -eq 0 ]; then
	echo "ERROR parsing bytes."
	exit 2
fi

# awk "BEGIN {print \"Total Bytes: \", $RXBYTES + $TXBYTES}"
gawk "BEGIN {printf(\"Total Bytes: %'d\n\", $RXBYTES + $TXBYTES)}"


