#!/bin/bash

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
	ssh.pivot.sh --idfile=$HOME/.ssh/mpiscopo_wopr.privatekey --background --localport=8834 --remoteip=10.8.0.17 --remoteport=8834 mpiscopo@$WOPR
else
	ssh.pivot.sh --background --localport=8834 --remoteip=10.8.0.17 --remoteport=8834 mpiscopo@$WOPR
fi

echo "Listening on 8834."

