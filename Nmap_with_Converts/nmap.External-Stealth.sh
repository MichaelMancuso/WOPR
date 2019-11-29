#!/bin/bash

# --------------- Functions -------------------------
ShowUsage() {
	echo "usage: $0 <target> <base descriptor>"
	echo "This script is designed to 'beat' Cisco IDS modules that limit port scans to 3 ports at a time."
	echo "With a base descriptor provided, nmap generates all three output formats with the specified base name."
	echo "<target> may start with 'file:' to designate an input target file for nmap"
}

EXPECTED_ARGS=2

if [ $# -lt $EXPECTED_ARGS ];then
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
	esac
done

BASEDESCRIPTOR=$2
TARGET=$1

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

	if [ ! -e $NETFILE ]; then
		echo "ERROR: Unable to find file '$NETFILE'"
		exit 2
	fi

	TARGET=`echo "-iL $NETFILE"`
fi

# Cisco IDS "TCP Port Sweep" or "UDP Port Sweep" rules are configured for 5 ports in 90 minutes thresholds
# So need to do 4 in 90 minutes.

TCPPORTBLOCKS=('21,22,23' '25,53,80' '81,110,443' '139,445' '636,990,2000' '2001,2512,2513' '3306,3389,5060' '5061,8000,8080' '8443,9990,10000')
UDPPORTBLOCKS=('53,123,161' '137,500,5060')

T_NUM=1
U_NUM=1

# This is the # of UDP blocks so we don't sleep an extra cycle
U_MAX=2

for TCPBLOCK in "${TCPPORTBLOCKS[@]}"; do
	echo "[`date`] Scanning TCP Block $TCPBLOCK..."
	nmap -Pn -n -sV -T3 -O -sT -p $TCPBLOCK --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -oA $BASEDESCRIPTOR-$T_NUM $TARGET
	T_NUM=$((T_NUM+1))
	echo "[`date`] TCP Sleeping 91 minutes..."
	sleep 91m
done

for UDPBLOCK in "${UDPPORTBLOCKS[@]}"; do
	echo "[`date`] Scanning UDP Block $UDPBLOCK..."
	nmap -Pn -n -sV -T3 -O -sU -p $UDPBLOCK --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -oA $BASEDESCRIPTOR-$U_NUM $TARGET
	U_NUM=$((U_NUM+1))

	if [ $U_NUM -le $U_MAX ]; then
		echo "[`date`] UDP Sleeping 91 minutes..."
		sleep 91m
	fi
done

echo "[`date`] Stealth scan finished."

