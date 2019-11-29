#!/bin/bash

which iperf3 > /dev/null

if [ $? -gt 0 ]; then
	apt-get -y install iperf3
fi

# See https://iperf.fr/iperf-servers.php for reference for public servers
echo "[`date`] Testing iperf.scottlinux.com (40 Gbps max)..."

iperf3 -c iperf.he.net -t 60

