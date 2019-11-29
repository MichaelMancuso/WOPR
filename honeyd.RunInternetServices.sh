#!/bin/sh

ShowUsage() {
	echo "Usage: $0 [--help] [script file]"
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

SCRIPTFILE="/usr/share/honeyd/scripts/config.InternetServices"

for i in $*
do
	case $i in
    	--help)
		ShowUsage
		exit 1
	;;
	*)
		SCRIPTFILE=$i
	esac
done

if [ ! -e $SCRIPTFILE ]; then
	echo "ERROR: Unable to find $SCRIPTFILE"
	exit 2
fi

IPADDRESSES=`cat $SCRIPTFILE | grep bind | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

CURDIR=`pwd`
cd /usr/share/honeyd/scripts
echo "Running arpspoof for the following IP addresses:"
echo "$IPADDRESSES"

for IPADDRESS in $IPADDRESSES
do
	arpspoof $IPADDRESS
done

echo "Starting honeyd with configuration file $SCRIPTFILE."
echo "Check /var/log/honeyd for generated log files."
honeyd -d -u 1000 -g 1000 -f $SCRIPTFILE
cd $CURDIR

