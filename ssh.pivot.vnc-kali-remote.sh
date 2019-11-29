#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <kali laptop id #> <VNC Display Number>"
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

KALINUMBER=$1
DISPLAYNUMBER=$2

# See how we should reference WOPR
nslookup wopr.ais.local > /dev/null 

if [ $? -eq 0 ]; then
	# We're on the same network
	WOPR="wopr.ais.local"
else
	# Can't resolve name.  See if we're VPN'd.
	HASTUNNEL=`ifconfig tun0 | grep "tun0" | wc -l`

	if [ $HASTUNNEL ]; then
		WOPR="10.8.0.1"
	else
		# Maybe we're just outside.  Note this address and SSH has limited connectivity.
		WOPR="wopr.alliedinfosecurity.com"
	fi
fi

MYUSERNAME="mpiscopo"

KALIID=`echo "ais-kali-ovpn$KALINUMBER"`

vncviewer -via "$MYUSERNAME@$WOPR" $KALIID:$DISPLAYNUMBER

