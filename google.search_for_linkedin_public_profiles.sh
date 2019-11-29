#!/bin/bash

DEBUG=0

ShowUsage() {
	echo "Usage: $0 <Company search name>"
	echo "$0 will query Google and extract all links related to LinkedIn public profiles for the specified company."
	echo "Note: Test the company search on LinkedIn first."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

SEARCHDOMAIN="$1"

# Delay between google page loads to try to avoid them thinking it's an automated scan :)
SLEEPDELAY="10s"

# Set up user agent string and Google query string
FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"
IPADUSERAGENTSTRING="Mozilla/5.0 (iPad; U; CPU iPad OS 5_0_1 like Mac OS X; en-us) AppleWebKit/535.1+ (KHTML like Gecko) Version/7.2.0.0 Safari/6533.18.5"
#USERAGENTSTRING="$IPADUSERAGENTSTRING"
USERAGENTSTRING="$FIREFOXUSERAGENTSTRING"
# GOOGLEURL="http://www.google.com/search?q=site:sitetoken&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a&num=50"
# GOOGLEURL="https://www.google.com/#filter=0search?q=site:sitetoken&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a&num=50"
#GOOGLEURL="https://www.google.com/search?num=50&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&noj=1&site=webhp&source=hp&q=site:sitetoken&oq=site:sitetoken"
GOOGLEURL="https://www.google.com/search?num=50&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&noj=1&site=webhp&source=hp&q=\"$SEARCHDOMAIN\"+site:linkedin.com%2Fpub"

# Make initial request which will tell us the approximate number of results that we'll need to go through

if [ $DEBUG -eq 1 ]; then
	echo "Searching with: $GOOGLEURL"
fi

# SEARCHRESULTS=`wget -nv -O- --user-agent="$USERAGENTSTRING" "$GOOGLEURL"`
TMPFILE=`echo "/tmp/$SEARCHDOMAIN.google.tmp" | sed "s| ||g"`

wget -nv -O- --user-agent="$USERAGENTSTRING" "$GOOGLEURL" > $TMPFILE

if [ $DEBUG -eq 1 ]; then
#	echo "$SEARCHRESULTS" > search_results.htm
	echo "SEARCH RESULTS"
	echo "$SEARCHRESULTS"
fi

if [ ! -e $TMPFILE ]; then
	echo "WARNING: No results found."
	exit 0
fi

# NUMRESULTS=`echo "$SEARCHRESULTS" 2>/dev/null | grep -Pio "resultStats.>.*? results" | sed "s|resultStats.>||" | sed "s|,||" | grep -Eio "[0-9]{1,}"`
NUMRESULTS=`cat $TMPFILE | grep -Pio "resultStats.>.*? results" | sed "s|resultStats.>||" | sed "s|,||" | grep -Eio "[0-9]{1,}" | head -1`

echo "Number of search results for $SEARCHDOMAIN: $NUMRESULTS"
echo "Number of search results for $SEARCHDOMAIN: $NUMRESULTS" 1>&2

if [ ${#NUMRESULTS} -eq 0 ]; then
	echo "WARNING: No results found."
	exit 0
fi

if [ $NUMRESULTS -gt 3000 ]; then
	NUMRESULTS=3000
	echo "INFO: More than 3000 results.  Capping at the first 3,000 findings..."
	echo "INFO: More than 3000 results.  Capping at the first 3,000 findings..." 1>&2
fi

# at 50 findings/page figure out how many google pages that is
NUMPAGES=`echo "$(($NUMRESULTS/50))"`

INTRESULTS=`echo "$((50*$NUMPAGES))"`

if [ $INTRESULTS -lt $NUMRESULTS ]; then
	NUMPAGES=$(($NUMPAGES+1))
fi

# print out the first set we already have
# PAGELINKS=`cat $TMPFILE | grep -Pio "<cite.*?>.*?</cite>" | grep -v "search\?q=site" | grep "$SEARCHDOMAIN" | grep -Pio ">.*?$SEARCHDOMAIN.*?<" | sed "s|[<>]||g" | grep -v "q=cache" | sed "s|\"$||g"`
PAGELINKS=`cat $TMPFILE | grep -Pio "<a href=\".*?\"" | sed "s|<a href=||g" | sed "s|\"||g" | grep -i "^http" | grep "$SEARCHDOMAIN"`

if [ $DEBUG -eq 1 ]; then
	echo "Extracted page links from the first results page:"
	echo "$PAGELINKS"
fi

# cycle through
if [ $NUMPAGES -gt 1 ]; then
	# Take one off the top end since we already have the first block (index 0)
	NUMPAGES=$(($NUMPAGES-1))
	for ((i=1; i<=$NUMPAGES; i++))
	do
		STARTLOC=$((50*i))
		# put in a small sleep delay so Google doesn't get too upset and flag us
		sleep $SLEEPDELAY
		# now get more results
#		SEARCHRESULTS=`wget -nv -O- --user-agent="$USERAGENTSTRING" "$GOOGLEURL&start=$STARTLOC"`
		wget -nv -O- --user-agent="$USERAGENTSTRING" "$GOOGLEURL&start=$STARTLOC" > $TMPFILE
#		PAGELINKSTMP=`cat $TMPFILE | grep -Pio "<cite.*?>.*?</cite>" | grep -v "search\?q=site" | grep "$SEARCHDOMAIN" | grep -Pio ">.*?$SEARCHDOMAIN.*?<" | sed "s|[<>]||g" | grep -v "q=cache" | sed "s|\"$||g"`
		PAGELINKSTMP=`cat $TMPFILE | grep -Pio "<a href=\".*?\"" | sed "s|<a href=||g" | sed "s|\"||g" | grep -i "^http" | grep "$SEARCHDOMAIN"`
		PAGELINKS=`echo "$PAGELINKS" && echo "$PAGELINKSTMP"`
	done
fi

if [ $DEBUG -eq 0 ]; then
	if [ -e $TMPFILE ]; then
		rm $TMPFILE
	fi
fi

echo "$PAGELINKS" | sort -u

echo ""

