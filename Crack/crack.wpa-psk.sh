#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 <--dictionary=<dictionary file> | --brute> --hashfile=<hash file> [--numthreads=<n>] [--format=<format>] " 
	echo ""
	echo "$0 will use john to attempt to crack a wireless wpa pre-shared key."
	echo "Steps: "
	echo "1.  Capture wireless traffic on a wireless card and save it to a pcap file."
	echo "2.  Use wpapcap2john from john to extract the hashes in a john-compatible format."
	echo "3.  Run through this utility with desired settings."
	echo ""
	echo "Notes: the optional format specifier can be wpapsk,wpapsk-cuda, or wpapsk-opencl"
	echo "      wpapsk is standard john, -cuda for NVIDIA CUDA, and -opencl for OpenCL"
	echo ""
	echo "      The default number of threads is 2 so it's highly recommended that more are used if available."
	echo ""
}

# Mode 1 = dict, Mode 2 = brute
MODE=2
DICTIONARYFILE=""
HASHFILE=""
BRUTEFORCE=0
FORMATSPEC="wpapsk"
NUMTHREADS=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
NUMTHREADS=$(( NUMTHREADS - 1 ))

if [ $NUMTHREADS -lt 1 ]; then
	NUMTHREADS=1
fi

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
	--dictionary=*)
		DICTIONARYFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		MODE=1
	;;
	--brute)
		BRUTEFORCE=1
		MODE=2
	;;
	--hashfile=*)
		HASHFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--format=*)
		FORMATSPEC=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	--numthreads=*)
		NUMTHREADS=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed "s|\"||g"`
	;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

echo ""
# Find john
JOHNDIR=""

if [ -e /opt/john ]; then
	DIREXISTS=`ls -1 /opt/john | grep MultiCore | wc -l`

	if [ $DIREXISTS -eq 0 ]; then
		if [ -e /opt/john/john ]; then
			JOHNDIR="/opt/john"
		fi
	else
		SUBDIR=`ls -1 /opt/john | grep -Eio "^.*MultiCore" | head -1 | tr '\n' ' ' | sed "s| ||"`
		JOHNDIR="/opt/john/$SUBDIR"
	fi
else
	JOHNEXE=`which john`
	if [ ${#JOHNEXE} -eq 0 ]; then	
		echo "ERROR: Unable to find john in /opt/john/...Multicore, /opt/john/ or in path"
		exit 2
	fi

fi

if [ ${#JOHNDIR} -gt 0 ];  then
	CURDIR=`pwd`
	cd "$JOHNDIR"

	HASFULLPATH=`echo "$HASHFILE" | grep "\/" | wc -l`

	if [ $HASFULLPATH -eq 0 ]; then
		# since we changed dirs we need to prepend original location
		HASHFILE="$CURDIR/$HASHFILE"
	fi

	HASFULLPATH=`echo "$DICTIONARYFILE" | grep "\/" | wc -l`

	if [ $HASFULLPATH -eq 0 ]; then
		# since we changed dirs we need to prepend original location
		DICTIONARYFILE="$CURDIR/$DICTIONARYFILE"
	fi

	if [ $MODE -eq 1 ]; then
		# Dictionary
		echo "Executing 'john --format=$FORMATSPEC --wordlist=$DICTIONARYFILE --rules --fork=$NUMTHREADS $HASHFILE'..."
		./john --format=$FORMATSPEC --wordlist=$DICTIONARYFILE --rules --fork=$NUMTHREADS $HASHFILE
	else
		# Brute force
		echo "Executing 'john --format=$FORMATSPEC --incremental --fork=$NUMTHREADS $HASHFILE'..."
		./john --format=$FORMATSPEC --incremental --fork=$NUMTHREADS $HASHFILE
	fi
else
	# its in the path
	if [ $MODE -eq 1 ]; then
		# Dictionary
		echo "Executing 'john --format=$FORMATSPEC --wordlist=$DICTIONARYFILE --rules --fork=$NUMTHREADS $HASHFILE'..."
		john --format=$FORMATSPEC --wordlist=$DICTIONARYFILE --rules --fork=$NUMTHREADS $HASHFILE
	else
		# Brute force
		echo "Executing 'john --format=$FORMATSPEC --incremental --fork=$NUMTHREADS $HASHFILE'..."
		john --format=$FORMATSPEC --incremental --fork=$NUMTHREADS $HASHFILE
	fi
fi


echo "[`date`] done"

