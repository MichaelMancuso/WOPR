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

METASPLOIT=1
which msfconsole > /dev/null

if [ $? -eq 0 ]; then
	# found it in the path
	MSFCMD=`which msfconsole`
else
	echo "ERROR: Unable to find msfconsole"
	exit 1
fi


if [ $METASPLOIT -eq 0 -a $FINDEMAIL -eq 1 ]; then
	# Enabled or not, if not present, disable.
	echo "Unable to locate msfconsole.  Disabling Metasploit-based email lookup..."
	METASPLOIT=0
	FINDEMAIL=0
fi

DOMAINS=`cat $DOMAINFILE | sed "s|\r||g" | grep -v "^$"`
NUMDOMAINS=`echo "$DOMAINS" | grep -v "^$" | wc -l`

echo "Mapping $NUMDOMAINS domain(s)... [`date`] "

for CURDOMAIN in $DOMAINS
do
	echo "      $CURDOMAIN [`date`] "
	EMAILFILE=`echo email_addresses.$CURDOMAIN.txt`

	$MSFCMD -x "use auxiliary/gather/search_email_collector; set DOMAIN $CURDOMAIN; set OUTFILE $EMAILFILE; exploit; exit" >> /dev/null
done

echo "Done [`date`]"

