#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <domain name> <output file name>"
	echo "$0 uses 'theharvester' to scan search engines for information about the domain and write findings to the specified output base name as an html file."
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

DOMAINNAME="$1"
BASENAME="$2"

theharvester -d $DOMAINNAME -b all -f $BASENAME.html

