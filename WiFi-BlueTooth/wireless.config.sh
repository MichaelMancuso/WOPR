#!/bin/sh

if [ $# -lt 3 ]; then
	echo "Usage $0 <--wpa | --wpa2 | --wep> <ssid> <wep key | wpa-psk>"
	echo "Where --wpa specifies use wpa-psk"
	echo "      --wpa2 specifies wpa2-psk"
	echo "      --wep specifies static wep (using key 1)"
	echo "<ssid>  Network SSID"
	echo "<wep key | wpa-psk>  For wep, specify key (eg. 01:02:03:04:05)"
	echo "                     for wep text keys, precede key with s:"
	echo "                     for wpa/2 provide pre-shared key / password."
	exit 1
fi

# 0=WEP, 1=WPA, 2=WPA2
MODE=0
SSID=$2
KEY=$3

case $1 in
--wep)
	MODE=0
	KEY=`echo $KEY | sed "s|:||g"`
;;
--wpa)
	MODE=1
;;
--wpa2)
	MODE=2
;;
esac

WIRELESSINTERFACE=`iwconfig 2> /dev/null | grep -B 1 "Mode:Managed" | head -1 | grep -Eo "^.*?IEEE" | sed "s|\sIEEE||" | sed "s|\s||g"`

if [ ${#WIRELESSINTERFACE} -gt 0 ]; then
	echo "Configuring $WIRELESSINTERFACE..."

	case $MODE in
	0)
		iwconfig $WIRELESSINTERFACE mode managed key $KEY
		iwconfig $WIRELESSINTERFACE essid "$SSID" 
#		iwconfig $WIRELESSINTERFACE channel auto

#		dhclient $WIRELESSINTERFACE
	;;
	1)
		echo "Not supported yet."
	;;
	2)
		echo "Not supported yet."
	;;
	esac
else
	echo "ERROR: No wireless interface found."
fi

