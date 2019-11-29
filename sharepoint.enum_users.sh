#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <site base URL>"
	echo "<base URL> something like https://www.mysite.com"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

USERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"

BASEURL="$1"

echo "[`date`] Scanning $BASEURL..."
for CURID in {1..200}
do
	wget -nv -O- --user-agent="$USERAGENTSTRING" $BASEURL/_layouts/UserDisp.aspx?ID=$CURID 2>/dev/null 

	if [ $? -eq 0 ]; then
		echo "Found: Access to $BASEURL/_layouts/UserDisp.aspx?ID=$CURID is available!"
	fi
done

echo "[`date`] Done."

