#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <IP input file>"
	echo "$0 will take each IP address (1 per line) and do a geoip and ISP lookup on it."
	echo ""
	exit 1
fi

which geoiplookup > /dev/null

if [ $? -gt 0 ]; then
	echo "[`date`] geoiplookup missing.  Installing geoip-bin..." >&2
	
	apt-get -y install geoip-bin
fi

if [ ! -e /usr/share/GeoIP/GeoLiteCity.dat ]; then
	echo "[`date`] GeoIP databases missing.  Getting latest..." >&2
	
	CURDIR=`pwd`

	cd /tmp

	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
	wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
	gunzip GeoIP.dat.gz
	gunzip GeoIPASNum.dat.gz
	gunzip GeoLiteCity.dat.gz
	cp GeoIP.dat GeoIPASNum.dat GeoLiteCity.dat /usr/share/GeoIP/ 

	cd $CURDIR
fi

INPUTFILE="$1"

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find $INPUTFILE."
	exit 2
fi

# Change whitespace to a new line
IFS_BAK=$IFS
IFS="
"

ADDRESSES=`cat $INPUTFILE | grep -v "^$"`

echo "IP	Country	GeoIP Location	ISP/ASN Owner"

for CURHOST in $ADDRESSES
do
	if [ -e /usr/share/GeoIP/GeoIP.dat ]; then
		COUNTRYSHORT=`geoiplookup -f /usr/share/GeoIP/GeoIP.dat $CURHOST 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	else
		COUNTRYSHORT="No GeoIP database"
	fi

	if [ -e /usr/share/GeoIP/GeoLiteCity.dat ]; then
		COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURHOST | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	else
		COUNTRYLONG="N/A"
	fi

	if [ -e /usr/share/GeoIP/GeoIPASNum.dat ]; then
		ISP=`geoiplookup -f /usr/share/GeoIP/GeoIPASNum.dat $CURHOST | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	else
		ISP="No ISP database"
	fi

	echo "$CURHOST	$COUNTRYSHORT	$COUNTRYLONG	$ISP"
done

# Change whitespace back
IFS=$IFS_BAK
IFS_BAK=
