#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <VPN IP/name of remote system>"
	echo "On remote system first run 'tightvncserver' as the desired user."
	echo "Use tightvnc viewer with a destination of 127.0.0.1:5901 to connect"
}

nslookup wopr.ais.local > /dev/null 

if [ $? -eq 0 ]; then
	WOPR="wopr.ais.local"
else
	WOPR="wopr.alliedinfosecurity.com"
fi

if [ -e $HOME/.ssh/mpiscopo_wopr.privatekey ]; then
	ssh.pivot.sh -i $HOME/.ssh/mpiscopo_wopr.privatekey --localport=5901 --remoteip=10.8.0.13 --remoteport=5901 mpiscopo@$WOPR
else
	ssh.pivot.sh --localport=5901 --remoteip=10.8.0.13 --remoteport=5901 mpiscopo@$WOPR
fi
