#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <URL File> [output directory]"
	echo "$0 will run Nikto against each base URI.  Each URL will have a file created in the specified output directory (or current directory if not specified)."
	echo "The file should have one link per line such as: "
	echo "https://ws.mydomain.com:8443/"
	echo "192.168.1.1"
	echo "http://ws.mydomain.com/"
	echo ""
	echo "Note that the port number in the link is optional and only needs to be provided if it's on a non-standard port."
	echo ""
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

# -------------- Main ----------------------------------

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

LINKFILE="$1"

if [ ! -e $LINKFILE ]; then
	echo "[`date`] ERROR: Unable to find the file $LINKFILE."
	exit 1
fi
LINKS=`cat $LINKFILE | grep -v "^$" | grep -v "^#"`

if [ $# -gt 1 ]; then
	CURDIR="$2"
else
	CURDIR=`pwd`
fi

# NIKTODIR=`ls -1d /opt/nikto/nikto-* | grep -o "nikto-.*" | grep -v "\.tar\.gz" | sort -u | tail -1`
# NIKTODIR=`echo "/opt/nikto/$NIKTODIR"`
NIKTODIR='/opt/nikto/nikto/program'
cd $NIKTODIR

# make sure nikto is up to date
#echo "[`date`] Checking for nikto updates..."
#./nikto.pl -update

NUMLINKS=`echo "$LINKS" | wc -l`
echo "[`date`] Processing $NUMLINKS URLs..."

for CURLINK in $LINKS; do
	BoundWebScanProcesses
	SSLPARAM=""
	echo "$CURLINK" | grep -qi "^https"

	if [ $? -eq 0 ]; then
		SSLPARAM="-ssl"
	fi

	BASEDESCRIPTOR=`echo "$CURLINK" | sed "s|.*//||g" | sed "s|/||g" | sed "s|:|_|"`

	./nikto.pl -evasion 1 -maxtime 4h $SSLPARAM -host $CURLINK >> $CURDIR/$BASEDESCRIPTOR.nikto.txt &

	CheckForKeypress
done

cd $CURDIR

echo "[`date`] Waiting for nikto processes to complete..."
while true
do
	NUMPROCS=`ps aux | grep "nikto.pl" | grep -v grep | wc -l`

	if [ $NUMPROCS -eq 0 ]; then 
		break
	fi

	sleep 10s
done

echo "[`date`] Scans complete.  Moving results with no findings..."
nikto.move_nofindings.sh
mkdir summary 2>/dev/null

echo "[`date`] Converting results into $BASEDECRIPTOR.all_nikto.csv..."
nikto.ConvertToCSV.sh > summary/$BASEDECRIPTOR.all_nikto.csv

if [ -e summary/$BASEDESCRIPTOR.all_nikto.csv ]; then
	cp summary/$BASEDESCRIPTOR.all_nikto.csv $CURDIR
fi

echo "[`date`] Done"

