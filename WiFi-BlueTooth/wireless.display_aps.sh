#!/bin/sh +x

ShowUsage() {
	echo ""
	echo "Usage: $0 [--help] [--bands=<abg>] [--output=<Output file prefix>] [--interface=<interface>] "
	echo "[--channel=<channel>,<channel>] [--bssid=<ap mac address>] [--showack] [--only-associated] [--gps]"
	echo ""
	echo "--help    This message."
	echo "--bands   Specify the wirelesss bands a/b/g to monitor.  Default is b/g"
	echo "--output  Write data to data set withthe specified output prefix"
	echo "--interface Use the specified interface.  Default is first iwconfig "
	echo "            interface in monitoring mode."
	echo "--channel  Channel to listen to.  (Default is all)"
	echo "--bssid    Filter based on AP mac address.  Note that this could require airodump-ng/aircrack-ng to be built from source."
	echo "--showack  Show ACK statistics.  Useful for troubleshooting."
	echo "--only-associated If specified, only show associated clients.  Default is all."
	echo "--gps       Enable gps tagging (requires gpsdrive)."
	echo ""
}

BANDS="bg"
OUTPUTFILE=""
ONLYASSOCIATED=""
GPS=""
CHANNEL=""
BSSID=""
SHOWACK=""

MONINTERFACE=`wireless.showmonitorinterface.sh 2> /dev/null`

if [ ${#MONINTERFACE} -eq 0 ]; then
#	echo "Unable to find monitor interface.  Please run wireless.monitormode.sh to configure."
#	echo "DEBUG: $MONINTERFACE"
#	exit 1
	# Use first wlan interface
	MONINTERFACE=`iwconfig 2>&1 | grep -Eio "wlan[0-9]{1,2}" | grep -v "^$"`
fi

# By default use the first monitoring mode interface....
MONINTERFACE=`echo "$MONINTERFACE" | head -1`

for i in $*
do
	case $i in
	--bands=*)
		BANDS=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--output=*)
		OUTPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--interface=*)
		MONINTERFACE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--channel=*)
		CHANNEL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		CHANNEL=`echo -c $CHANNEL`
	;;
	--bssid=*)
		BSSID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		BSSID=`echo "--bssid $BSSID"`
	;;
	--only-associated)
		ONLYASSOCIATED="-a"
	;;
	--showack)
		SHOWACK="--showack"
	;;
	--gps)
		GPS="-g"
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

if [ ${#OUTPUTFILE} -eq 0 ]; then
	airodump-ng $MONINTERFACE $SHOWACK -b $BANDS $ONLYASSOCIATED $CHANNEL $BSSID $GPS
else
	airodump-ng $MONINTERFACE $SHOWACK -b $BANDS -w $OUTPUTFILE $ONLYASSOCIATED $CHANNEL $BSSID $GPS
fi

