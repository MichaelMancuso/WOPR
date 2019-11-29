#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <VPN IP/name of remote system>"
}

nslookup wopr.ais.local > /dev/null 

if [ $? -eq 0 ]; then
	WOPR="wopr.ais.local"
else
	# Can't resolve name.  See if we're VPN'd.
	HASTUNNEL=`ifconfig tun0 | grep "tun0" | wc -l`

	if [ $HASTUNNEL ]; then
		WOPR="10.8.0.1"
	else
		WOPR="wopr.alliedinfosecurity.com"
	fi
fi

if [ -e $HOME/.ssh/mpiscopo_wopr.privatekey ]; then
	ssh.pivot.sh --idfile=$HOME/.ssh/mpiscopo_wopr.privatekey --background --localport=2222 --remoteip=10.8.0.13 --remoteport=22 mpiscopo@$WOPR
else
	ssh.pivot.sh --background --localport=2222 --remoteip=10.8.0.13 --remoteport=22 mpiscopo@$WOPR
fi
