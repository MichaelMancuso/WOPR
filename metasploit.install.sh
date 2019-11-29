#!/bin/sh

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
	echo "Script running under Cygwin detected.  Downloading Windows version..."
	exit 1
fi

echo "Installing the latest version of metasploit..."


if [ $ISLINUX -eq 1 ]; then
	LATESTVERSION=`wget -qO- http://www.metasploit.com/framework/download | grep -Eio --max-count=1 "\/releases\/framework-[3-9]\.[0-9]{1,2}\.[0-9]{1,2}-linux-i686\.run" | sed "s|\/releases\/||"`
else
	LATESTVERSION=`wget -qO- http://www.metasploit.com/framework/download | grep -Eio --max-count=1 "\/releases\/framework-[3-9]\.[0-9]{1,2}\.[0-9]{1,2}\.exe" | sed "s|\/releases\/||"`
fi

if [ ! -e $LATESTVERSION ]; then
	wget http://www.metasploit.com/releases/$LATESTVERSION

	chmod +x $LATESTVERSION
fi

./$LATESTVERSION

