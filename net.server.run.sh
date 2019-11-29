#!/bin/bash

if [ ! -e /var/log/net.server ]; then
	mkdir /var/log/net.server
fi

cd /var/log/net.server

TCP_KEEPALIVE=`cat /proc/sys/net/ipv4/tcp_keepalive_time`

if [ $TCP_KEEPALIVE -gt 180 ]; then
	echo "WARNING: TCP Keepalive is a bit high ($TCP_KEEPALIVE seconds / 7200 is the default)"
	echo "This could leave closed connections in CLOSE_WAIT for a while.  Consider adjusting it by:"
	echo "Editing /etc/sysctl.conf and adding:"
	echo "net.ipv4.tcp_keepalive_time = 180"
	echo "Then running: 'sysctl -p /etc/sysctl.conf' to reload"
	echo "cat /proc/sys/net/ipv4/tcp_keepalive_time to verify setting."
fi

while true; do
	NUMPROCS=`ps aux | grep "net.server.ssl.rb" | grep -v grep | wc -l`
	
	if [ $NUMPROCS -eq 0 ]; then
		echo "[`date`] net.server.ssl.rb died.  Restarting..." >> /var/log/net.server/service_monitor.log

		net.server.ssl.rb &
	fi
	
	sleep 1m
done
