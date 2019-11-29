#!/bin/sh

ShowUsage() {
	echo "$0: Randomly rotate through IP's within a specified range"
	echo "Addresses can be rotated through static IP addresses and a range "
	echo "or by rotating the hardware MAC address and re-querying DHCP"
	echo "For now, this program is meant to rotate within a /24 or smaller address space."
	echo "Notes:"
	echo "You must specify at least one parameter as a safety check to prevent entering"
	echo "rotation mode.  This parameter could by -v or --rotate-ip for basic operations."
	echo " "
	echo "Also note that mac address rotation can cause a DoS.  The last 2 octets "
	echo "of the current mac address are rotated, however if this happens to coincide"
	echo "with another node on the network, it can cause conflicts."
	echo " "
	echo "Usage:"
	echo "--help                     This message."
	echo "-v                         Be verbose."
	echo "--dhcp                     Return system to normal DHCP operations"
	echo "Rotate by changing MAC Address (L2 rotation)"
	echo "--rotate-mac               Use mac rotation for IP changes."
	echo "                           Note: this then ignores all L3 rotation parameters."
	echo "--dhcp-dontrelease         When changing MAC address, do not gracefully release"
	echo "                           the current address.  This can exhaust a DHCP pool."
	echo "                           Default is to release before rotating."
	echo " "
	echo "Rotate by static IP address (L3 rotation) "
	echo "--rotate-ip                Use L3 static IP rotation (default)"
	echo "--networkid=<network>      First three octets of IP address (e.g. 192.168.1)."
	echo "                           Default is current network."
	echo "--startip=<starting addr>  Starting 4th octet for IP rotation.  Default is 1."
	echo "--endingip=<ending addr>   Ending 4th octet for IP rotation.  Default is 254."
	echo "--netmask=<netmask>        Network Mask for IP (e.g. 255.255.255.0).  Default is current mask."
	echo "--gateway=<default gateway>   Default Gateway.  Default is current gateway"
	echo "--domainname=<domain name> Default domain name for this system. Default is current."
	echo "--dnsserver=<dns server>   IP address of DNS server to use.  Default is current."
}

# -------------- Main -------------------

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

if [ $ISLINUX -eq 1 ]; then
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root.  Please use sudo $0 to run."
	   exit 2
	fi
fi

if [ $# -eq 0 ]; then
	ShowUsage

	exit 1
fi

# Set Defaults
RETURNTONORMAL=0
VERBOSE=0
STATICMODE=1
DHCPRELEASE=1

# Parse Parameters
FULLIP=`ifconfig | grep -A 1 "eth[0-9]" | grep -Eio "inet addr:.*? B" | sed "s|inet addr:||" | sed "s|  B||" | grep -Eio --max-count=1 "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
BASEIP=`echo "$FULLIP" | grep -Eio "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

if [ ${#BASEIP} -eq 0 ]; then
	echo "ERROR: Unable to find eth[0-9] ip address."
	echo " "
	ifconfig
	exit 3
fi

STARTIP=1
ENDIP=254
NETMASK=`ifconfig | grep -E -A 1 "eth[0-9]" | grep "Mask:" | sed "s|.*Mask:||"`
if [ ${#NETMASK} -eq 0 ]; then
	if [ $VERBOSE -eq 1 ]; then
		echo "Unable to read current netmask."
	fi

	NETMASK="255.255.255.0"
fi

GATEWAY=`route -n | grep -E "^0\.0\.0\.0" | grep -Eio --max-count=1 "[1-9][0-9]{1,2}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
if [ ${#GATEWAY} -eq 0 ]; then
	if [ $VERBOSE -eq 1 ]; then
		echo "Unable to read routing table devault entry (route -n)."
	fi

	GATEWAY=`echo "$BASEIP.1"`
fi

DOMAINNAME=`cat /etc/resolv.conf | grep "domain" | sed "s|domain ||"`
DNSSERVER=`cat /etc/resolv.conf | grep "nameserver" | sed "s|nameserver ||"`

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	-v)
		VERBOSE=1
	;;
	--dhcp)
	RETURNTONORMAL=1
	;;
	--networkid=*)
		# extra grep ensures the format is just the first 3 octets
		BASEIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | grep -Eio "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	;;
	--startip=*)
		STARTIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--endingip=*)
		ENDIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--netmask=*)
		NETMASK=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--gateway=*)
		GATEWAY=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--domainname=*)
		DOMAINNAME=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--dnsserver=*)
		DNSSERVER=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--rotate-mac)
		STATICMODE=0
	;;
	--dhcp-dontrelease)
		DHCPRELEASE=0
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

if [ $STARTIP -ge $ENDIP ]; then
	echo "ERROR: Starting IP of $STARTIP is greater than or equal to ending IP of $ENDIP"
	exit 3
fi

ACTIVECONFIGFILE="/etc/network/interfaces"
DHCPCONFIGFILE="/etc/network/interfaces.dhcp"
TMPCONFIGFILE="/etc/network/interfaces.tmp"

if [ $VERBOSE -eq 1 ]; then
	echo " "
	echo "Running with the following settings: "

	if [ $STATICMODE -eq 1 ]; then
		echo "Rotation Mode: L3 static IP rotation"
		echo "Base Network Id: $BASEIP"
		echo "Starting IP Range: $BASEIP.$STARTIP"
		echo "Ending IP Range: $BASEIP.$ENDIP"
		echo "Netmask: $NETMASK"
		echo "Default Gateway: $GATEWAY"
		echo "Domain Name: $DOMAINNAME"
		echo "DNS Server: $DNSSERVER"
	else
		echo "Rotation Mode: L2 mac address and DHCP rotation"

		if [ $DHCPRELEASE -eq 1 ]; then
			echo "Gracefully release address first: Yes"
		else
			echo "Gracefully release address first: No"
		fi
	fi

	echo " "
fi

if [ ! -e $DHCPCONFIGFILE ]; then
	# This is the first time this was run.  Back up the interfaces file.
	echo "Backing up existing interface config file..."
	cp $ACTIVECONFIGFILE $DHCPCONFIGFILE

	cp /etc/resolv.conf /etc/resolv.conf.dhcp
fi

if [ $RETURNTONORMAL -eq 1 ]; then
	# Returning to DHCP
	if [ -e $DHCPCONFIGFILE ]; then
		echo "Returning to DHCP operations..."
		cp -f $DHCPCONFIGFILE $ACTIVECONFIGFILE
		cp -f /etc/resolv.conf.dhcp /etc/resolv.conf

		/etc/init.d/networking restart

		dhclient

		ifconfig | grep -A 2 "eth[0-9]"
		exit 0
	else
		echo "ERROR: Unable to locate saved DHCP / standard config file at $DHCPCONFIGFILE"
		exit 2
	fi
fi

if [ $STATICMODE -eq 1 ]; then
	# Continue to rotate address

	# get interface descriptor
	ETH_INT=`ifconfig | grep -Eio --max-count=1 "^eth[0-9]" | sed "s|\r||"`

	IPLIST=`seq $STARTIP $ENDIP | sort --random-sort`

	FOUNDIP=0
	NEWIP=""

	for CURIP in $IPLIST
	do
		if [ $FOUNDIP -eq 0 ]; then
			# Test connectivity
			ping -c 2 $BASEIP.$CURIP > /dev/null

			if [ $? -gt 0 ]; then
				# Ping failed.  Address is available
				NEWIP=$CURIP

				FOUNDIP=1
			fi
		fi
	done

	if [ $FOUNDIP -eq 0 ]; then
		echo "Unable to find a free IP address in the specified range."
		echo "IP configuration not changed."

		exit 4
	fi

	echo "Changing address to $BASEIP.$NEWIP..."

	cp -f $DHCPCONFIGFILE $TMPCONFIGFILE
	echo "auto $ETH_INT" >> $TMPCONFIGFILE
	echo "iface $ETH_INT inet static" >> $TMPCONFIGFILE
	echo "address $BASEIP.$NEWIP" >> $TMPCONFIGFILE
	echo "netmask $NETMASK" >> $TMPCONFIGFILE
	# echo "network $BASEIP.0" >> $TMPCONFIGFILE
	# echo "broadcast $BROADCAST" >> $TMPCONFIGFILE
	echo "gateway $GATEWAY" >> $TMPCONFIGFILE

	cp -f $TMPCONFIGFILE $ACTIVECONFIGFILE
	rm -f $TMPCONFIGFILE

	# rewrite resolv.conf
	echo "domain $DOMAINNAME" > /etc/resolv.conf
	echo "search $DOMAINNAME" >> /etc/resolv.conf
	echo "nameserver $DNSSERVER" >> /etc/resolv.conf

else
	# change mac address

	# Get current address:"
	CURRENTMAC=`ifconfig | grep --max-count=1 "eth[0-9]" | sed "s|.*HWaddr ||"`
	MACBASE=`echo "$CURRENTMAC" | grep -o "^..:..:..:.." `
	# Generate random last two octets:"
	OCTET1=`seq 1 99 | sort --random-sort | head -1`
	OCTET2=`seq 1 99 | sort --random-sort | head -1`

	if [ ${#OCTET1} -eq 1 ]; then
		OCTET1=`echo 0$OCTET1`
	fi

	if [ ${#OCTET2} -eq 1 ]; then
		OCTET1=`echo 0$OCTET2`
	fi

	if [ $VERBOSE -eq 1 ]; then
		echo "Using mac address $MACBASE:$OCTET1:$OCTET2"
	fi


	INTERFACE=`ifconfig | grep -Eio --max-count=1 "^eth[0-9]" | sed "s|\r||"`
	ifconfig $INTERFACE down
	ifconfig $INTERFACE hw ether $MACBASE:$OCTET1:$OCTET2
	ifconfig $INTERFACE up

	if [ $DHCPRELEASE -eq 1 ]; then
		if [ $VERBOSE -eq 1 ]; then
			echo "Releasing current address..."
		fi

		dhclient -r
	fi
fi

echo "Restarting networking..."
/etc/init.d/networking restart


