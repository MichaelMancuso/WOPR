#!/bin/bash

ShowUsage() {
	echo "$0 Usage: $0 <vlan id>"
	echo "$0 will remove an 802.1q tagged vlan interface eth0.xxx as specified by the vlan id"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

VLANID=$1
ETHINT=`echo "eth0.$VLANID"`

ifconfig -a | grep -qP "$ETHINT\s"

if [ $? -gt 0 ]; then
	echo "ERROR: unable to find interface $ETHINT."
	exit 2
fi

ifconfig $ETHINT down
vconfig rem $ETHINT


