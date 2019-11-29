#!/bin/bash

if [ -e /sys/class/thermal/thermal_zone0/temp ]; then
	CURVAL=`cat /sys/class/thermal/thermal_zone0/temp`
	WHOLENUM=`echo "$CURVAL" | cut -c1-2`
	# DECIMAL=`echo "$CURVAL" | cut -c3-5`
	DECIMAL=`echo "$CURVAL" | cut -c3-4`

	echo "CPU Temperature: $WHOLENUM.$DECIMAL C"
else
	echo "ERROR: /sys/class/thermal/thermal_zone0/temp does not exist.  System may not be able to monitor temperature."
fi

if [ -e /usr/bin/nvidia-smi ]; then
	if [ -e /usr/bin/nvidia.show_card_temp.sh ]; then
		nvidia.show_card_temp.sh
	fi
fi
