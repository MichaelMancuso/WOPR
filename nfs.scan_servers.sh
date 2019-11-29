#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <nfs server file>"
	echo "$0 scans the systems in the nfs server file (1 IP / line) and if shares are advertised prints the results."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi
NFSSERVERFILE="$1"

if [ ! -e $NFSSERVERFILE ]; then
	echo "ERROR: Unable to find $NFSSERVERFILE."
	exit 2
fi

NFSSERVERS=`cat $NFSSERVERFILE`

for CURSERVER in $NFSSERVERS;do
	RESULTS=`sunrpc.showmountpoints.sh $CURSERVER 2>/dev/null`
	
	if [ ${#RESULTS} -gt 0 ]; then
		echo "$RESULTS" | grep -q "Program not registered"
		
		if [ $? -gt 0 ]; then
			echo "[`date`] System: $CURSERVER"
			echo "$RESULTS"
			echo ""
		fi
	fi
	
done
