#!/bin/sh

NUMRADIUS=`ps aux | grep radiusd | grep -v grep | wc -l`

if [ $NUMRADIUS -eq 0 ]; then
	echo "Starting RADIUS Server..."
#	radiusd
	freeradius-wpe
else
	echo "radiusd already running.  Continuing..."
fi

echo "Captured credentials..."
#if [ ! -e /usr/local/var/log/radius/freeradius-server-wpe.log ]; then
#	touch /usr/local/var/log/radius/freeradius-server-wpe.log
#fi

#tail -f /usr/local/var/log/radius/freeradius-server-wpe.log
tail -f /var/log/freeradius-wpe/radius.log

