#!/bin/bash

# Functions
# --------------------------------
ShowUsage() {
	echo ""
	echo "$0 Usage: $0 [--help] [--maxtime=<time>] [--file=<host file>] | <host>"
	echo ""
	echo ""
	echo "$0 scans the specified host or hosts and extracts the certificate's common name."
	echo ""
  	echo -e "\033[1mParameters:\033[0m"
	echo "--help 		This help screen"
	echo "--maxtime=<time>  Maximum time for any one dirb scan to run.  Default is 6h.  Designators can be "
	echo "			a time followed by 's', 'm', or 'h' for seconds, minutes, or hours"
	echo "--file=<file>	Read multiple hosts in from specified file. Host can be <BaseURL> or <BaseURL:Port>.  Ex: http://myserver:8080/ or https://myserver:444/"
	echo "<host>		Host to scan.  Either provide --file or hostname. Host can be <BaseURL> or <BaseURL:Port>"
	echo ""

}

ShowMessage() {
	if [ $# -lt 2 ]; then
		echo "ERROR in ShowMessage call.  Please provide message and Verbose flag." 
		exit 4
	fi

	MESSAGE=`echo "$1"`
	VERBOSE=$2

	if [ $VERBOSE -eq 1 ]; then
		echo "$MESSAGE" >&2
	fi
}

BoundWebScanProcesses() {
	# New memory management approach, try to keep 250M free.

	MINSCANMEMFREE=100

	WAITING=0
	FREEMEM=`free -m | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4`
	if [ $FREEMEM -lt $MINSCANMEMFREE ]; then
		echo -n "Waiting for memory to free up (only $FREEMEM available).."
		WAITING=1
	fi

	while [ `free -m | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4` -lt $MINSCANMEMFREE ]
	do
		echo -n "."
		sleep 9s
		
		CheckForKeypress
	done	

	if [ $WAITING -eq 1 ]; then
		echo "Continuing"
	fi
}

CheckForKeypress() {
	USER_INPUT=""
	read -t 1 -n 1 USER_INPUT 

	if [ ${#USER_INPUT} -gt 0 ]; then
		case $USER_INPUT in
		p)
			echo ""
			echo "Paused [`date`].  Press c to continue or q to quit."

			while true
			do
				USER_INPUT=""
				read -t 1 -n 1 USER_INPUT 
				if [ ${#USER_INPUT} -gt 0 ]; then
					case $USER_INPUT in
					c)
						echo "Continuing [`date`]..."
						break			
					;;
					q)
						echo "Quitting [`date`]."
						exit 1
					;;
					*)
						echo "Paused.  Press c to continue or q to quit."
					;;
					esac
				fi
			done
		;;
		q)
			echo "Quitting [`date`]."
			exit 1
		;;
		esac
	fi
}

# MAIN
# ------------------------------------------

# GLOBALS
VERBOSE=0
SHOWDETAIL=0
SHOWSHORT=0
HOSTFILE=""
HOSTS=""
FROMFILE=0
MAXTIME="6h"
DICTIONARYFILE="/opt/dirbuster/directory-list-2.3-small.txt"

OSTYPE=`uname`

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

# Parse parameters
if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
    	--file=*)
		HOSTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		FROMFILE=1
	;;
	*)
		HOSTS=$i
	esac
done

# Perform safety and setting checks
if [ ${#HOSTFILE} -eq 0 -a ${#HOSTS} -eq 0 ]; then
	echo "ERROR:  Please either specify a host to scan or a file of hosts."
	echo ""
	exit 2
fi

if [ $FROMFILE -eq 1 ]; then
	if [ ! -e $HOSTFILE ]; then
		echo "ERROR: Unable to find file $HOSTFILE"
		exit 3
	fi

	HOSTS=`cat $HOSTFILE | grep -Ev -e "^$" -e "^#"`
fi

echo "Scanning:"
echo "$HOSTS"		

CURDIR=`pwd`

for CURHOST in $HOSTS
do
	SCANURL="$CURHOST"
	SCANHOST=`echo "$SCANURL" | sed "s|http:\/\/||g" | sed "s|https:\/\/||g" | sed "s|:|\.|g" | sed "s|\/$||"`

	echo "Running dirb for $SCANURL and saving to $SCANHOST.dirb.txt..."
#	BoundWebScanProcesses
	timeout $MAXTIME dirb $SCANURL -a "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0" -o $CURDIR/$SCANHOST.dirb.txt
done

echo "Scan completed [`date`]"

