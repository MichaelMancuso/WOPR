#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <user@server> <proxy ip or name> <proxy port> <external ssh server IP or name> <external ssh server port>"
	echo "$0 uses SSH and 'corkscrew' to use an HTTP proxy and establish an outbound SSH tunnel..."
	echo "that also creates a local proxy listener.  This can be used for firewall and proxy evasion."
	echo ""
}

if [ $# -lt 5 ]; then
	ShowUsage
	exit 1
fi

SSHLOGIN="$1"
PROXYHOST="$2"
PROXYPORT=$3
EXTERNALSSHSERVERHOST="$4"
EXTERNALSSHSERVERPORT=$5

LOCALPORT=8443

ssh -ND $LOCALPORT user@server -o "ProxyCommand corkscrew $PROXYHOST $PROXYPORT $EXTERNALSSHSERVERHOST $EXTERNALSSHSERVERPORT"
