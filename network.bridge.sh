#!/bin/bash

# create a network bridge
ShowUsage() {
	echo "Usage: $0 <eth1> <eth2>"
	echo "may need to apt-get install bridge-utils"
	
	echo ""
	echo "To make it permanent, edit /etc/network/interfaces.  For example:"
	echo "iface br0 inet static"
    echo "    bridge_ports eth0 eth1"
    echo "    address 192.168.1.2"
    echo "    broadcast 192.168.1.255"
    echo "    netmask 255.255.255.0"
    echo "    gateway 192.168.1.1"
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

# create bridge
brctl addbr br0

# set up forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
# set up EAPOL forwarding (this requires extra things to happen [see 8021x.bridge.sh] but just for completeness)
echo 8 > /sys/class/net/br0/bridge/group_fwd_mask

# These no longer work on debian
# sysctl net.bridge.bridge-nf-call-iptables=0
# sysctl net.bridge.bridge-nf-call-arptables=0

if [ $? -eq 0 ]; then
	brctl addif br0 $1 $2
else
	echo "ERROR creating bridge br0."
fi
brctl stp br0 off

ifconfig br0 up

echo "[`date`] Done."
brctl show br0
ifconfig br0

