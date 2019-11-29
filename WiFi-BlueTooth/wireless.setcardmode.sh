#!/bin/sh

ShowUsage() {
	echo "Usage: --mode=<ap | monitor | managed | adhoc> [--interface=<adapter>] [--channel=N] [--ssid=<ssid>] [--help]"
	echo ""
	echo "Note: This utility is meant to directly control "
	echo "an Atheros card's status (e.g. ath0)"
	echo ""
	echo "Modes are:"
	echo "ap   - Master or Access Point mode"
	echo "monitor - Promiscuous monitoring mode"
	echo "managed - Default / Normal mode"
	echo "adhoc   - AdHoc mode."
	echo ""
	echo "--interface= specifies the athX adapter to use.  The default"
	echo "is the first ath[0-9] interface found.  If that's not present it'll use mon[0-9]."
	echo ""
	echo "AP Mode or Ad-Hoc Mode:"
	echo "--ssid=   If the mode is ap, an ssid may be provided."
	echo "--channel=  A channel number can be provided. Default=11"
	echo ""
	echo "Notes: Sometimes if madwifi is in use and ath_pci is not"
	echo "in /etc/modules, issuing modprobe ath_pci can correct it."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

# ATH_INTERFACE="ath0"
ATH_INTERFACE=`iwconfig 2> /dev/null | grep "^ath[0-9]" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`
if [ ${#ATH_INTERFACE} -eq 0 ]; then
ATH_INTERFACE=`iwconfig 2> /dev/null | grep "^wlan[0-9]" | grep -Eio "^[a-z,A-Z,0-9]{3,7}" | sed "s|\sIEEE||" | sed "s|\s||"`

fi

CARDMODE=""
SSID=""
CHANNEL=11

for i in $*
do
	case $i in
    	--mode=*)
		CARDMODE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--interface=*)
		ATH_INTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--ssid=*)
		SSID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--channel=*)
		CHANNEL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

ifconfig -a | grep "$ATH_INTERFACE" > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to find $ATH_INTERFACE." >&2
	exit 2
fi

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

ifconfig $ATH_INTERFACE down

WLANMODE="Managed"
SEARCHSTR="Managed"

case $CARDMODE in
	ap)
		WLANMODE="ap"
		SEARCHSTR="Master"
	;;
	monitor)
		WLANMODE="Monitor"
		SEARCHSTR="Monitor"
	;;

	managed)
		WLANMODE="Managed"
		SEARCHSTR="Managed"
	;;
	adhoc)
		WLANMODE="adhoc"
		SEARCHSTR="Ad-Hoc"
	;;
esac

# wlanconfig will only be present if madwifi is installed.  the mode switch
# will still work on backtrack with certain cards
USEIWCONFIG=0
WLANCFG=`which wlanconfig`

if [ $? -gt 0 ]; then
	WLANCFG=""
	USEIWCONFIG=1
fi

if [ ${#WLANCFG} -gt 0 ]; then
	wlanconfig $ATH_INTERFACE destroy 2>&1 1>/dev/null

	if [ $? -gt 0 ]; then
		USEIWCONFIG=1
	else
		wlanconfig $ATH_INTERFACE create wlandev wifi0 wlanmode $WLANMODE -uniquebssid > /dev/null
	fi
fi

if [ $USEIWCONFIG -eq 1 ]; then
	# for wlan0 bring down interface before switching modes
	iwconfig $ATH_INTERFACE mode $WLANMODE
fi

if [ "$CARDMODE" = "ap" -o "$CARDMODE" = "adhoc" ]; then
	iwconfig $ATH_INTERFACE channel $CHANNEL

	if [ ${#WLANCFG} -gt 0 ]; then
		athchans -i $ATH_INTERFACE $CHANNEL-$CHANNEL
	fi

	if [ ${#SSID} -gt 0 ]; then
		iwconfig $ATH_INTERFACE essid "$SSID"
	fi
else
        if [ ${#WLANCFG} -gt 0 ]; then
		athchans -i $ATH_INTERFACE 1-255
	fi
fi

ifconfig $ATH_INTERFACE up

# Now check that it changed...
NEWSTATUS=`iwconfig 2> /dev/null | grep -A 1 "^$ATH_INTERFACE" | grep -i "Mode:$SEARCHSTR" | wc -l`

if [ $NEWSTATUS -eq 1 ]; then
	echo "$ATH_INTERFACE now in $WLANMODE mode:"
	echo ""
else
	echo "ERROR: unable to put $ATH_INTERFACE in $WLANMODE mode" >&2
	echo "" >&2
fi

ifconfig $ATH_INTERFACE down
ifconfig $ATH_INTERFACE up

iwconfig 2> /dev/null | grep -A 1 "^$ATH_INTERFACE"

