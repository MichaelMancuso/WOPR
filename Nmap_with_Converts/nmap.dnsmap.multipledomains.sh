#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <dns file name>"
	echo ""
	echo "$0 will run nmap.dnsmap.sh --no-whois --noversion for each of the domains in the input file."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ "$1" = "--help" ]; then
	ShowUsage
	exit 1
fi

DOMAINFILE=$1

if [ ! -e $DOMAINFILE ]; then
	echo "ERROR: Unable to find $DOMAINFILE"
	exit 2
fi

DOMAINS=`cat $DOMAINFILE | sed "s|\r||g" | grep -v "^$"`
NUMDOMAINS=`echo "$DOMAINS" | grep -v "^$" | wc -l`

echo "Mapping $NUMDOMAINS domain(s)... [`date`] "

for CURDOMAIN in $DOMAINS
do
	echo "      $CURDOMAIN [`date`] "
	nmap.dnsmap.sh --no-whois --noversion $CURDOMAIN 1>/dev/null 2>/dev/null &
done

# Wait for all runs to finish
while [ `ps aux | grep "nmap.dnsmap.sh" | grep -v grep | wc -l` -gt 0 ]
do 
	sleep 2s
done

echo "[`date`] Postprocessing host files..."

for CURFILE in `ls -1 *.hosts.txt`
do 
	nmap.dns_hostfile_remove_clutter.sh $CURFILE
done

echo "Done [`date`]"

