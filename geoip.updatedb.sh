#!/bin/bash

if [ ! -e /usr/share/GeoIP ]; then
	echo "ERROR: /usr/share/GeoIP does not exist.  Install geoip first."
	exit 1
fi

if [ ! -e /usr/share/GeoIP/bak ]; then
	mkdir /usr/share/GeoIP/bak
	cp /usr/share/GeoIP/*.dat /usr/share/GeoIP/bak
fi

cd /tmp

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz

gunzip GeoIP.dat.gz
gunzip GeoIPASNum.dat.gz
gunzip GeoLiteCity.dat.gz
gunzip GeoLite2-City.mmdb.gz
cp GeoIP.dat GeoIPASNum.dat GeoLiteCity.dat GeoLite2-City.mmdb /usr/share/GeoIP/ 

if [ -e /etc/geoip ]; then
	cp GeoIP.dat GeoIPASNum.dat GeoLiteCity.dat GeoLite2-City.mmdb /etc/geoip/
fi

