#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <target ip>"
	echo ""
	echo "$0 will scan the target ip for weak IPSec transforms that might respond to a handshake request."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 0
fi

PARM_IS_IP=`echo "$1" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | wc -l`

if [ $PARM_IS_IP -eq 0 ]; then
	ShowUsage
	exit 0
fi

echo "Accepted transforms will report \"1 returned handshake\"," 
echo "failed will report \"0 returned handshake\""
# rem -T2 -d 10000 can be added to test over Cisco TCP / 10000
# rem -T1 tests for Checkpoint IKE over TCP (don't know port #)
echo "Testing DES, MD5, DH1, PSK..."
ike-scan --trans="(1=1,2=1,3=1,4=1)" -v $1
echo "Testing DES, SHA1, DH1, PSK..."
ike-scan --trans="(1=1,2=2,3=1,4=1)" -v $1
echo "Testing DES, MD5, DH2, PSK..."
ike-scan --trans="(1=1,2=1,3=1,4=2)" -v $1
echo "Testing DES, SHA1, DH2, PSK..."
ike-scan --trans="(1=1,2=2,3=1,4=2)" -v $1


