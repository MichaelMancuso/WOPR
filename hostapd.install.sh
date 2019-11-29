#!/bin/sh

# --------------- Functions -------------------------
CheckInstall() {
	SW_INSTALLED=`aptitude search "$1" | grep "^i" | wc -l`

	if [ $SW_INSTALLED -eq 0 ]; then
		echo "$1 not installed.  Installing..."
		apt-get -y install "$1"

#		Ensure it was installed.
		SW_INSTALLED=`aptitude search "$1" | grep "^i" | wc -l`
	
		if [ $SW_INSTALLED -eq 0 ]; then
			echo "$1 installation failed."
		fi
	else
		echo "$1 already installed..."
	fi
}

apt-get install libssl-dev libnl-3-dev libnl-genl-3-dev
# --------------- Main --------------------------
OSTYPE=`uname`
if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

if [ $ISLINUX -eq 1 ]; then
	# make sure installation is done by root
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root.  Please use sudo $0 to configure."
	   exit 1
	fi
else
	echo "hostapd will not run under windows!"
	exit 1
fi

# Get latest version:
echo "Checking http://hostap.epitest.fi/hostapd/ for latest version information..."
LATESTVERSIONS=`wget -qO- http://hostap.epitest.fi/hostapd/ | grep -Eio ">host.*?\.tar\.gz" | sed "s|>||g"`
LATESTRELEASE=`echo "$LATESTVERSIONS" | head -1`
LATESTDEV=`echo "$LATESTVERSIONS" | tail -1`

wget http://hostap.epitest.fi/releases/$LATESTDEV

if [ -e $LATESTDEV ]; then
	tar -zxvf $LATESTDEV
	HOSTAPDDIR=`echo $LATESTDEV | sed "s|\.tar\.gz||"`
	cd $HOSTAPDDIR/hostapd
	if [ ! -e .config ]; then
		echo "Creating .config file..."
		cat defconfig | sed "s|#CONFIG_DRIVER_MADWIFI=y$|CONFIG_DRIVER_MADWIFI=y\nCFLAGS += -I\/tmp\/madwifi\n|" > .config
	fi

	if [ ! -d /tmp/madwifi ]; then
		echo "Downloading madwifi source..."
		svn checkout http://svn.madwifi-project.org/madwifi/trunk /tmp/madwifi
	fi

	if [ ! -d /etc/hostapd ]; then
		mkdir /etc/hostapd

		cat hostapd.conf | sed "s|^interface=wlan0|interface=ath0|" | sed "s|# driver=hostap|# driver=hostap\ndriver=madwifi|" \
			| sed "s|^hw_mode=.|hw_mode=g|" | sed "s|^channel=60|channel=11|" \
			| sed "s|#supported_rates|supported_rates=540\n#supported_rates|" \
			| sed "s|auth_algs=3|auth_algs=1|" > /etc/hostapd/hostapd.conf
	fi

	echo "Making $HOSTAPDDIR..."

	make

	if [ -e hostapd ]; then
		make install

		cd ../..
	else
		echo "ERROR: Make failed!"
	fi

else
	echo "ERROR: Unable to retrieve http://hostap.epitest.fi/releases/$LATESTDEV"
fi

