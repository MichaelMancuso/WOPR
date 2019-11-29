#!/bin/bash

echo "[`date`] Hardening IP stack..."
UPDATEDSYSCTL=0

CURVAL="net.ipv4.tcp_syncookies=1"

grep -q "^$CURVAL" /etc/sysctl.conf

if [ $? -gt 0 ]; then
	# Not present.  Add it.
	echo "$CURVAL" >> /etc/sysctl.conf
	echo "Added $CURVAL"
	UPDATEDSYSCTL=1
fi

CURVAL="net.ipv4.tcp_max_syn_backlog = 2048"
grep -q "^$CURVAL" /etc/sysctl.conf

if [ $? -gt 0 ]; then
	# Not present.  Add it.
	echo "$CURVAL" >> /etc/sysctl.conf
	echo "Added $CURVAL"
	UPDATEDSYSCTL=1
fi

CURVAL="net.ipv4.tcp_synack_retries = 1"
grep -q "^$CURVAL" /etc/sysctl.conf

if [ $? -gt 0 ]; then
	# Not present.  Add it.
	echo "$CURVAL" >> /etc/sysctl.conf
	echo "Added $CURVAL"
	UPDATEDSYSCTL=1
fi

CURVAL="net.ipv4.tcp_keepalive_time = 180"
grep -q "^$CURVAL" /etc/sysctl.conf

if [ $? -gt 0 ]; then
	# Not present.  Add it.
	echo "$CURVAL" >> /etc/sysctl.conf
	echo "Added $CURVAL"
	UPDATEDSYSCTL=1
fi

CURVAL="net.ipv4.tcp_timestamps = 0"
grep -q "^$CURVAL" /etc/sysctl.conf

if [ $? -gt 0 ]; then
	# Not present.  Add it.
	echo "$CURVAL" >> /etc/sysctl.conf
	echo "Added $CURVAL"
	UPDATEDSYSCTL=1
fi

if [ $UPDATEDSYSCTL -eq 0 ]; then
	echo "[`date`] Nothing added.  All stack hardening settings were already enabled."
else
	sysctl -p
	echo "[`date`] Done."
fi
