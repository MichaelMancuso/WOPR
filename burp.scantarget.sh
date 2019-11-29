#!/bin/bash

# Uses carbonator plugin to scan and produce html report
# java -jar -Xmx2g path/to/burp.jar http localhost 80 /folder

if [ $# -lt 3 ]; then
	echo "Usage: $0 <http | https> <host> <port>"
	exit 0
fi

JARFILE=`ls -t /opt/BurpSuitePro/burp | head -1 | grep -Eio ".*\.jar"`
java -jar -Djava.awt.headless=true -Xmx2g /opt/BurpSuitePro/burp/$JARFILE $1 $2 $3 /tmp/burpscan

