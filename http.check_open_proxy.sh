#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <host> <port>"
	echo "$0 will use nmap to check the specified host and port to see if it's an open proxy."
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

nmap -Pn -n -p $2 --script http-open-proxy $1

