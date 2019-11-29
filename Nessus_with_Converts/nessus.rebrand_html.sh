#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Nessus html file>"
	echo "$0 will rebrand a Nessus html report with the Delta Risk style."
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HTMLFILE="$1"

sed -i "s|Nessus Scan Report|Delta Risk Scan Report|g" $HTMLFILE
sed -i "s|Nessus Report|Delta Risk Scan Report|g" $HTMLFILE

NEWLOGO=`cat /opt/nessus/ness-rest/scripts/delta_risk_logo.base64.txt | tr '\n' ' ' | sed "s| ||g"`

sed -i "s|base64,.*\"|base64,$NEWLOGO\" width=\"200\" height=\"111\" border=\"0\" |" $HTMLFILE
sed -i "s|background: #425363;|background: #d0103a;|" $HTMLFILE
sed -i "s|background: #053958;|background: #981e32;|" $HTMLFILE

