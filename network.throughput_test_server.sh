#!/bin/bash

which iperf3 > /dev/null

if [ $? -gt 0 ]; then
	apt-get -y install iperf3
fi

echo "[`date`] Starting iperf server..."

iperf3 -s
