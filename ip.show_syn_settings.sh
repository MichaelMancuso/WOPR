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

# On Red-Hat, also use: echo 1 > /proc/sys/net/ipv4/tcp_syncookies
# This will need to go in a config script.

# Can simulate a DoS attack with something like:
# while TRUE; do
# ./sendip -p ipv4 -p tcp -ts r -td 23 ddos-1.example.com
# done

# Can use netstat to detect:
# netstat -an | grep "SYN_RCVD" | wc -l

