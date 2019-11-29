#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <ssh username> <target SSH Server IP> <target SSH Server Port> <destination VNC Server IP> <VNC Display Id>"
	echo "This script is a generic script to leverage xtightvncviewer to pivot to a VNC display through an SSH server.  This can be done on any SSH port."
	echo ""
	echo "If the VNC server is on the same system as the SSH server, use localhost for the destination VNC server IP.  This IP/name is from the perspective of the SSH server."
}

if [ $# -lt 5 ]; then
	ShowUsage
	exit 1
fi

SSHUSERNAME=$1
SSHSERVER=$2
SSHPORT=$3
VNCSERVER="$4"
VNCDISPLAYID=$5


xtightvncviewer -via "$SSHUSERNAME@$SSHSERVER -p $SSHPORT" $VNCSERVER:$VNCDISPLAYID

