#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <pcap filename> [interface]"
	echo "$0 will start tcpdump on eth0 (or interface specified) and write output to the specified pcap file.  At intervals it will convert this file to a pdml file for use with john's krbng2john.py script and output the hashes to a <pcapfile>.krb5.john file."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

PCAPFILE=$1
INTERFACE=eth0

if [ $# -gt 1 ]; then
	INTERFACE=$2
fi

# Need full path...
FULLPATH=`echo "$PCAPFILE" | grep "^\/" | wc -l`

if [ $FULLPATH -eq 0 ]; then
	PCAPFILE=`echo "$PWD/$PCAPFILE"`
fi

cd /opt/john/1.8-MultiCore

echo "[`date`] Starting capture (output will be written to $PCAPFILE.krb5.john in 2 minute intervals)..."

while true
do
	timeout 2m tcpdump -v -i $INTERFACE -w $PCAPFILE "port 88"
	tshark -r $PCAPFILE -T pdml > $PCAPFILE.pdml
	echo "[`date`] Writing haches to $PCAPFILE.krb5.john..."
	./krbpa2john.py $PCAPFILE.pdml >> $PCAPFILE.krb5.john

	echo "[`date`] Current hashes:"
	cat $PCAPFILE.krb5.john
done


