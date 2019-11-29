#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <dns domain name> [DNS Server] [--interface=<interface>]"
	echo "If a DNS Server to provide is not specified, the local 10.0.0.1"
	echo "address is provided in the lease."
	echo "if interface is not specified, eth0 is used."
	exit 1
fi

if [ ! -e /etc/dhcp3/dhcpd.conf ]; then
	echo "can't find /etc/dhcp3/dhcpd.conf.  DHCP may not be installed."

	exit 2
fi

if [ $# -gt 2 ]; then
	INTERFACE=`echo $3 | sed 's/[-a-zA-Z0-9]*=//'`
else
	INTERFACE="eth0"
fi

if [ "$INTERFACE" == "at0" ]; then
	ifconfig at0 > /dev/null

	if [ $? -gt 0 ]; then
		echo "Unable to find wirelss TAP interface (at0)."
		echo "Please confirm fake_ap.sh is running."

		exit 3
	fi
fi

ifconfig -a | grep "^$INTERFACE" > /dev/null

if [ $? -eq 0 ]; then
	echo "Configuring dhcp for 10.0.0.0/24 on $INTERFACE..."
	if [ ! -e /etc/dhcp3/dhcpd.conf.bak ]; then
		cp /etc/dhcp3/dhcpd.conf /etc/dhcp3/dhcpd.conf.bak
	fi

	DOMAIN=`echo "$1" | sed "s|\.|\\\.|g"`

	cat /etc/dhcp3/dhcpd.conf.bak | sed "s|example\.org|$DOMAIN|g" | sed "s|^option domain-name-servers|# option domain-name-servers|" | sed "s|^#authoritative;|authoritative;|" > /etc/dhcp3/dhcpd.conf.new

	echo "subnet 10.0.0.0 netmask 255.255.255.0 {" >> /etc/dhcp3/dhcpd.conf.new
	echo "  range 10.0.0.21 10.0.0.200;" >> /etc/dhcp3/dhcpd.conf.new
	
	if [ $# -gt 1 ]; then
		echo "Providing DNS Server: $2"
		echo "  option domain-name-servers $2;" >> /etc/dhcp3/dhcpd.conf.new
	else
		echo "Providing DNS Server: 10.0.0.1"
		echo "  option domain-name-servers 10.0.0.1;" >> /etc/dhcp3/dhcpd.conf.new
	fi

	echo "  option domain-name \"$1\";" >> /etc/dhcp3/dhcpd.conf.new
	echo "  option routers 10.0.0.1;" >> /etc/dhcp3/dhcpd.conf.new
	echo "}" >> /etc/dhcp3/dhcpd.conf.new

	cp /etc/dhcp3/dhcpd.conf.new /etc/dhcp3/dhcpd.conf

	echo "Setting up $INTERFACE as 10.0.0.1/24..."

	ifconfig $INTERFACE up 10.0.0.1 netmask 255.255.255.0

	# start dhcpd in daemon mode.  Note that at0 is a wireless TAP interface
	# that is created by the fake_ap.sh script
	rm -f ./dhcpd.pid > /dev/null
#	dhcpd3 at0
	dhcpd3 -f -pf ./dhcpd.pid $INTERFACE
else
	echo "ERROR: Unable to find interface $INTERFACE."
fi


