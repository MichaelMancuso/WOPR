#!/bin/sh

ShowUsage() {
	echo "Usage: $0 <dns domain name> [DNS Server] [--interface=<interface>]"
	echo "If a DNS Server to provide is not specified, the local 10.0.0.1"
	echo "address is provided in the lease."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ "$1" = "--help" ]; then
	ShowUsage
	exit 1
fi


if [ ! -e /etc/dhcp3/dhcpd.conf ]; then
	echo "can't find /etc/dhcp3/dhcpd.conf.  DHCP may not be installed."
	echo "use 'sudo apt-get -y install dhcp3-server' to configure."
	echo "then 'update-rc.d -f dhcp3-server remove' to prevent auto-start."
	exit 2
fi

# configure wireless interface
WIRELESSINTERFACE=`iwconfig 2> /dev/null | grep -B 1 "Mode:Managed" | head -1 | grep -Eo "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||g"`
# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Master" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ $# -gt 2 ]; then
	INTERFACE=`echo $3 | sed 's/[-a-zA-Z0-9]*=//'`
else
	INTERFACE="at0"
fi

if [ ${#MONINTERFACE} -eq 0 ]; then
	# See if we have a MASTER mode interface
	MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`
fi

if [ "$INTERFACE" = "at0" ]; then
	ifconfig at0 > /dev/null

	if [ $? -gt 0 ]; then
		INTERFACE=$MONINTERFACE
	fi
fi

if [ ${#MONINTERFACE} -gt 0 ]; then
	echo "Configuring dhcp for 10.0.0.0/24 on wireless adapter..."
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
	echo "ERROR: No wireless monitor mode interface found."
fi


