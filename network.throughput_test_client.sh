#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <target iperf server IP> [optional test time in seconds]"
	exit 1
fi

which iperf3 > /dev/null

if [ $? -gt 0 ]; then
	apt-get -y install iperf3
fi

if [ $# -eq 1 ]; then
	iperf3 -c $1
else
	iperf3 -c $1 -t $2
fi

