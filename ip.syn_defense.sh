#!/bin/bash

# Couple of useful articles:
# http://ufsdump.org/papers/uuasc-november-ddos.html
# http://www.symantec.com/connect/articles/hardening-tcpip-stack-syn-attacks

echo ""
echo "[`date`] Current settings: " 
sysctl net.ipv4.tcp_max_syn_backlog
sysctl net.ipv4.tcp_syncookies
sysctl net.ipv4.tcp_synack_retries

echo ""
echo "[`date`] Adjusting..."
sysctl -w net.ipv4.tcp_max_syn_backlog="2048"
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.tcp_synack_retries=1

echo ""
echo "[`date`] New settings..."
sysctl net.ipv4.tcp_max_syn_backlog
sysctl net.ipv4.tcp_syncookies
sysctl net.ipv4.tcp_synack_retries
echo ""

if [ -d /etc/network/if-up.d ]; then
	HASLINK=`ls /etc/network/if-up.d/ip_syn_defense 2>/dev/null | wc -l`
	
	if [ $HASLINK -eq 0 ]; then
		if [ ! -e /usr/bin/ip.syn_defense.sh ]; then
			cp $0 /usr/bin/ip.syn_defense.sh
			chmod 744 /usr/bin/ip.syn_defense.sh
		fi
		
		if [ -e /usr/bin/ip.syn_defense.sh ]; then
	
			ln -s /usr/bin/ip.syn_defense.sh /etc/network/if-up.d/ip_syn_defense
		else
			echo "ERROR: /etc/network/if-up.d/ip_syn_defense does not exist and cannot find /usr/bin/ip.syn_defense.sh to create link."
		fi
	fi
fi

# On Red-Hat, also use: echo 1 > /proc/sys/net/ipv4/tcp_syncookies
# This will need to go in a config script.

# Can simulate a DoS attack with something like:
# while TRUE; do
# ./sendip -p ipv4 -p tcp -ts r -td 23 ddos-1.example.com
# done

# Can use netstat to detect:
# netstat -an | grep "SYN_RCVD" | wc -l

