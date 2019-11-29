#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <source i/f> <dest i/f>"
	echo "$0 mirrors traffic from one interface to another."
	echo "see http://backreference.org/2014/06/17/port-mirroring-with-linux-bridges/ for a reference."
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

ETH1=$1
ETH2=$2

tc qdisc add dev $ETH1 ingress
tc filter add dev $ETH1 parent ffff: protocol all u32 match u8 0 0 action mirred egress mirror dev $ETH2
# tc qdisk show dev $ETH1
