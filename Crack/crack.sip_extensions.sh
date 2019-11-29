#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target IP>"
	echo "$0 will try extensions 1000-2500 against a SIP listener (UDP/5060)"
	echo ""
	echo "Can also try svwar:"
	echo "svwar -e1000-2000 <target IP>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGETIP="$1"
STARTEXTENSION=1000
ENDEXTENSION=2500
nmap --script=sip-enum-users -sU -p 5060 --script-args 'sip-enum-users.padding=4, sip-enum-users.minext=$STARTEXTENSION,sip-enum-users.maxext=$ENDEXTENSION' $TARGETIP

