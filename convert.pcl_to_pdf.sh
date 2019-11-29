#!/bin/sh

# NOTE: because this pc16 is a windows app, this script is designed
# to run under Windows so both a Linux/cygwin file path and a windows file path are needed (pc16 takes windows path
# but file check needs linux path
GHOSTPCLDIR="/cygdrive/c/Tools/Program Files/GhostPCL"

ShowUsage() {
	echo "$0 <pcl file name>"
	echo ""
	echo "$0 converts pcl print jobs to pdf using GhostPCL.  PCL jobs can be captured from a pcap file by finding tcp/9100 conversations and saving the stream as a raw file."
	echo ""
	echo "In order to get the individual files from a network, run wireshark/tcpdump and filter out TCP/9100 LPR packets.  Then save just the LPR packets in a separate cap file and use 'tcptrace -e <capfile> to extract each individual stream to a separate file."
	echo ""
	echo "Files can be renamed with a command similar to: rename 's/\.dat$/\.pcl/' *.dat"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

FILENAME=$1
LINUXFILENAME=$1

echo "$LINUXFILENAME" | grep -q '\\'

if [ $? -eq 0 ]; then
# Filename is windows format with full path
	LINUXFILENAME=`echo "/cygdrive/$FILENAME"`
	LINUXFILENAME=`echo "$LINUXFILENAME" | sed 's|\\\\|\/|g' | sed 's|:||'`
else
# File is relative.  Full path is still needed since we cd later
	CURDIR=`pwd`
	LINUXFILENAME=`echo "$CURDIR/$FILENAME"`
	FILENAME=`echo "$LINUXFILENAME" | sed 's|\/|\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\c\\\\|\\\\c:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\d\\\\|\\\\d:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\e\\\\|\\\\e:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\f\\\\|\\\\f:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\g\\\\|\\\\g:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\h\\\\|\\\\h:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\i\\\\|\\\\i:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\n\\\\|\\\\n:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\z\\\\|\\\\z:\\\\|g'`
	FILENAME=`echo "$FILENAME" | sed 's|\\\\cygdrive\\\\||'`
fi

# LINUXFILENAME=`echo "$LINUXFILENAME" | sed 's| |\\\\ |g'`

if [ ! -e "$LINUXFILENAME" ]; then
	echo "ERROR: Unable to find file $FILENAME"
	exit 2
fi

cd "$GHOSTPCLDIR"

echo "Processing $FILENAME to $FILENAME.pdf..."
./pc16 -sDEVICE=pdfwrite -sOutputFile="$FILENAME.pdf" "$FILENAME"
