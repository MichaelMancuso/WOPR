#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <site base URL> [-v]"
	echo "<base URL> something like https://www.mysite.com"
	echo "[-v] Optional for verbose output."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BASEURL="$1"
BEVERBOSE=0

if [ $# -gt 1 ]; then
	BEVERBOSE=1
fi

if [ ! -e /opt/sharepoint/SharePoint-UrlExtensions-18Mar2012.txt ]; then
	echo "ERROR: Unable to find /opt/sharepoint/SharePoint-UrlExtensions-18Mar2012.txt with URL list."
	exit 2
fi

USERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"

SHAREPOINTLINKS=`cat /opt/sharepoint/SharePoint-UrlExtensions-18Mar2012.txt | grep -v "^$" | sed "s|^\/||g"`

NUMLINKS=`echo "$SHAREPOINTLINKS" | wc -l`
echo "[`date`] Testing $BASEURL with $NUMLINKS links."

for CURLINK in $SHAREPOINTLINKS
do
	if [ $BEVERBOSE -eq 1 ]; then
		echo "Testing $BASEURL/$CURLINK"
	fi

	wget -nv -O- --user-agent="$USERAGENTSTRING" $BASEURL/$CURLINK 2>/dev/null 

	if [ $? -eq 0 ]; then
		echo "Found: Access to $BASEURL/$CURLINK is available!"
	fi
done

echo "[`date`] Done."

