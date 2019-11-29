#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <linked in logged in session cookie file> <base page url> [max entries]"
	echo "Process: Log in to linkedin in your browser and do your search.  Then use Firebug to export cookies for the site to a file.  (that will be your cookies.txt file).  Then Copy the URL for one of the pages at the bottom (less the page_num= part) and pass that as the base URL."
	echo "[Max Entries] can be specified to align with your LinkedIn account.  Here's the settings from LinkedIn:"
	echo "Standard Account - Up to 100 Entries (default)"
	echo "Business Account - Up to 300 Entries"
	echo "Business+ Account - Up to 500 Entries"
	echo "Executive Account - Up to 700 Entries"
	echo ""
	echo "It really helps to get your search tuned in the LinkedIn portal first before copying the link to optimize the results."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

COOKIEFILE="$1"
BASEURL="$2"
#BASEURL="https://www.linkedin.com/vsearch/p?keywords=accolade%2C+inc&openFacets=N%2CG%2CCC&f_G=us%3A77&f_CC=579052"
FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"

IFS_BAK=$IFS
IFS="
"

if [ $# -ge 3 ]; then
	MAXENTRIES=$3
else
	MAXENTRIES=100
fi

MAXRANGE=$(($MAXENTRIES / 10))

LINKEDINRESULTS=`wget --user-agent="$USERAGENTSTRING" -O /tmp/linkedin.tmp --load-cookies $COOKIEFILE --save-cookies $COOKIEFILE --keep-session-cookies -nv "$BASEURL&page_num=1" 2>/dev/null`
SRCHTOTAL=`cat /tmp/linkedin.tmp | grep -Pio "srchtotal=[0-9]{1,}" | head -1 | sed "s|srchtotal=||"`

echo "Extracting first 100 of $SRCHTOTAL entries... (Note a personal account can only handle 100 entries, business 300, business+ 500, Exec 700 so you may not get them all.)" >&2

echo "Name	Company	Title"

PAGERANGE=`seq $MAXRANGE`

for i in $PAGERANGE
do
#	echo "Requesting page $BASEURL&page_num=$i..."
	LINKEDINRESULTS=`wget --user-agent="$USERAGENTSTRING" -O /tmp/linkedin.tmp --load-cookies $COOKIEFILE --save-cookies $COOKIEFILE --keep-session-cookies -nv "$BASEURL&page_num=$i" 2>/dev/null`

	if [ -e /tmp/linkedin.tmp ]; then
#		NAMES=`cat /tmp/linkedin.tmp | grep -Pio "fmt_name.:.*?," | sed "s|fmt_name.:.||g" | sed "s|.,||g"`
		TMPLINES=`cat /tmp/linkedin.tmp | grep -Pio "fmt_headline.*?fmt_name.:.*?,"`
		
		for CUR_LINE in $TMPLINES
		do
			CURNAME=`echo "$CUR_LINE" | grep -Pio "fmt_name.:.*?," | sed "s|fmt_name.:.||g" | sed "s|.,||g"`
			COMPANY=`echo "$CUR_LINE" | grep -Pio " at .*?\"," | head -1  | sed 's|&amp;|\&|g' | sed 's|.u002d|-|g' | sed 's|.u003cstrong class=..highlight...u003e||g' | sed 's|.u003c.strong.u003e||g' | sed "s| at ||" | sed "s|\",||" | sed 's|\\u003cB\\u003e||' | sed 's|\\u003c\/B\\u003e||'`

			PERSONTITLE=`echo "$CUR_LINE" | grep -Pio "fmt_headline.:.*? at " | sed "s|fmt_headline.:.||" | sed 's|&amp;|\&|g' | sed 's|.u002d|-|g' | sed 's|.u003cstrong class=..highlight...u003e||g' | sed 's|.u003c.strong.u003e||g'`
			PERSONTITLE=`echo "$PERSONTITLE" | grep -Pio ".*? at " | head -1 | sed 's| at .*$||g'`

			echo "$CURNAME	$COMPANY	$PERSONTITLE"
		done

		if [ -e /tmp/linkedin.tmp ]; then
			rm /tmp/linkedin.tmp
		fi
#		echo "$NAMES"
	else
		echo "ERROR: can't find temporary web content file."
	fi

done

if [ -e /tmp/linkedin.tmp ]; then
	rm /tmp/linkedin.tmp
fi

IFS=$IFS_BAK
IFS_BAK=

