#!/bin/bash

if [ ! -e freeradius-server-2.1.12.tar.gz ]; then
	echo "ERROR: Unable to find freeradius-server-2.1.12.tar.gz"

	exit 1
fi

if [ ! -e freeradius-wpe-2.1.12.patch ]; then
	echo "ERROR: Unable to find wpe patch."

	exit 2
fi

if [ ! -e freeradius-server-2.1.12.tar.gz ]; then
	echo "ERROR: Unable to find freeradius-server-2.1.12.tar.gz"
	exit 3
fi

tar -zxvf freeradius-server-2.1.12.tar.gz
cp freeradius-wpe-2.1.12.patch freeradius-server-2.1.12/
cd freeradius-server-2.1.12
patch -p1 < ../freeradius-wpe-2.1.12.patch
./configure
make
make install

if [ ! -e /usr/local/sbin/radiusd ]; then
	echo "ERROR: Unable to find /usr/local/sbin/radiusd.  Something may have failed during build."
	exit 2
fi

ln -s /usr/local/sbin/radiusd /usr/bin/radiusd
ln -s /usr/local/lib/libfreeradius-eap-2.1.12.so /usr/lib/libfreeradius-eap-2.1.12.so
ln -s /usr/local/lib/libfreeradius-radius-2.1.12.so /usr/lib/libfreeradius-radius-2.1.12.so
ln -s /usr/local/lib/libltdl.so.3 /usr/lib/libltdl.so.3
ln -s /usr/local/lib/libltdl.so /usr/lib/libltdl.so

echo "Fixing radiusd.conf file..."
RADFILE="/usr/local/etc/raddb/radiusd.conf"

if [ -e $RADFILE ]; then
	sed -i 's|\#\twith_ntdomain_hack = no|\twith_ntdomain_hack = yes|' $RADFILE
	sed -i 's|\#\twith_ntdomain_hack = no|\twith_ntdomain_hack = yes|' /usr/local/etc/raddb/modules/mschap

else
	echo "Unable to find $RADFILE."
	echo "Manually change #with_ntdomain_hack = no to"
	echo "with_ntdomain_hack = yes for only the MSCHAP entry."
fi

echo "FreeRadius-WPE Edition installed."
echo "run 'radiusd' and"
echo "tail -f /usr/local/var/log/radius/freeradius-server-wpe.log"
echo "for details and keys."

