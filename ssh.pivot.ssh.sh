#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <VPN IP/name of remote system>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

nslookup wopr.ais.local > /dev/null 

if [ $? -eq 0 ]; then
	WOPR="wopr.ais.local"
else
	WOPR="wopr.alliedinfosecurity.com"
fi

if [ -e $HOME/.ssh/mpiscopo_wopr.privatekey ]; then
	ssh.pivot.sh -i $HOME/.ssh/mpiscopo_wopr.privatekey --localport=2222 --remoteip=$1 --remoteport=22 mpiscopo@$WOPR
else
	ssh.pivot.sh --localport=2222 --remoteip=$1 --remoteport=22 mpiscopo@$WOPR
fi
