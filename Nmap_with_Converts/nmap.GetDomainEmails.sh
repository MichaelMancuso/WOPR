#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <domain name>"
	echo "$0 will use Metasploit to query Google, Bing, and Yahoo"
	echo "and extract any valid email addresses."
	echo ""
	echo "Output will be written to email_addresses.<domain>.txt"
	echo ""
	echo "Options:"
	echo "--help      Show usage."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

METASPLOIT=1
which msfconsole > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Unable to run msfconsole."
	exit 2
fi

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	*)
		DOMAIN=$i
	;;
	esac
done

echo "Looking up email addresses for $DOMAIN..."
msfconsole -x "use auxiliary/gather/search_email_collector; set DOMAIN $DOMAIN; set OUTFILE email_addresses.$DOMAIN.txt; exploit; exit"

