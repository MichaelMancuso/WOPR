#!/bin/sh
ShowUsage() {
	echo "Usage: $0 <ntp server>"
	echo ""
	echo "$0 will query the specified NTP server for its configured peers."
	echo ""
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

NTPSERVER=$1

ntpq -p -n $NTPSERVER
