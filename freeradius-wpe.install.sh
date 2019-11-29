#!/bin/sh

if [ ! -e freeradius-server-2.0.2.tar.gz ]; then
	wget http://wirelessdefence.org/Contents/Files/freeradius-server-2.02.tar.gz

	if [ ! -e freeradius-server-2.0.2.tar.gz ]; then
		echo "ERROR: Unable to find or download freeradius-server-2.0.2.tar.gz"
		exit 2
	fi
fi

if [ ! -e freeradius-wpe-2.0.2.patch ]; then
	wget http://www.willhackforsushi.com/code/freeradius-wpe/freeradius-wpe-2.0.2.patch

	if [ ! -e freeradius-wpe-2.0.2.patch ]; then
		echo "ERROR: Unable to find or download freeradius-wpe patch."
		exit 2
	fi
fi

tar -zxvf freeradius-server-2.0.2.tar.gz
cd freeradius-server-2.0.2

echo "Building freeradius..."
patch -p1 < ../freeradius-wpe-2.0.2.patch

./configure && make && sudo make install && sudo ldconfig

echo "Building certificates..."
cd raddb/certs

cp server.cnf server.cnf.bak
cp  ca.cnf ca.cnf.bak
cat server.cnf | sed "s|= FR|= US|" | sed "s|= Radius|= California|" | \
		sed "s|= Somewhere|= VeriSign Trust Network|" | \
		sed "s|Example Inc\.|VeriSign, Inc\.|" | sed "s|\@example.com|\@verisign.com|" | \
		sed "s|Example Server Certificate|localhost|" | sed "s|= 365|= 730|" > server.cnf.new
cat ca.cnf | sed "s|= FR|= US|" | sed "s|= Radius|= California|" | \
		sed "s|= Somewhere|= VeriSign Trust Network|" | \
		sed "s|Example Inc\.|VeriSign, Inc\.|" | sed "s|\@example.com|\@verisign.com|" | \
		sed "s|Example Server Certificate|localhost|" | sed "s|= 365|= 730|" > ca.cnf.new

cp server.cnf.new server.cnf
cp ca.cnf.new ca.cnf

./bootstrap

sudo cp -r * /usr/local/etc/raddb/certs
cd ../..

echo "Fixing radiusd.conf file..."
RADFILE="/usr/local/etc/raddb/radiusd.conf"

if [ -e $RADFILE ]; then
	cp $RADFILE $RADFILE.bak
	cat $RADFILE | sed 's|\#with_ntdomain_hack = no|with_ntdomain_hack = yes|' > $RADFILE.tmp
	cp $RADFILE.tmp $RADFILE
	rm $RADFILE.tmp
else
	echo "Unable to find $RADFILE."
	echo "Manually change #with_ntdomain_hack = no to"
	echo "with_ntdomain_hack = yes for only the MSCHAP entry."
fi

echo "FreeRadius-WPE Edition installed."
echo "run 'radiusd' and"
echo "tail -f /usr/local/var/log/radius/freeradius-server-wpe.log"
echo "for details and keys."





m


