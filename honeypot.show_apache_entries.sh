#!/bin/bash

IFS_BAK=$IFS
IFS="
"
echo "[`date`] Apache http entries"

LOGENTRIES=`cat /var/log/apache2/access.log | grep -v awstats | grep -aEv -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}"`

for CURLINE in $LOGENTRIES
do
	CURIP=`echo "$CURLINE" | grep -Eo " [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} " | sed "s| ||g"`
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT ($COUNTRYLONG)" | sed "s|^ ||g"`
	CURLINE=`echo "$CURLINE" | sed "s|-0500 |-0500\t|g" | sed "s| login attempt |\t|g" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g"`
	echo "$COUNTRY	$CURLINE"
done
echo ""

echo "[`date`] Apache https entries"

LOGENTRIES=`cat /var/log/apache2/access_ssl.log | grep -v awstats | grep -aEv -e "172\.22\.16\.[0-9]{1,3}" -e "172\.22\.1[2-5]\.[0-9]{1,3}" -e "192\.168\.[0-9]{1,3}\.[0-9]{1,3}"`

for CURLINE in $LOGENTRIES
do
	CURIP=`echo "$CURLINE" | grep -Eo " [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} " | sed "s| ||g"`
	COUNTRYSHORT=`geoiplookup  -f /usr/share/GeoIP/GeoIP.dat $CURIP 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
	COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURIP | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
	COUNTRY=`echo "$COUNTRYSHORT ($COUNTRYLONG)" | sed "s|^ ||g"`
	CURLINE=`echo "$CURLINE" | sed "s|-0500 |-0500\t|g" | sed "s| login attempt |\t|g" | sed "s| failed|\tfailed|g" | sed "s| success|\tsuccess|g"`
	echo "$COUNTRY	$CURLINE"
done
echo ""

IFS=$IFS_BAK
IFS_BAK=
