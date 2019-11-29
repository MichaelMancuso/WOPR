#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <project base name> [override eth adapter]"
}

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

BASENAME=$1

STARTTIME=`date`

if [ $# -eq 1 ]; then
	ETHINT=`ifconfig | grep -Eio "^eth[0-9]" | sort -u | head -1`
else
	ETHINT=$2
fi

# Get DHCP Lease Info
echo "[`date`] DHCP Lease Info..."
echo "[`date`] DHCP Lease Info" > $BASENAME.dhcp_info.txt
ifconfig $ETHINT >> $BASENAME.dhcp_info.txt
cat /etc/resolv.conf >> $BASENAME.dhcp_info.txt
cat $BASENAME.dhcp_info.txt

# See who's active on the local subnet
LOCALSUBNET=`ifconfig $ETHINT | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
LOCALSUBNET=`echo "$LOCALSUBNET.0/24"`

nmap -sn -oA $BASENAME.ping_sweep $LOCALSUBNET
NUMHOSTS=`cat $BASENAME.ping_sweep.gnmap | grep "Status: Up" | wc -l`
echo "[`date`] Found $NUMHOSTS live systems in $LOCALSUBNET..."

# Check for A/V type...
echo "[`date`] Checking A/V type..."
DNSSERVER=`cat /etc/resolv.conf | grep nameserver | head -1 | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
av.check-via-dns.sh $DNSSERVER > $BASENAME.av_check.txt

# Checking Windows (DNS) Server
DNSSERVER=`cat /etc/resolv.conf | grep nameserver | head -1 | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
echo "[`date`] Checking Windows Null Session (LDAP and SMB) against $DNSSERVER..."

nmap.WindowsADEnum.sh --null-enum $DNSSERVER > $DNSSERVER.ad_null_enum.txt
nmap.WindowsSystemEnum.sh --null-enum $DNSSERVER > $DNSSERVER.null_enum.txt

# Start passive network capture and allow to run for 37 minutes
# (Need > 30 min to capture certain things like 30 min routing updates or 12 min windows updates)
timeout 37m tcpdump -i $ETHINT -w $BASENAME.passive_cap.cap &
echo "[`date`] tcpdump started for $ETHINT writing to $BASENAME.passive_cap.cap for 37 minutes.  Use ps or watch to monitor for completion."

# Scan for IP Subnets
echo "[`date`] Scanning for gateways.  This may take some time.  Use ps or watch to monitor for running 'SearchForGateways' jobs"
echo "[`date`] Starting 192.168.x.0..."
if [ -e 192.168.gateway_search.txt ]; then
	rm 192.168.gateway_search.txt
fi

nmap.SearchForGateways.sh 192.168 >> 192.168.gateway_search.txt &

echo "[`date`] Starting 172.16..."
if [ -e 172.gateway_search.txt ]; then
	rm 172.gateway_search.txt
fi

for i in {16..31}; do
	nmap.SearchForGateways.sh 172.$i >> 172.gateway_search.txt &
done

HAS_10NET=`ifconfig $ETHINT | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | wc -l`

echo "[`date`] Starting 10.[0-10]..."
if [ -e 10.gateway_search.txt ]; then
	rm 10.gateway_search.txt
fi

for i in {0..254}; do
	nmap.SearchForGateways.sh 10.$i >> 10.gateway_search.txt &
done

SEARCHESDONE=""

echo "[`done`] Watch behaves unusually so use this command to monitor for running processes:"
echo "while true; do clear && echo \"[\`date\`]\" && ps aux | grep -e SearchFor -e tcpdump | grep -v grep && sleep 5s; done"
while true; do 
	clear 
	echo "[`date`]"
	TCPDUMPRUNNING=`ps aux | grep tcpdump | grep "timeout" | grep -v grep | wc -l`
	SEARCHESRUNNING=`ps aux | grep SearchFor | grep -v grep | wc -l`

	if [ $TCPDUMPRUNNING -gt 0 ]; then
		echo "tcpdump running: Yes"
	else
		echo "tcpdump running: No"
	fi

	if [ $SEARCHESRUNNING -eq 0 -a ${#SEARCHESDONE} -eq 0 ]; then
		SEARCHESDONE=`date`
	fi
	
	if [ $SEARCHESRUNNING -gt 0 ]; then
		echo "Subnet Searches running: $SEARCHESRUNNING"
	else
		echo "Subnet Searches running: Started $STARTTIME and Finished at $SEARCHESDONE"
	fi

	sleep 5s

	if [ $TCPDUMPRUNNING -eq 0 -a $SEARCHESRUNNING -eq 0 ]; then
		break;
	fi
done

echo "Done.  Ran from $STARTTIME to `date`.  Subnet searches ran till $SEARCHESDONE."

