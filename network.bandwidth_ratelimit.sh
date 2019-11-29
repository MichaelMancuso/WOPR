#!/bin/bash
# References: 
# http://openvz.org/Traffic_shaping_with_tc
# http://linux.die.net/man/8/tc
# http://lartc.org/howto/lartc.qdisc.filters.html

ShowSettings() {
	tc qdisc show dev $DEV
	tc class show dev $DEV parent 1:
	tc -p filter show dev $DEV
}

# Ethernet Interface
DEV="eth0"
SHOWSETTINGSONEXIT=1

# Also note that these settings do not appear to survive a reboot so the script will need to get called on if-up
# The following lines first check before setting them.
HASSETTINGS=`tc qdisc show dev $DEV | grep "cbq 1" | wc -l`

if [ $HASSETTINGS -gt 0 ]; then
	if [ $SHOWSETTINGSONEXIT -eq 1 ]; then
		ShowSettings
	fi
	
	exit 0
fi

# Bandwidth limit mbit designator is Mbps.  Can also use kbit (kbps) for lower bandwidth.
BANDWIDTHLIMIT="4mbit"
# LINKBANDWIDTH="100mbit"
LINKBANDWIDTH=`ethtool $DEV | grep -Ei "Speed: " | grep -Eio "[0-9]{1,}" | head -1`
LINKBANDWIDTH=`echo "${LINKBANDWIDTH}mbit"`
DESTINATIONIP="199.244.201.43/32"
# The average packet size probably shouldn't be changed without a good reason:
AVERAGEPACKETSIZE=1000

# Can use 'tc qdisc show dev eth0' to show the current settings

# Remove the default pfifo
tc qdisc del dev $DEV root 2>/dev/null

# Add a new 'queueing discipline' (qdisc)
# cbq - class-based queuing 
# avpkt - average size of a packet (mandatory)
# bandwidth - Link bandwidth (mandatory)
tc qdisc add dev $DEV root handle 1: cbq avpkt $AVERAGEPACKETSIZE bandwidth $LINKBANDWIDTH

# Add a qdisc for outbound rate limiting.  Limit it to $BANDWIDTHLIMIT
# allot - the number of bytes a qdisc can dequeue 
# prio - priority.  Lower numbers dequeue first
# bounded and isolated specify that the class cannot "borrow" bandwidth from its siblings
tc class add dev $DEV parent 1: classid 1:1 cbq rate $BANDWIDTHLIMIT allot 1500 prio 5 bounded isolated

# Create a filter to match on destination IP
# u32 says that the filter can match on any part of a packet given the match designator
# prio 16 lowers the packet priority
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst $DESTINATIONIP flowid 1:1
# Can add other filters here too
# This one will PRIORITIZE (queue 1) SSL traffic
# tc filter add dev eth0 protocol ip parent 10: prio 1 u32 match ip dport 443 flowid 1:1
# This will prioritize HTTP traffic from the specified IP
# tc filter add dev eth0 parent 10:0 protocol ip prio 1 u32 match ip src 4.3.2.1/32 match ip dport 80 flowid 1:1
  
# Add a classless Stochastic Fairnesss Queue
# Can also retune for Random Early Detection with the "red" parameter rather than sfq
tc qdisc add dev $DEV parent 1:1 sfq perturb 10

if [ $SHOWSETTINGSONEXIT -eq 1 ]; then
	ShowSettings
fi
