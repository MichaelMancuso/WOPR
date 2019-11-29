#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <--status | --test | --set-large | --set-default | --help> [--target=<IP | hostname>]"
	echo "--status	Display the current default route's MTU size."
	echo "--test	Test the default gateway for large MTU support."
	echo "          Will return: 0 - Jumbo supported, 1 - Not supported, 2 - Error in testing"
	echo "--set-large  Test and if it's available leave it set at MTU=9000.  Same return codes as --test."
	echo "--set-default  Return MTU to the default 1500 setting and don't test."
	echo "--target=<ip | hostname>  If a specific target is specified (such as a server) then it is used as the recipient of the ping, otherwise the default gateway is used."
	echo ""
}

SHOWSTATUS=0
SETLARGE=0
SETDEFAULT=0
SPECIFICTARGET=""

if [ $# -gt 0 ]; then
	for i in $*
	do
		case $i in
			--status)
				SHOWSTATUS=1
			;;
			--test)
			;;
			--set-large)
				SETLARGE=1
			;;
			--set-default)
				SETDEFAULT=1
			;;
			--help)
				ShowUsage
				exit 0
			;;
			--target=*)
				SPECIFICTARGET=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
			;;
			*)
				ShowUsage
				exit 0
			;;
		esac
	done
else
	ShowUsage
	exit 0
fi

# This script will return:
# 0 - If Jumbo frames are supported
# 1 - If they are not
# 2 - If an error occurred (like not finding the default gateway)

# Get the interface to use
DEFROUTE_INT=`route -n | grep "^0.0.0.0" | head -1 | awk '{print $8}'`

if [ ${#DEFROUTE_INT} -eq 0 ]; then
	echo "ERROR: unable to identify default route adapter from routing table."
	echo "Default route:"
	route -n | grep "^0.0.0.0"
	exit 1
fi

TESTINTERFACE="$DEFROUTE_INT"
# Get the current MTU size
CUR_MTU=`ifconfig $TESTINTERFACE | grep -Eio "MTU:[0-9]{1,}" | sed "s|MTU:||"`

# If this is a status request, just display it and exit.
if [ $SHOWSTATUS -eq 1 ]; then
	echo "Interface $TESTINTERFACE:"
	ifconfig $TESTINTERFACE | grep "MTU"
	exit 0
fi

# If this is a set default, set it to 1500 and exit
if [ $SETDEFAULT -eq 1 ]; then
	ifconfig $TESTINTERFACE mtu 1500
	exit 0
fi

DEFAULTMTU=1

# If it's set at 1500 make it bigger so we can try a bigger packet
if [ $CUR_MTU -eq 1500 ]; then
	# Set MTU to 9000
	ifconfig $TESTINTERFACE mtu 9000
	
	if [ $? -gt 0 ]; then
		echo "ERROR setting MTU 9000.  This typically happens when your adapter ($TESTINTERFACE) doesn't support large MTU's"
		exit 1
	fi
	
	DEFAULTMTU=0
fi

if [ ${#SPECIFICTARGET} -eq 0 ]; then
	# Get the default gateway
	DEF_GATEWAY=`route -n | grep "^0.0.0.0" | head -1 | awk '{print $2}'`

	if [ ${#DEF_GATEWAY} -eq 0 ]; then
		echo "ERROR: Unable to get default gateway from routing table."
		exit 2
	fi
else
	DEF_GATEWAY="$SPECIFICTARGET"
fi

TESTSIZE=2000

# Ping it with a large packet and see if it responds
echo "Testing $DEF_GATEWAY with a $TESTSIZE byte packet..."
ping -M do -c 2 -s $TESTSIZE $DEF_GATEWAY

if [ $? -eq 0 ]; then
	echo ""
	echo "Jumbo frames are supported by the system $DEF_GATEWAY."
	JUMBOFRAMES=0
else
	echo ""
	echo "Jumbo frames do not appear to be supported by the system $DEF_GATEWAY."
	JUMBOFRAMES=1
fi

if [ $DEFAULTMTU -eq 0 ]; then
	# if we changed the MTU size to test and the command-line parameter doesn't say to leave it large, change it back.
	if [ $SETLARGE -eq 0 ]; then
		# Change it back
		ifconfig $TESTINTERFACE mtu 1500
	fi
fi

exit $JUMBOFRAMES

