#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 <ssid> <channel> [WEP Key] [--hide] [--all] [--ad-hoc]"
	echo "If a WEP key is provided, the AP is switched to WEP mode."
	echo "The key may be a stream of digits 1234567890 or be separated"
	echo "by colons: 01:23:45:67:89."
	echo "40-bit WEP is 10 characters, 104-bit is 26 characters."
	echo ""
	echo "--hide     Do not broadcast SSID (default is broadcast)"
	echo "--all      Echo all seen probes (default is only specified SSID)"
	echo "--ad-hoc   act as an ad-hoc client rather than an AP"
	echo ""
	exit 1
fi

SSID=`echo "$1" | sed "s|^ *||" | sed "s| *$||"`
CHANNEL=`echo "$2" | grep -Eo "[0-9]{1,2}"`

if [ $# -gt 2 ]; then
	WEPKEY=$3
else
	WEPKEY=""
fi

HIDE=""
ECHOALL=""
ADHOC=""

for i in $*
do
	case $i in
		--hide)
			# Do not broadcast OR respond to non SSID probes
			HIDE="--hidden -y"
		;;
		--all)
			ECHOALL="-P"
		;;
		--ad-hoc)
			ADHOC="--ad-hoc"
		;;
	esac
done

# MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||"`
MONINTERFACE=`iwconfig 2> /dev/null | grep  -B 1 "Mode:Monitor" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

if [ ${#MONINTERFACE} -gt 0 ]; then

	# Get current mac address to make sure it doesn't change it...
	MACADDRESS=`ifconfig -a | grep "^$MONINTERFACE" | grep -Pio " [A-Fa-f0-9]{2,2}-[A-Fa-f0-9]{2,2}-[A-Fa-f0-9]{2,2}-[A-Fa-f0-9]{2,2}-[A-Fa-f0-9]{2,2}-[A-Fa-f0-9]{2,2}" | sed "s| ||"`

	if [ ${#WEPKEY} -gt 0 ]; then
		echo "Creating access point for SSID: $SSID on channel $CHANNEL using $MONINTERFACE..."
		echo "Enabling WEP with key $3"
#		airbase-ng -e "$SSID" -c $CHANNEL -W 1 -w $WEPKEY -a $MACADDRESS $HIDE $ECHOALL $ADHOC $MONINTERFACE
		airbase-ng -e "$SSID" -c $CHANNEL -W 1 -w $WEPKEY $HIDE $ECHOALL $ADHOC $MONINTERFACE
	else
		echo "Creating open access point for SSID: $SSID on channel $CHANNEL using $MONINTERFACE..."
#		airbase-ng -e "$SSID" -c $CHANNEL -a $MACADDRESS $HIDE $ECHOALL $ADHOC $MONINTERFACE
		airbase-ng -e "$SSID" -c $CHANNEL $HIDE $ECHOALL $ADHOC $MONINTERFACE
	fi
else
	echo "ERROR: No monitoring interface configured."
fi

