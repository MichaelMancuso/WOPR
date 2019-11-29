#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <output file>"
	echo "$0 will scan all private 172.[16-31], 192.168, and 10.[1-255] networks for live gateways."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

OUTPUTFILE="$1"

if [ -e $OUTPUTFILE ]; then
	rm $OUTPUTFILE
fi

echo "[`date`] Starting scan of 192.168 private networks..."
nmap.SearchForGateways.sh 192.168 >> $OUTPUTFILE &

echo "[`date`] Starting scan of 172.16 private networks..."
for i in {16..31}
do
	nmap.SearchForGateways.sh 172.$i >> $OUTPUTFILE &
done

echo "[`date`] Starting scan of 10.x private networks..."

for i in {1..255}
do
	nmap.SearchForGateways.sh 10.$i >> $OUTPUTFILE &
done

while true;
do
	echo -n "."

	NUMSCANSRUNNING=`ps aux | grep "nmap.SearchForGateways.sh" | grep -v grep | wc -l`

	if [ $NUMSCANSRUNNING -eq 0 ]; then
		break
	fi

	sleep 10s
done

echo ""
echo "[`date`] Done."


