#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <nmap output name>"
	echo "$0 will test an nmap scan against portquiz.net, a site with all TCP ports available to determine outbound firewall rules."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

OUTPUTNAME=$1
nmap -Pn -n -sT -sU --max-retries 1 -oA $OUTPUTNAME portquiz.net