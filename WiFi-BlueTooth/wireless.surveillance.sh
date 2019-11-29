#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 [--help] [--disable] [--channel=<channel> (Default=11)] --wpa"
	echo "$0 will create an wireless AP, enable usb cameras, and web server for surveillance."
	echo ""
	echo "--disable            Shut down related services."
	echo "--channel=<channel>  Wireless channel number to use."
	echo "--wpa                Default AP security is WEP with SSID PH6MOBILE and a WEP key of 0198027634."
	echo "                     WPA will create a WPA-PSK AP with an SSID of PH6MOBILE2 and Pass of H3ffalumpWoozel."
	echo "                     Note: WPA can sometimes be tempermental.  Also /etc/hostapd/mifi.conf will"
	echo "                     need to be edited for SSID and channel."
	echo ""
}

ENABLEPARM="--enable"
ENABLE=1
CHANNEL=11
MODE="wep"

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	--enable)
		ENABLEPARM="--enable"
	;;
	--disable)
		ENABLEPARM="--disable"
		ENABLE=0
	;;
	--channel=*)
		CHANNEL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--wpa)
		MODE="wpa"
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

#if [ ! -e /etc/hostapd/mifi.conf ]; then
#	echo "ERROR: Unable to find /etc/hostapd/mifi.conf"
#	exit 2
#fi

if [ $ENABLE -eq 1 ]; then
	echo "Creating access point..."
#	wireless.setcardmode.sh --mode=monitor --channel=$CHANNEL
else
	echo "Stopping access point..."
fi

if [ "$MODE" = "wpa" ]; then
	echo "Creating WPA access point..."
	wireless.wifi.sh $ENABLEPARM --channel=$CHANNEL --hostapd=/etc/hostapd/mifi.conf --mode=wpa --dnslocal
else
	echo "Creating WEP access point..."
	wireless.wifi.sh $ENABLEPARM --channel=$CHANNEL --mode=wep --wepkey=0198027634 --dnslocal --ssid=PH6MOBILE
fi

if [ $? -eq 0 ]; then
	if [ $ENABLE -eq 1 ]; then
		echo "Starting web server..."
		service apache2 start
	else
		echo "Stopping web server..."
		service apache2 stop
	fi

	if [ $ENABLE -eq 1 ]; then
		echo "Starting usb camera service..."
		start-usbcams
	else
		echo "Stopping usb camera service..."
		stop-usbcams
	fi
else
	ERRMSG=`echo "$ENABLEPARM" | sed "s|--||"`
	echo "ERROR: Could not $ERRMSG wifi status"
	exit 1
fi


