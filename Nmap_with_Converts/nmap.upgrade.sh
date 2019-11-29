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
	echo "Script running under Cygwin detected.  Please use Windows installer."
	exit 1
fi

echo "Checking installed components..."
CheckInstall "alien"

FORCEINSTALL=0

if [ $# -gt 0 ]; then
	for i in $*
	do
		case $i in
		--force)
			FORCEINSTALL=1
		;;
		--help)
			echo "$0 Usage:"
			echo "--force     Force install even if the latest version is installed."
			echo ""
			exit 1
		;;
		esac
	done
fi

# Get latest nmap version:
echo "Checking nmap.org for latest version information..."
LATESTNMAP=`wget -qO- "http://nmap.org/download.html" | grep -Eio "nmap-.*?\.rpm" | grep -v "\"" | grep --max-count=1 "i386"`
LATESTZENMAP=`wget -qO- "http://nmap.org/download.html" | grep -Eio "zenmap-.*?\.rpm" | grep -v "\"" | grep --max-count=1 "noarch"`

INSTALLEDNMAPVERSION=`nmap -v 2> /dev/null | grep -Eio "nmap [5-9]\.[0-9]{1,3}" | grep -Eio "[5-9]\.[0-9]{1,3}" | sed "s|\s||g"`
LATESTNMAPVERSION=`echo "$LATESTNMAP" | grep -Eo "[5-9]\.[0-9]{1,3}" | sed "s|\s||g"`

if [ "$INSTALLEDNMAPVERSION" != "$LATESTNMAPVERSION" -o $FORCEINSTALL -eq 1 ]; then
	# download nmap
	echo "Installed NMap version: $INSTALLEDNMAPVERSION"
	echo "Available NMap version: $LATESTNMAPVERSION"
	echo "Upgrading nmap..."

	wget http://nmap.org/dist/$LATESTNMAP
	wget http://nmap.org/dist/$LATESTZENMAP
	
	alien -i $LATESTNMAP
	alien -i $LATESTZENMAP
else
	echo "Currently installed version is the latest version ($INSTALLEDNMAPVERSION)."
fi
