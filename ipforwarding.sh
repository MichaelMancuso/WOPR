#!/bin/sh

ShowUsage() {
	echo ""
	echo "$0 controls IP forwarding and nat capabilities between"
	echo "interfaces."
	echo ""
	echo "Options:"
	echo "--status    Show ip forwarding status"
	echo "--enable-forwarding"
	echo "--disable-forwarding"
	echo "--interface=<interface>  Provides outbound interface name.  Default is eth0"
	echo "--source=<source spec>  Can optionally provide source network (e.g. 10.0.0.0/24)"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage

	exit 1
fi

CURSETTING=`sysctl net.ipv4.ip_forward`
CURSETTINGVALUE=`echo "$CURSETTING" | grep -Eo "=.*?$" | sed "s|= ||"`
NEWSTATUS=0
INTERFACE="eth0"
SOURCE=""

for i in $*
do
	case $i in
	--status)
		echo "$CURSETTING"

		exit 0
	;;
	--enable-forwarding)
		NEWSTATUS=1
	;;
	--disable-forwarding)
		NEWSTATUS=0
	;;
	--interface=*)
		INTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--source=*)
		SOURCE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

# Make sure there's a backup copy:

if [ ! -e /etc/sysctl.conf.bak ]; then
	cp /etc/sysctl.conf /etc/sysctl.conf.bak
fi

if [ $CURSETTINGVALUE -ne $NEWSTATUS ]; then
	# Note that this may not save to the file so it won't survive a reboot.

	if [ $NEWSTATUS -eq 1 ]; then
		# enable
		iptables --table nat --flush
		iptables --table nat --delete-chain

		echo "Enabling IP forwarding with NAT to $INTERFACE..."
		iptables -P FORWARD ACCEPT
		
		HASNAT=`iptables -L | grep "Chain nat" | wc -l`

		if [ $HASNAT -eq 0 ]; then
			iptables --new nat
		fi

		if [ ${#SOURCE} -gt 0 ]; then
			iptables --table nat -A POSTROUTING -s $SOURCE -o $INTERFACE -j MASQUERADE
		else
			iptables --table nat -A POSTROUTING -o $INTERFACE -j MASQUERADE
		fi
	else
		# disable
		echo "Disabling IP forwarding with NAT to $INTERFACE..."
		if [ ${#SOURCE} -gt 0 ]; then
			iptables --table nat -D POSTROUTING -s $SOURCE -o $INTERFACE -j MASQUERADE
		else
			iptables --table nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
		fi
	fi

	sysctl -w net.ipv4.ip_forward=$NEWSTATUS > /dev/null
else
	echo "Setting already at $CURSETTINGVALUE."
fi


