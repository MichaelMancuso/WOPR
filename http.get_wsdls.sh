#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <WSDL Link File>"
	echo "$0 will query each WSDL Link in the link file and save the contents to individual files in the local directory named based on the URL link."
	echo "WSDL File should have one link per line such as: "
	echo "https://ws.mydomain.com:8443/myservices/UtilityService?wsdl"
	echo ""
	echo "Note that the port number in the link is optional and only needs to be provided if it's on a non-standard port."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

WSDLLINKFILE="$1"

if [ ! -e $WSDLLINKFILE ]; then
	echo "ERROR: Unable to find the file $WSDLLINKFILE."
	exit 1
fi

LINKS=`cat $WSDLLINKFILE | grep -v "^$" | grep -v "^#"`

NUMLINKS=`echo "$LINKS" | wc -l`
echo "[`date`] Processing $NUMLINKS URLs..."

for CURLINK in $LINKS; do
	CURFILE=`echo "$CURLINK" | grep -Pio "\/.*?\?" | sed "s|.*\/||g" | sed "s|\?||g"`
	CURFILE=`echo "$CURFILE.wsdl"`
	
	echo "$CURLINK " | grep -iq "https"
	
	if [ $? -eq 0 ]; then
		wget --no-check-certificate -O $CURFILE $CURLINK
	else
		wget -O $CURFILE $CURLINK
	fi
done

echo "[`date`] Done"
