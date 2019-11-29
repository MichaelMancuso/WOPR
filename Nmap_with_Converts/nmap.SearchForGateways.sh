#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <First Two Octets>"
	echo "$0 will check each class c for the specified octets and look for .1 and .254"
	echo "Ex: $0 172.22 will check 172.22.1.1 and 172.22.1.254, then increment to 172.22.2.1 and 172.22.2.254"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

OSTYPE=`uname`
if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	echo "Please run this on a true linux system."
	exit 3
else
	ISLINUX=1
fi

FIRSTOCTETS=$1
CUR3RDOCTET=1

for i in `seq 1 255`
do
	FOUNDSYSTEM=0
	CUR_CLASSC=`echo "$FIRSTOCTETS.$i"`
	CUR_IP1=`echo "$CUR_CLASSC.1"`
	CUR_IP254=`echo "$CUR_CLASSC.254"`
	CUR_IPOTHER=`echo "$CUR_CLASSC.3"`
	
	ping -c 1 -w 1 $CUR_IP1 > /dev/null
	
	if [ $? -eq 0 ]; then
		echo "Found $CUR_IP1"
	fi

	ping -c 1 -w 1 $CUR_IP254 > /dev/null

	if [ $? -eq 0 ]; then
		echo "Found $CUR_IP254"
	fi

	ping -c 1 -w 1 $CUR_IPOTHER > /dev/null
	
	if [ $? -eq 0 ]; then
		echo "Found $CUR_IPOTHER"
	fi

done
