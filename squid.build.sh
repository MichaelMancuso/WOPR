#!/bin/bash

# build squid on debian
cd /tmp
LATESTSQUID=`wget -O - http://www.squid-cache.org/Versions/v3/3.5/ 2>/dev/null | grep -Pio "squid\-3\.5\..*?\.tar\.gz" | head -1`

if [ ${#LATESTSQUID} -eq 0 ]; then
	echo "ERROR: Unable to determine latest tar.gz.  Please check http://www.squid-cache.org/Versions/v3/3.5/"
	exit 1
fi

wget $LATESTSQUID
tar -zxvf squid-3*.gz
cd squid-3*

# From the squid page for debian: http://wiki.squid-cache.org/SquidFaq/CompilingSquid#Do_you_have_pre-compiled_binaries_available.3F

./configure --prefix=/usr --localstatedir=/var --libexecdir=${prefix}/lib/squid --datadir=${prefix}/share/squid --sysconfdir=/etc/squid --with-default-user=proxy --with-logdir=/var/log/squid --with-pidfile=/var/run/squid.pid
make
make install

if [ ! -e /usr/sbin/squid ]; then
	echo "ERROR: Unable to find /usr/sbin/squid."
	exit 1
fi

if [ ! -e /usr/sbin/squid3.bak ]; then
	mv /usr/sbin/squid3 /usr/sbin/squid3.bak
fi

ln -s /usr/sbin/squid /usr/sbin/squid3
NUMPROCS=`ps aux | grep squid3 | grep -v grep | wc -l`

if [ $NUMPROCS -gt 0 ]; then
	/etc/init.d/squid3 restart
fi

