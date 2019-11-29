#!/bin/bash
ShowUsage() {
	echo "Usage: $0 --target=<system> --outputfile=<outputfile> [--userid=<userid>] [--idfile=<ssh key file>] [-v]"
	echo "This script will pull CPU, memory, disk, and swap file statistics"
	echo "from the target system and store them in the specified file."
	echo "By default the username will be root@<system>.  This can be overridden and "
	echo "a private key file can be specified to automate collection without supplying the password."
	echo "-v will provide more verbose output."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

SYSTEM=""
OUTPUTFILE=""
USERID="root"
IDFILE=""
VERBOSE=0

for i in $*
do
	case $i in
		-v)
			VERBOSE=1
		;;
    	--target=*)
			SYSTEM=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
		--outputfile=*)
			OUTPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
		--userid=*)
			USERID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
		--idfile=*)
			IDFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
		*)
			ShowUsage
			exit 1
		;;
	esac
done

if [ ${#OUTPUTFILE} -eq 0 ]; then
	echo "ERROR: Please provide an output file."
	exit 255
fi

if [ ${#SYSTEM} -eq 0 ]; then
	echo "ERROR: Please provide a target system."
	exit 255
fi

DATESTR=`date +"%D %T"`
echo "[$DATESTR] Collecting from $SYSTEM..." >&2

if [ ${#IDFILE} -eq 0 ]; then
	RESULTS=`ssh $USERID@$SYSTEM "top -b -n 1" | grep -E "^(Cpu|Mem|Swap)"`
else
	RESULTS=`ssh -i $IDFILE $USERID@$SYSTEM "top -b -n 1" | grep -E "^(Cpu|Mem|Swap)"`
fi

if [ ${#RESULTS} -eq 0 ]; then
	echo "ERROR:"
	echo "$RESULTS"
	exit 255
fi

CPU=`echo "$RESULTS" | grep -Eio "[0-9]{1,3}\.[0-9]\%us" | sed "s|us||"`
MEM=`echo "$RESULTS" | grep "^Mem"`
SWAP=`echo "$RESULTS" | grep "^Swap"`
MEMTOTAL=`echo "$MEM" | grep -Eio "[0-9]{1,}k total" | sed "s|k total||"`
MEMUSED=`echo "$MEM" | grep -Eio "[0-9]{1,}k used" | sed "s|k used||"`
MEMFREE=`echo "$MEM" | grep -Eio "[0-9]{1,}k free" | sed "s|k free||"`
SWAPTOTAL=`echo "$SWAP" | grep -Eio "[0-9]{1,}k total" | sed "s|k total||"`
SWAPUSED=`echo "$SWAP" | grep -Eio "[0-9]{1,}k used" | sed "s|k used||"`
SWAPFREE=`echo "$SWAP" | grep -Eio "[0-9]{1,}k free" | sed "s|k free||"`

if [ $VERBOSE -eq 1 ]; then
	echo "[`date +"%D %T"`]"
	echo "CPU: $CPU"
	echo "Mem: $MEMFREE free, $MEMUSED used, $MEMTOTAL total"
	echo "Swap: $SWAPFREE free, $SWAPUSED used, $SWAPTOTAL total"
fi

# Get disk info
if [ ${#IDFILE} -eq 0 ]; then
	DISKINFO=`ssh $USERID@$SYSTEM "df"`
else
	DISKINFO=`ssh -i $IDFILE $USERID@$SYSTEM "df"`
fi

if [ ${#DISKINFO} -eq 0 ]; then
	echo "ERROR:"
	echo "$DISKINFO"
	exit 255
fi

DISKLIST=`echo "$DISKINFO" | grep -Eio "^\/dev\/sda[1-9]" | sed "s|\/dev\/||g"`
DISKS=`echo "$DISKINFO" | grep -Eio "^\/dev\/sda[1-9]" | tr "\n" "," | sed "s|,$|\n|" | sed "s|,|, |g" | sed "s|\/dev\/||g"`

if [ ! -e $OUTPUTFILE ]; then
	echo "TIME,SYSTEM, CPU, MEM FREE, MEM USED, MEM TOTAL, SWAP FREE, SWAP USED, SWAP TOTAL, $DISKS" > $OUTPUTFILE
fi

if [ $VERBOSE -eq 1 ]; then
	echo "Disk Info:"
	echo "$DISKINFO"
	echo "DISKS Inspected: $DISKS"
fi

DISKUSEDOUTPUT=""

for CURDISK in $DISKLIST
do
	DISKUSED=`echo "$DISKINFO" | grep "$CURDISK" | grep -Eio "[0-9]{2,}.*\%" | grep -Eio "[0-9]{1,}" | head -2 | tail -1`

	if [ $VERBOSE -eq 1 ]; then
		echo "$CURDISK used: $DISKUSED"
	fi
	
	DISKUSEDOUTPUT=`echo -e "$DISKUSEDOUTPUT\n$DISKUSED"`
done

DISKUSEDOUTPUT=`echo "$DISKUSEDOUTPUT" | tr "\n" "," | sed "s|,$||" | sed "s|^,||"`

echo "$DATESTR,$SYSTEM, $CPU, $MEMFREE, $MEMUSED, $MEMTOTAL, $SWAPFREE, $SWAPUSED, $SWAPTOTAL, $DISKUSEDOUTPUT" >> $OUTPUTFILE
