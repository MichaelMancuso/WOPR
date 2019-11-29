#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target IP"
	echo "$0 will scan the Microsoft SQL Server and use nmap's ms-sql-info script to display sql server and instance information."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGETIP=$1

nmap -Pn -n -p 1433,1434 --script=ms-sql-info $TARGETIP


