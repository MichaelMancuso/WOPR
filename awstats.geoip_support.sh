#!/bin/bash

# NOTE: Use GeoIPFree, the others don't work!
#

mkdir /etc/geoip
cd /etc/geoip
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip GeoIP.dat.gz
 
apt-get install libgeoip-dev libgeoip1 geoip-bin make gcc zlib1g-dev
cpan install Geo::IP
cpan install Geo:IPfree

sed -i "s|# LoadPlugin=\"geoip GEOIP_STANDARD .*|LoadPlugin=\"geoip GEOIP_STANDARD /etc/geoip/GeoIP.dat\"|" /etc/awstats/*.conf

cd /tmp
wget http://search.cpan.org/CPAN/authors/id/M/MA/MAXMIND/Geo-IP-PurePerl-1.26.tar.gz
tar -zxvf Geo-IP-PurePerl-1.26.tar.gz
cd Geo-IP-PurePerl-1.26
perl Makefile.PL
make
make install

sed -i "s|geoip|geoippureperl|" /usr/local/awstats/wwwroot/cgi-bin/plugins/geoip.pm
sed -i "s|Geo/IP/PurePerl.pm|/usr/share/perl5/XML/SAX/PurePerl.pm|" /usr/local/awstats/wwwroot/cgi-bin/plugins/geoip.pm

cd /tmp
wget http://www.maxmind.com/download/geoip/api/c/GeoIP-1.4.3.tar.gz
tar -zxvf GeoIP-1.4.3.tar.gz
cd GeoIP-1.4.3
./configure
make
make install

