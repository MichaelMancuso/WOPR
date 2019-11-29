#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <target ip>"
	echo ""
	echo "$0 will scan the target ip for aggressive mode ('1 returned handshake' will indicate its presence)."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 0
fi

PARM_IS_IP=`echo "$1" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | wc -l`

if [ $PARM_IS_IP -eq 0 ]; then
	ShowUsage
	exit 0
fi

ike-scan --aggressive --multiline --id=test $1
