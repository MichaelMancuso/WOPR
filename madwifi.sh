#!/bin/sh
ShowUsage()  {
	echo "$0 - Version 1.0  Written by Mike Piscopo"
	echo "Usage: $0 <enable | disable | status | install [--help] [--leavedir]>"
	echo ""
	echo "--leavedir  [install only] Once the madwifi has been downloaded or unzipped with an install,"
	echo "            do not delete it when done.  Default: leave it if it already existed, else delete."
	echo "--help      This screen"
	echo ""

}

if [ $# -eq 0 ]; then
	ShowUsage

	exit 1
fi

InstallMadwifi() {
	mkdir /tmp/madwifi

	DIREXISTED=0

	CURDIR=`pwd`

	if [ -e madwifi_drivers/madwifi-0.9.4.tar.gz ]; then
		cp madwifi_drivers/madwifi-0.9.4.tar.gz /tmp/madwifi
		pushd /tmp/madwifi
		tar -zxvf madwifi-0.9.4.tar.gz
		mv madwifi-0.9.4 madwifi
	else
		if [ -d madwifi ]; then
			DIREXISTED=1
		fi

		svn checkout http://svn.madwifi-project.org/madwifi/trunk/ madwifi
	fi

	echo "" >> /etc/modprobe.d/blacklist
	cat /etc/modprobe.d/blacklist | grep "blacklist ath" > /dev/null

	if [ $? -gt 0 ]; then
		# not already blacklisted
		echo "#Added to use MadWIFI Drivers" >> /etc/modprobe.d/blacklist
		echo "blacklist ath9k" >> /etc/modprobe.d/blacklist
		echo "blacklist ath5k" >> /etc/modprobe.d/blacklist
	fi

	cd madwifi
	make && make install
	echo ath_pci >> /etc/modules

	cd $CURDIR

	if [ $DIREXISTED -eq 0 -a $1 -eq 0 ]; then
		# If directory didn't exist and --leavedir was not specified, delete
		rm -rf /tmp/madwifi
	fi
}

LEAVEDIR=0

case $1 in
	--leavedir)
		# Used for install
		LEAVEDIR=1
	;;
	enable | disable)
		if [ "$(id -u)" != "0" ]; then
		   echo "This script must be run as root.  Please use sudo $0 to run."
		   exit 2
		fi

		if [ ! -e /etc/modprobe.d/blacklist ]; then
			echo "Unable to find /etc/modprobe.d/blacklist."
			exit 2
		fi

		# Just to be safe, check for backup files...

		if [ ! -e /etc/modprobe.d/blacklist.bak ]; then
			cp /etc/modprobe.d/blacklist /etc/modprobe.d/blacklist.bak
		fi

		if [ ! -e /etc/modules.bak ]; then
			cp /etc/modules /etc/modules.bak
		fi
	;;
	install)
	;;
	--help)
		ShowUsage
		exit 1
	;;
esac

if [ "$1" == "install" ]; then
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root.  Please use sudo $0 to run."
	   exit 2
	fi

	InstallMadwifi $LEAVEDIR

	echo "Please restart system for changes to take affect."

	exit 0
fi

ENABLE=`echo "$1" | grep -i "enable" | wc -l`

case $1 in
	enable)
		# enable madwifi
		cat /etc/modprobe.d/blacklist | sed "s|^blacklist ath|# blacklist ath|g" > /etc/modprobe.d/blacklist.tmp
		cp /etc/modprobe.d/blacklist.tmp /etc/modprobe.d/blacklist

		cat /etc/modules | grep "^ath_pci" > /dev/null

		if [ $? -gt 0 ]; then
			# ath_pci not enabled.

			# check if it's there just commented out.

			cat /etc/modules | grep "# ath_pci" > /dev/null
			
			if [ $? -gt 0 ]; then
				echo "ath_pci" >> /etc/modules
			else
				cat /etc/modules | sed "s|# ath_pci|ath_pci|" > /etc/modules.tmp
				
				cp /etc/modules.tmp /etc/modules
				rm /etc/modules.tmp
			fi
		fi

		echo "Please restart system for changes to take affect."
	;;
	disable)
		# disable madwifi
		cat /etc/modprobe.d/blacklist | sed "s|^# blacklist ath|blacklist ath|g" > /etc/modprobe.d/blacklist.tmp
		cp /etc/modprobe.d/blacklist.tmp /etc/modprobe.d/blacklist

		cat /etc/modprobe.d/blacklist | grep -E "^blacklist ath" > /dev/null
		
		if [ $? -gt 0 ]; then
			# Not in file, add it.
			echo "blacklist ath_pci" >> /etc/modprobe.d/blacklist
		fi

		cat /etc/modules | grep "^ath_pci" > /dev/null

		if [ $? -eq 0 ]; then
			# ath_pci enabled.

			cat /etc/modules | sed "s|^ath_pci|# ath_pci|" > /etc/modules.tmp
			
			cp /etc/modules.tmp /etc/modules
			rm /etc/modules.tmp
		fi
		echo "Please restart system for changes to take affect."
	;;
	status)
		HASMODULE=`cat /etc/modules | grep -E "^ath_pci" | wc -l`

		if [ $HASMODULE -gt  0 ]; then
			echo "Madwifi status: enabled"
			VERSION=`modinfo ath_pci | grep "^version" | sed "s|version:.*svn ||"`
			echo "Version: $VERSION"
		else
			echo "Madwifi status: disabled"
		fi
	;;
	*)
		ShowUsage

		exit 1
	;;
esac

