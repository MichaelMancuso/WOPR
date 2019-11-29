#!/bin/bash

if [ ! -e Nessus*.deb ]; then
	echo "ERROR: Unable to find local Nessus package.  Download from http://www.tenable.com/products/nessus/select-your-operating-system and try again."
	exit 1
fi

dpkg -i Nessus*.deb
if [ -e /etc/init.d/nessusd ]; then
	# Note that this is only required for an immediate start.  It does add it in the rc.d paths
	
	/etc/init.d/nessusd start
	
	echo "Nessus started.  Go to https://127.0.0.1:8834/ to connect."
else
	echo "ERROR: Unable to find /etc/init.d/nessusd.  A problem may have occurred during installation."
	exit 2
fi
