#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <shodan detail file> [--vulns-only]"
	echo "$0 will parse a saved shodan detail file for identified vulnerabilities"
	echo "If --vulns-only is provided, only vulnerabilities are displayed."
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

VULNSONLY=0

for i in $*
do
	case $i in
	--vulns-only)
		VULNSONLY=1
		;;
	*)
		DETAILFILE=$i
	;;
	esac
done


if [ ! -e $DETAILFILE ]; then
	echo "ERROR: Unable to find $DETAILFILE."
	exit 2
fi

DETAILS=`cat $DETAILFILE | grep "^{"`

IFS_BAK=$IFS
IFS="
"

if [ $VULNSONLY -eq 1 ]; then
		echo "Last Update, IP, Hostnames, Vulns"
fi

for DETAIL in $DETAILS
do
	if [ $VULNSONLY -eq 1 ]; then
		VULNS=`echo "$DETAIL" | jq ". | {last_update,ip_str,hostnames,vulns}"`
		echo "$VULNS" | grep -iq "vulns.: null"

		if [ $? -gt 0 ]; then
			echo "$VULNS" | tr ',\n' ' ' | tr '{' '\n' | sed "s|}||g" | sed "s|\"    \"|,|g" | sed "s|\"||g" | sed "s|last_update: ||g" | sed "s|ip_str: ||g" | sed "s|hostnames: ||g" | sed "s|vulns: |,|g" | sed 's|\[||g' | sed 's|\]||g' | sed "s| ||g"
		fi
	else
		echo "$DETAIL" | jq ". | {last_update,ip_str,hostnames,city,region_code,latitude,longitude,ports,vulns}"
	fi
done

if [ $VULNSONLY -eq 1 ]; then
	echo ""
fi

IFS=$IFS_BAK
IFS_BAK=

