#!/bin/bash

ShowUsage() {
	echo "$0 Usage: $0 <vlan id>"
	echo "$0 will create a new 802.1q tagged vlan interface eth0.xxx as specified by the vlan id"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

DOT1QMOD=`modprobe -c | grep 8021q | wc -l`

if [ $DOT1QMOD -eq 0 ]; then
	modprobe 8021q
fi

VLANID=$1
ETHINT=`echo "eth0.$VLANID"`

ifconfig -a | grep -qP "$ETHINT\s"

if [ $? -eq 0 ]; then
	echo "ERROR: $ETHINT already exists."
	exit 2
fi

vconfig add eth0 $VLANID

ifconfig -a | grep -qP "$ETHINT\s"

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to create $ETHINT"
	exit 2
fi

ifconfig $ETHINT up



