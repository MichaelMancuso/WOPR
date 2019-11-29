#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <ip>"
	exit 1
fi

if [ -e /usr/share/GeoIP/GeoIPASNum.dat ]; then
	ISP=`geoiplookup -f /usr/share/GeoIP/GeoIPASNum.dat $CURHOST | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
else
	echo "ERROR: unable to find /usr/share/GeoIP/GeoIPASNum.dat.  Please run geoip.updatedb.sh."
	exit 1
fi


