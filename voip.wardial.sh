#!/bin/sh

ShowUsage() {
	echo "Usage: $0 [--areacode=<areacode e.g. 215> --prefix=<prefix e.g. 555> --range=<range: e.g. 1000-1012>] "
	echo "          OR [--numberfile=<file>]"
	echo "          [--logfile=<file>] [--device=/dev/<device>] [--dial9first] [-v]"

	echo ""
	echo "$0 will dial the specified phone number range with tone location and report the results."
	echo "By default, the standard serial port (/dev/ttyS0) will be used.  If you would like to use a "
	echo "USB/serial adapter such as /dev/ttyUSB0 use --device to specifiy it."
	echo ""
	echo "Most parameters are self-explanatory.  The number range can't include 1 number: e.g. 1000-1000."
	echo ""
	echo "-v  Verbose Mode"
	echo "--dial9first  Dials 9 and waits for secondary dialtone before dialing a number."
	echo "--numberfile  A file containing the numbers to dial, one number per line. e.g.: 2155551212"
	echo ""
}

# -a enable tone detection (toneloc)
# --npa is the area code (e.g. 215)
# --nxx is the number prefix (e.g. 555-)

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

VERBOSE=1
AREACODE=""
NUMBERPREFIX=""
RANGE=""
LOGFILE=""
MODEM="/dev/ttyS0"
DIAL9=0
NUMBERFILE=""

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	-v)
		VERBOSE=1
	;;
	--areacode=*)
		AREACODE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--prefix=*)
		NUMBERPREFIX=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--range=*)
		RANGE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--numberfile=*)
		NUMBERFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--logfile=*)
		LOGFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--device=*)
		MODEM=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	--dial9first)
		DIAL9=1
	;;
	esac
done

echo "$MODEM" | grep -i "ttyUSB" > /dev/null

if [ $? -eq 0 ]; then
	# Use USB/Serial adapter
	NUMMODEMS=`ls -1 $MODEM | wc -l`

	if [ $NUMMODEMS -eq 0 ]; then
		echo "ERROR: Unable to find usb/serial modem at $MODEM"
		exit 2	
	fi
fi

if [ ${#NUMBERFILE} -eq 0 ]; then
	if [ ${#AREACODE} -ne 3 ]; then
		echo "ERROR: Please provide a valid area code.  E.g. 215"
		echo "Value provided: $AREACODE"
		exit 2
	fi

	if [ ${#NUMBERPREFIX} -ne 3 ]; then
		echo "ERROR: Please provide a valid number prefix.  E.g. 555"
		echo "Value provided: $NUMBERPREFIX"
		exit 2
	fi

	if [ ${#RANGE} -ne 9 ]; then
		echo "ERROR: Please provide a valid number range.  E.g. 1000-1012"
		echo "Value provided: $RANGE"
		exit 2
	fi

# Most modems including the Courier V.Everything can't do tone detection
#	PARAMETERS=`echo "--info --tonedetect --device $MODEM --npa $AREACODE --nxx $NUMBERPREFIX --range $RANGE"`
	PARAMETERS=`echo "--info --device $MODEM --npa $AREACODE --nxx $NUMBERPREFIX --range $RANGE"`
	echo "Running dial against $AREACODE-$NUMBERPREFIX-[$RANGE]..."
else
	# Running from numbers in a file
# Most modems including the Courier V.Everything can't do tone detection
#	PARAMETERS=`echo "--info --tonedetect --device $MODEM --loadfile $NUMBERFILE"`
	PARAMETERS=`echo "--info --device $MODEM --loadfile $NUMBERFILE"`
fi



if [ ${#LOGFILE} -gt 0 ]; then
	echo "(and writing output to log file $LOGFILE)"

	PARAMETERS=`echo "$PARAMETERS --logfile $LOGFILE --fulllog"`
fi

if [ $DIAL9 -eq 1 ]; then
	PARAMETERS=`echo "$PARAMETERS --predial 9w1"`
else
	PARAMETERS=`echo "$PARAMETERS --predial 1"`
fi

if [ $VERBOSE -eq 1 ]; then
	echo "Running iwar with the following parameters:"
	echo "iwar $PARAMETERS"
	echo ""
fi

iwar $PARAMETERS

