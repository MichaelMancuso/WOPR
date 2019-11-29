#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <URL> <Report File> [cookie string]"
	echo "Note: AFR reports can then be converted with /usr/share/arachni/bin/arachni_reporter to other formats"
	echo "Example: /usr/share/arachni/bin/arachni_reporter myscan.afr --report=html:outfile=my_report.html"
	echo "Note 2: If you can't find a report file, it could have ended up in /usr/share/arachni/bin"
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

URL="$1"
FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0"
USERAGENT="$FIREFOXUSERAGENTSTRING"
REPORTFILE="$2"

echo "$REPORTFILE" | grep -q "\/"

if [ $? -gt 0 ]; then
	CURDIR=`pwd`
	REPORTFILE=`echo "$CURDIR/$2"`
fi

echo "$PATH" | grep -q "\/usr\/share\/arachni"

if [ $? -gt 0 ]; then
	export PATH=$PATH:/usr/share/arachni/bin
fi

if [ $# -gt 2 ]; then
	COOKIESTRING="$3"
	arachni --report=$REPORTFILE --audit-links --audit-forms --audit-cookies --scope-exclude-pattern=logout --http-cookie-string="$COOKIESTRING" --http-user-agent="$USERAGENT" $URL
else
	arachni --report=$REPORTFILE --audit-links --audit-forms --audit-cookies --scope-exclude-pattern=logout --http-user-agent="$USERAGENT" $URL
fi

