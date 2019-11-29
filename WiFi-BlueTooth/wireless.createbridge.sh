#!/bin/sh

ShowUsage() {
	echo "Usage: $0 [--bridgeip=<ip address>] [--wireless-if=<wireless interface>] [--wired-if=<ethernet interface>] [--help]"
	echo ""
	echo "--bridgeip=    IP address to use for the bridge.  Default is 10.0.0.1"
	echo "--wireless-if= Wireless adapter to use.  Default is ath0"
	echo "--wired-if=    Ethernet adapter to bridge to.  Default is eth0"
	echo ""
	echo "Notes/Sequence:"
	echo "1.  wireless.setcardmode.sh should be used first to set the card in AP mode with the"
	echo "appropriate ESSID."
	echo "2.  Run this script to create the bridge."
	echo "3.  hostapd should be run last."
	echo ""
	echo "If a bridge is created, no DHCP service would be required.  However"
	echo "additional IP parameters like netmask, default gateway, and DNS (in /etc/resolv.conf)"
	echo "may need to be configured."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BRIDGEIP="10.0.0.1"
ATH_INTERFACE="ath0"
ETH_INTERFACE="eth0"

for i in $*
do
	case $i in
    	--bridgeip=*)
		BRIDGEIP=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--wireless-if=*)
		ATH_INTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--wired-if=*)
		ETH_INTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

iwpriv $ATH_INTERFACE mode 3
brctl addbr br0
brctl addif br0 $ETH_INTERFACE
brctl addif br0 $ATH_INTERFACE
brctl setfd br0 1
ifconfig $ATH_INTERFACE up
ifconfig $ETH_INTERFACE up
ifconfig br0 $BRIDGEIP up

# Then run hostapd

