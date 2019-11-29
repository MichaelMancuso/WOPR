#!/bin/sh

StartOpenOrWEP() {
# $1 = SSID
# $2 = Channel
# $3 = WEP Key (Can be empty for Open AP)
# $4 = LocalDNS

	# Grab first interface
	ATH_INTERFACE=`ifconfig -a | grep -o --max-count=1 -e "^ath[0-9]" -e "wlan[0-9]"`
	LOCALDNS=$4

	if [ ${#ATH_INTERFACE} -gt 0 ]; then
		SSID=$1
		CHANNEL=$2
		WEPKEY=$3

		wireless.setcardmode.sh --mode=monitor --interface=$ATH_INTERFACE --ssid=$SSID --channel=$CHANNEL
		
		if [ ${#WEPKEY} -gt 0 ]; then
			echo "Enabling wireless access point for SSID $SSID with WEP key $WEPKEY..."
			wireless.fake_ap.sh $SSID $CHANNEL $WEPKEY &
		else
			echo "Enabling wireless Open access point for SSID $SSID..."

			wireless.fake_ap.sh $SSID $CHANNEL &
		fi
	else
		echo "Unable to find wireless interface."
		exit 3
	fi

	sleep 5

	NUMPROC=`ps -A | grep "airbase-ng" | wc -l`

	if [ $NUMPROC -gt 0 ]; then
		# Get current dns server:
		
		echo "Starting DHCP service..."

		if [ $LOCALDNS -eq 1 ]; then
			wireless.dhcp.setup.sh mobile.local &

			sleep 2

			dnsspoof -i at0 &
		else
			DNSSERVER=`cat /etc/resolv.conf | grep --max-count=1 "nameserver" | sed "s|nameserver||" | sed "s| ||g"`

			wireless.dhcp.setup.sh mobile.local $DNSSERVER &
		fi

		echo "Enabling Network Address Translation..."
		ETHADAPTER=`ifconfig | grep -Eio --max-count=1 "^eth[0-9]" | head -1`
		ipforwarding.sh --enable-forwarding --interface=$ETHADAPTER
	else
		echo "Unable to start Access point."
		exit 3
	fi

	echo ""
}

StartHostapd() {
# $1 = Config file
# $2 = LOCALDNS

	HOSTAPDCONF=$1
	LOCALDNS=$2

	if [ -e $HOSTAPDCONF ]; then

		ATH_IN_CONFIG=`cat $HOSTAPDCONF | grep "^interface=" | sed "s|interface=||"`
		ATH_INTERFACE=`iwconfig 2>/dev/nul | grep -Eio -e "^ath[0-9]" -e "wlan0"`

		SSID=`cat $HOSTAPDCONF | grep -i "^ssid=" | sed "s|ssid=||"`
		CHANNEL=`cat $HOSTAPDCONF | grep -i "^channel=" | sed "s|channel=||"`

		echo "Enabling wireless access point..."
#		wireless.setcardmode.sh --mode=ap --interface=$ATH_INTERFACE --ssid=$SSID --channel=$CHANNEL

		# This recheck will account for a card number rotation when running from a USB stick
		ATH_INTERFACE_NOW=`iwconfig 2>/dev/nul | grep -Eio -e "^ath[0-9]" -e "wlan[0-9]"`

		cat $HOSTAPDCONF | grep "^interface=$ATH_INTERFACE_NOW" > /dev/null

		if [ $? -eq 0 ]; then
			cat $HOSTAPDCONF | sed "s|^channel=[0-9]{1,3}|channel=$CHANNEL|"  | sed "s|^ssid=.*$|ssid=$SSID|" > $HOSTAPDCONF.tmp
		else
			cat $HOSTAPDCONF | sed "s|^channel=[0-9]{1,3}|channel=$CHANNEL|" | sed "s|^ssid=.*$|ssid=$SSID|" | sed "s|^interface=ath[0-9]|interface=$ATH_INTERFACE_NOW|" > $HOSTAPDCONF.tmp
			ATH_INTERFACE=$ATH_INTERFACE_NOW
		fi

		hostapd $HOSTAPDCONF.tmp &
	fi

	sleep 5

	NUMPROC=`ps -A | grep "hostapd" | wc -l`

	if [ $NUMPROC -gt 0 ]; then
		# Get current dns server:
		echo "Setting $ATH_INTERFACE IP address to 10.0.0.1..."
		ifconfig $ATH_INTERFACE 10.0.0.1 netmask 255.255.255.0

		echo "Starting DHCP service..."

		if [ $LOCALDNS -eq 1 ]; then
			wireless.dhcp.setup.sh mobile.local 10.0.0.1 --interface=$ATH_INTERFACE&

			sleep 2

			dnsspoof -i $ATH_INTERFACE &
		else
			DNSSERVER=`cat /etc/resolv.conf | grep --max-count=1 "nameserver" | sed "s|nameserver||" | sed "s| ||g"`

			wireless.dhcp.setup.sh mobile.local $DNSSERVER --interface=$ATH_INTERFACE&
		fi

		echo "Enabling Network Address Translation..."
		ETHADAPTER=`ifconfig | grep -Eio --max-count=1 "^eth[0-9]" | head -1`
		ipforwarding.sh --enable-forwarding --interface=$ETHADAPTER
	else
		echo "Unable to start Access point."
		exit 3
	fi
}

EnableMiFi() {
# $1 = wpa-psk, wep, or open
# $2 = Channel to use
# $3 = SSID
# $4 = HOSTAPDCONF
# $5 = WEPKEY
# $6 = LOCALDNS

	SSID=$3
	MODE=$1
	CHANNEL=$2
	HOSTAPDCONF=$4
	
	WEPKEY=$5
	LOCALDNS=$6

	CURDIR=`pwd`

	ifconfig | grep -i -A 1 "^eth" | grep -i "inet addr" > /dev/null

	if [ $? -gt 0 ]; then
		echo "Unable to find active ethernet connection.  Please check connectivity. (Continuing...)"
#		exit 3
	fi
	

	case $MODE in
	wpa|wpa-psk)
		StartHostapd $HOSTAPDCONF $LOCALDNS
	;;
	wep)
		StartOpenOrWEP $SSID $CHANNEL $WEPKEY $LOCALDNS
	;;
	open)
		StartOpenOrWEP $SSID $CHANNEL "" $LOCALDNS
	;;
	esac

	echo "AP is up and running."
}

DisableMiFi() {
	# check if dnsspoof is running
	PROC=`ps -A | grep "dnsspoof" | wc -l`

	if [ $PROC -gt 0 ]; then
		# Running dnsspoof
		PROC=`ps -A | grep "dnsspoof" | grep -Eio --max-count=1 "^.[0-9]{2,5}" | sed "s| ||g"`

		if [ ${#PROC} -gt 0 ]; then
			kill $PROC
		fi
	fi

	ROUTINGADAPTER=""
	WIRELESSADAPTER=""

	# Determine if we're running hostapd or airbase-ng
	PROC=`ps -A | grep "hostapd" | wc -l`
	if [ $PROC -gt 0 ]; then
		# Running hostapd
		PROC=`ps -A | grep "hostapd" | grep -Eio --max-count=1 "^.[0-9]{2,5}" | sed "s| ||g"`

		kill $PROC

		ROUTINGADAPTER=`ifconfig | grep -Eio --max-count=1 "^eth[0-9]" | head -1`
		WIRELESSADAPTER=`iwconfig 2> /dev/null | grep -B 1 "Mode:Master" | grep -Eio --max-count=1 -e "^ath[0-9]" -e "wlan[0-9]"`
	else
		# look for airbase-ng
		ROUTINGADAPTER=`ifconfig -a | grep -o --max-count=1 -e "^ath[0-9]" -e "wlan[0-9]"`
		WIRELESSADAPTER=`iwconfig 2> /dev/null | grep -B 1 "Mode:Monitor" | grep -Eio --max-count=1 -e "^ath[0-9]" -e "wlan[0-9]"`

		PROC=`ps -A | grep "airbase-ng" | wc -l`

		if [ $PROC -gt 0 ]; then
			# Running hostapd
			PROC=`ps -A | grep "airbase-ng" | grep -Eio --max-count=1 "^.[0-9]{2,5}" | sed "s| ||g"`

			kill $PROC
		else
			echo "Unable to find running access point process.  Continuing to shut down..."
		fi
	fi

	echo "Disabling Network Address Translation..."
	/usr/bin/ipforwarding.sh --disable-forwarding --interface=$ROUTINGADAPTER
	/usr/bin/ipforwarding.sh --disable-forwarding

	FORWARDINGSTATUS=`ipforwarding.sh --status | grep -Eio "= [0-1]" | sed "s|= ||"`

	if [ $FORWARDINGSTATUS -eq 1 ]; then
		echo "ERROR: Unable to disable forwarding to $ROUTINGADAPTER"
		exit 3
	fi

	echo "Disabling DHCP..."
	PROC=`ps -A | grep "dhcpd3" | wc -l`

	if [ $PROC -gt 0 ]; then
		# Running dhcp
		PROC=`ps -A | grep "dhcpd3" | grep -Eio --max-count=1 "^.[0-9]{2,5}" | sed "s| ||g"`

		kill $PROC
	else
		echo "Unable to find running dhcp process.  Continuing to shut down..."
	fi

	echo "Returning wireless to normal operations..."
	wireless.setcardmode.sh --mode=Managed --interface=$WIRELESSADAPTER

}

ShowUsage() {
	echo ""
	echo "Usage: $0 [--help] [--enable | --disable] [--mode=<wpa | wep | open] [--channel=<channel>]"
	echo "[--ssid=<ssid>] [--wepkey=<key>] [--hostapd=<conf>] [--dnslocal]"
	echo ""
	echo "$0 will configure the system to run as a wireless Access Point"
	echo "with the specified encryption and settings, and will take all"
	echo "inbound traffic and NAT it out the connected Ethernet interface."
	echo "For Open or WEP, airbase is used, for for WPA, hostapd and the "
	echo "specified config file is used. (note hostapd settings could specify"
	echo "anything.)"
	echo ""
	echo "--enable  Start wifi mode (default if not specified)"
	echo "--mode    Specify if the AP should be in open, wep, or"
	echo "          wpa-psk mode (wpa-psk controlled thru /etc/hostapd/mifi.conf."
	echo "          Default is WEP."
	echo "--channel If in open or wep mode, a channel should be specified."
	echo "          Default is 11.  In wpa-psk mode, the channel is read from the"
	echo "          specified /etc/hostapd/<config>.conf file."
	echo "--ssid    Specifies the SSID for Open or WEP mode (for WPA mode settings"
	echo "          are read from the specified hostapd conf file)"
	echo "--wepkey  If WEP mode is specified a key needs to be provided."
	echo "          40-bit WEP is 10 characters, 104-bit is 26 characters."
	echo "--hostapd=<conf>  If the mode is wpa and a hostapd config file is specified"
	echo "          all other settings are read from there."
	echo "--dnslocal Default DHCP DNS settings are do use the DNS server in the current"
	echo "           resolv.conf.  Specifying --dnslocal will change the provided "
	echo "           DNS server to the AP IP 10.0.0.1.  This is useful when using fakedns"
	echo "           attacks and/or Karmetasploit."
	echo ""
	echo "--disable Shut down wifi mode"
	echo ""
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

CREATEAP=1
ENABLE=1
CHANNEL=11
mode="wep"
HOSTAPDCONF=""
SSID=""
WEPKEY=""
LOCALDNS=0

for i in $*
do
	case $i in
	--dnslocal)
		LOCALDNS=1
	;;
	--help)
		ShowUsage
		exit 1
	;;
	--enable)
		ENABLE=1
	;;
	--disable)
		ENABLE=0
	;;
	--channel=*)
		CHANNEL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--mode=*)
		mode=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--ssid=*)
		SSID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--wepkey=*)
		WEPKEY=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--hostapd=*)
		HOSTAPDCONF=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	esac
done

if [ $ENABLE -eq 1 ]; then
	FORWARDINGSTATUS=`ipforwarding.sh --status | grep -Eio "= [0-1]" | sed "s|= ||"`

	if [ $FORWARDINGSTATUS -eq 1 ]; then
		echo "IP forwarding appears enabled.  Resetting for AP..."
		ipforwarding.sh --disable-forwarding
	fi

	# Check WEP and WPA param matchup

	case $mode in
	wep)
		if [ ${#WEPKEY} -eq 0 ]; then
			echo "Please specify a WEP key for wep mode."
			exit 3
		fi
	;;
	wpa|wpa-psk)
		mode="wpa"
		if [ ${#HOSTAPDCONF} -eq 0 ]; then
			echo "Please specify a hostapd config file."
			exit 3
		fi

		if [ ! -e $HOSTAPDCONF ]; then
			echo "The specified hostapd config file cannot be found."
			exit 3
		fi
	;;
	esac

	EnableMiFi $mode "$CHANNEL" "$SSID" "$HOSTAPDCONF" "$WEPKEY" "$LOCALDNS"
else
	DisableMiFi
fi


