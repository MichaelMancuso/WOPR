#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target> <port(s)> [action]"
	echo "Where:"
	echo "Target	is the system to test"
	echo "Port(s)   is one or more (comma-separated list, no spaces) ports to check"
	echo "          Script monitoring will stop when any one of the specified ports becomes available"
	echo "action    Optional parameter specifying a command to execute when the port becomes available."
	echo "          The action should be enclosed in quotes if it contains spaces, etc. and quotes "
	echo "          or other special command-line characters should be escaped."
	echo ""
}

if [ $# -gt 1 ]; then
	TARGET=$1
	PORT=$2
else
	ShowUsage
	exit 1
fi

which nmap > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to find nmap."
	exit 1
fi

echo "[`date`] Monitoring $TARGET on TCP port $PORT..."
while (True)
do
	nmap -PN -p $PORT $TARGET | grep -iq "open"
	if [ $? -eq 0 ]; then
		echo "[`date`] $PORT on $TARGET is now available"
		
		if [ $# -gt 2 ]; then
			echo "[`date`] Executing $3..."
			$3
			echo "[`date`] Done."
		fi
		break
	else
		echo -n "."
		sleep 30s
	fi
done

