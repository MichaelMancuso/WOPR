#!/bin/sh
dpkg --force-architecture --install freeradius-server-wpe_2.1.11-1_i386.deb

ldconfig

echo "Building certificates..."
cd /usr/local/etc/raddb/certs

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

