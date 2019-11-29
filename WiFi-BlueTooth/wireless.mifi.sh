#!/bin/sh

StartOpenOrWEP() {
# $1 = SSID
# $2 = Channel
# $3 = WEP Key (Can be empty for Open AP)

	# Grab first interface
	ATH_INTERFACE=`ifconfig -a | grep -o --max-count=1 -e "^ath[0-9]" -e "^wlan[0-9]"`

	if [ ${#ATH_INTERFACE} -gt 0 ]; then
		SSID=$1
		CHANNEL=$2
		WEPKEY=$3
		wireless.setcardmode.sh --mode=monitor --interface=$ATH_INTERFACE --ssid=$SSID --channel=$CHANNEL
		
		if [ ${#WEPKEY} -gt 0 ]; then
			echo "Enabling wireless access point for SSID $SSID with WEP key $WEPKEY..."
			wireless.fake_ap.sh $SSID $CHANNEL "$WEPKEY" &
		else
			echo "Enabling wireless Open access point for SSID $SSID..."

			wireless.fake_ap.sh $SSID $CHANNEL &
		fi
	else
		echo "Unable to find wireless interface ath[0-9] or wlan[0-9]."
		exit 3
	fi

	sleep 5

	NUMPROC=`ps -A | grep "airbase-ng" | wc -l`

	if [ $NUMPROC -gt 0 ]; then
		# Get current dns server:
		DNSSERVER=`cat /etc/resolv.conf | grep --max-count=1 "nameserver" | sed "s|nameserver||" | sed "s| ||g"`

		echo "Starting DHCP service..."
		wireless.dhcp.setup.sh mobile.phn.private $DNSSERVER &

		echo "Enabling Network Address Translation..."
		PPPADAPTER=`ifconfig | grep -Eio --max-count=1 "^ppp[0-9]" | tail -1`
		ipforwarding.sh --enable-forwarding --interface=$PPPADAPTER
	else
		echo "Unable to start Access point."
		exit 3
	fi

	echo ""
}

StartHostapd() {
	if [ -d /etc/hostapd ]; then
		if [ -e /etc/hostapd/mifi.conf ]; then

			ATH_INTERFACE=`cat /etc/hostapd/mifi.conf | grep "^interface=" | sed "s|interface=||"`

			ifconfig -a | grep "^$ATH_INTERFACE" > /dev/null

			if [ $? -eq 0 ]; then
				SSID=`cat /etc/hostapd/mifi.conf | grep -i "^ssid=" | sed "s|ssid=||"`
				CHANNEL=`cat /etc/hostapd/mifi.conf | grep -i "^channel=" | sed "s|channel=||"`
				echo "Enabling wireless access point..."
				wireless.setcardmode.sh --mode=ap --interface=$ATH_INTERFACE --ssid=$SSID --channel=$CHANNEL
				hostapd /etc/hostapd/mifi.conf&
			else
				echo "Unable to find wireless interface $ATH_INTERFACE."
				exit 3
			fi
		fi
	fi

	sleep 5

	NUMPROC=`ps -A | grep "hostapd" | wc -l`

	if [ $NUMPROC -gt 0 ]; then
		# Get current dns server:
		DNSSERVER=`cat /etc/resolv.conf | grep --max-count=1 "nameserver" | sed "s|nameserver||" | sed "s| ||g"`

		echo "Starting DHCP service..."
		wireless.dhcp.setup.sh mobile.phn.private $DNSSERVER &

		echo "Enabling Network Address Translation..."
		PPPADAPTER=`ifconfig | grep -Eio --max-count=1 "^ppp[0-9]" | tail -1`
		ipforwarding.sh --enable-forwarding --interface=$PPPADAPTER
	else
		echo "Unable to start Access point."
		exit 3
	fi
}

EnableMiFi() {
# $1 = wpa-psk, wep, or open
# $2 = Channel to use

	SSID="PH6MOBILE"
	MODE=$1
	CHANNEL=$2
	WEPKEY="01:98:02:76:34"

	CURDIR=`pwd`
	cd /usr/local/share/bbteather

	echo "Enabling blackberry tether..."
	python bbtether.py att &

	sleep 10

	cd $CURDIR

	ifconfig | grep -i "^ppp" > /dev/null

	if [ $? -gt 0 ]; then
		echo "Unable to find successful connection.  Please check teather."
		exit 3
	fi
	

	case $MODE in
	wpa-psk)
		StartHostapd
	;;
	wep)
		StartOpenOrWEP $SSID $CHANNEL $WEPKEY
	;;
	open)
		StartOpenOrWEP $SSID $CHANNEL ""
	;;
	esac

	echo "mifi up and running."
}

DisableMiFi() {
	# Determine if we're running hostapd or airbase-ng
	PROC=`ps -A | grep "hostapd" | wc -l`

	ROUTINGADAPTER=""
	WIRELESSADAPTER=""

	if [ $PROC -gt 0 ]; then
		# Running hostapd
		PROC=`ps -A | grep "hostapd" | grep -Eio --max-count=1 "^.[0-9]{2,5}" | sed "s| ||g"`

		kill $PROC

		ROUTINGADAPTER=`ifconfig | grep -Eio --max-count=1 "^ppp[0-9]" | tail -1`
		WIRELESSADAPTER=`iwconfig 2> /dev/null | grep -B 1 "Mode:Master" | grep -Eio --max-count=1 "^ath[0-9]"`
	else
		# look for airbase-ng
		ROUTINGADAPTER=`ifconfig -a | grep -o --max-count=1 "^ath[0-9]"`
		WIRELESSADAPTER=`iwconfig 2> /dev/null | grep -B 1 "Mode:Monitor" | grep -Eio --max-count=1 "^ath[0-9]"`

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

	echo "Terminating tether..."
	PROC=`ps -A | grep "python" | wc -l`

	if [ $PROC -gt 0 ]; then
		# Running hostapd
		PROC=`ps -A | grep "python" | grep -Eio "^.[0-9]{2,5}" | sed "s| ||g"`

		for CURPROC in $PROC
		do
			# Don't just terminate.  The modem will stil be enabled.
			# Send an interrupt (CTL-C) kill message to the app and
			# it will controlled shutdown.
			kill -s 15 $CURPROC
		done

		sleep 20
	fi

	# Check that all shut down gracefully
	PROC=`ps -A | grep "python" | wc -l`

	if [ $PROC -gt 0 ]; then
		echo "Some processes did not shut down.  Please user berry4all to reset"
		echo "the modem.  Killing processes..."
		# Running hostapd
		PROC=`ps -A | grep "python" | grep -Eio "^.[0-9]{2,5}" | sed "s| ||g"`

		for CURPROC in $PROC
		do
			# Hard kill
			kill $CURPROC
		done
	fi
}

ShowUsage() {
	echo ""
	echo "Usage: $0 [--help] [--enable | --disable] [--mode=<wpa-psk | wep | open] [--channel=<channel>] --nocheck"
	echo ""
	echo "$0 will configure the system to run as a 'mifi' hotspot"
	echo "The blackberry connection will be established and all"
	echo "inbound traffic on other network adapters will be NATd"
	echo "out the dial-up interface."
	echo ""
	echo "--enable  Start mifi mode (default if not specified)"
	echo "--mode    Specify if the AP should be in open, wep, or"
	echo "          wpa-psk mode (wpa-psk controlled thru /etc/hostapd/mifi.conf."
	echo "          Default is WEP."
	echo "--channel If in open or wep mode, a channel should be specified."
	echo "          Default is 11.  In wpa-psk mode, the channel is read from the"
	echo "          mifi.conf file."
	echo "--nocheck The default behavior is to heck that a Blackberry is connected"
	echo "          before continuing.  In some cases, it's possible that lsusb"
	echo "          would not list the device.  If that's the case use --nocheck"
	echo "          to disable checking."
	echo ""
	echo "--disable Shut down mifi mode"

	echo "If an /etc/hostapd/mifi.conf file exists and a wireless"
	echo "ath0 adapter is present, a wireless AP will also be established."
	echo "Note this can be disabled with the --no-ap parameter."
	echo ""
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

CHECKBB=1
CREATEAP=1
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
	--no-ap)
		CREATEAP=0
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
	--nocheck)
		CHECKBB=0
	;;
	esac
done

if [ $CHECKBB -eq 1 ]; then
	BBPRESENT=`lsusb | grep "Research In Motion" | wc -l`

	if [ $BBPRESENT -eq 0 ]; then
	   echo "Unable to find Research in Motion in lsusb list."
	   exit 2
	fi
fi

if [ $ENABLE -eq 1 ]; then
	FORWARDINGSTATUS=`ipforwarding.sh --status | grep -Eio "= [0-1]" | sed "s|= ||"`

	if [ $FORWARDINGSTATUS -eq 1 ]; then
		echo "ERROR: NAT already appears to be enabled."
		echo "Please disable with ipforwarding.sh first."
		exit 3
	fi

	EnableMiFi $MODE $CHANNEL
else
	DisableMiFi
fi


