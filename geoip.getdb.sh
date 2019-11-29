#!/bin/bash
if [ ! -e /etc/geoip ]; then
	mkdir /etc/geoip
fi

cd /etc/geoip
if [ -e GeoIP.dat ]; then
#	mv GeoIP.dat GeoIP.dat.bak
	mv GeoLiteCity.dat GeoLiteCity.dat.bak
fi

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz

gunzip GeoLiteCity.dat.gz

if [ $? -gt 0 ]; then
	echo "ERROR: Unamble to unzip GeoLiteCity.dat.gz.  Reverting to backup."
	cp GeoLiteCity.dat.bak GeoLiteCity.dat
fi

# Now restart apache
service apache2 restart

