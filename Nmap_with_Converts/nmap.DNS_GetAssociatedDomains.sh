#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <domain registrant name>"
	echo "$0 will Google search whois.domaintools.com for all domains including the specified registrant name."
	echo ""
	echo "Note: First look up a good domain at whois.domaintools.com/<domain name> and get the correct registrant name."
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"

REGISTRANTNAME=`echo "$1" | sed "s| |+|g"`
echo "[`date`] Searching for $REGISTRANTNAME..." >&2

SEARCHRESULTS=`wget -O- --user-agent="$USERAGENTSTRING" "https://www.google.com/search?q=%22Registrant+Organization:$REGISTRANTNAME%22+site:whois.domaintools.com+%22domain+name%22&num=100&client=firefox-a&hs=hwC&rls=org.mozilla:en-US:official&channel=sb&filter=0&biw=1424&bih=631" 2>/dev/null`
DOMAINLIST=`echo "$SEARCHRESULTS" | grep -Pio ">whois.domaintools.com.*?<\/cite>" | sed "s|>whois.domaintools.com\/||g" | sed "s|<\/cite>||g" | sort -u`
NUMDOMAINS=`echo "$DOMAINLIST" | wc -l`
echo "[`date`] $NUMDOMAINS domains found." >&2
echo "$DOMAINLIST"


