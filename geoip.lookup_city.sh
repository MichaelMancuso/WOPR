#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 [--short] <ip>"
	exit 1
fi

if [ -e /usr/share/GeoIP/GeoLiteCity.dat ]; then
if [ $# -eq 1 ]; then
	geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $1 | sed "s|^GeoIP .*: ||" | cut -f1-6 -d","
else
	geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $1 | sed "s|^GeoIP .*: ||" | cut -f1-4 -d","
fi
else
	echo "ERROR: unable to find /usr/share/GeoIP/GeoLiteCity.dat.  Please run geoip.updatedb.sh."
	exit 1
fi
