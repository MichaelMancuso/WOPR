#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <domain name> <output file>"
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi


DOMAIN=$1
EMAILFILE=$2

msfconsole -x "use auxiliary/gather/search_email_collector; set DOMAIN $DOMAIN; set OUTFILE $EMAILFILE; exploit; exit"

