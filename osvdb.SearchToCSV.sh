#!/bin/sh

ShowUsage() {
	echo "Usage: $0 <query string> <cookie file> [--help]"
	echo ""
	echo "$0 will take the specified query string, search the osvdb,"
	echo "and produce a CSV-formatted output."
	echo ""
	echo "Because OSVDB has decided to use CloudFlare DDoS services, you now have to first visit OSVDB in Firefox.  Then use Firebox to export cookies to a file and pass that cookie file to this script."
	echo ""
	echo "Note that query string should be formatted in URL format where"
	echo "spaces are replaced with + such as Search+for+this."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

QueryString="$1"
COOKIEFILE="$2"

if [ ! -e $COOKIEFILE ]; then
	echo "ERROR: Unable to find $COOKIEFILE."
	exit 2
fi

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	esac
done

QueryString=`echo "$QueryString" | sed "s| |+|g"`
FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"
USERAGENTSTRING="$FIREFOXUSERAGENTSTRING"
OSVDBIDRESULT=`wget --cookies=on --load-cookies=$COOKIEFILE --keep-session-cookies -O - -U "$USERAGENTSTRING" "http://osvdb.org/search/search?search[vuln_title]=$QueryString&search[text_type]=titles&search[refid]=&search[referencetypes]=&kthx=search" 2>/dev/null`

OSVDBIDRESULT=`echo "$OSVDBIDRESULT" | tr '\n' ' ' | tr '\r' ' '`
OSVDBIDS=`echo "$OSVDBIDRESULT" | grep -Eio "\/show\/osvdb\/[0-9]{1,7}" | sed "s|\/show\/osvdb\/||g" | sort -nu`

echo "Date, Vuln Id (OSVDB), Risk Level, Vulnerability, Observation, Remediation"

for OSVDBID in $OSVDBIDS
do
	OSVDBPAGE=`wget --cookies=on --load-cookies=$COOKIEFILE --keep-session-cookies -O - -U "$USERAGENTSTRING" http://osvdb.org/show/osvdb/$OSVDBID 2>/dev/null`

	CVSSSCORE=""
	CVSSSCORE=`echo "$OSVDBPAGE" | grep -Pio "CVSSv2 Base Score = [0-9]{1,2}\.[0-9]{1,2}" | grep -Pio "[0-9]{1,2}\.[0-9]{1,2}"`

	DATESTR=`echo "$OSVDBPAGE"  | tr '\n' ' ' | tr '\r' ' ' |  grep -Pio "Disclosure Date.*?[0-9]{4,4}-[0-9]{1,2}-[0-9]{1,2}" | grep -Pio "[0-9]{4,4}-[0-9]{1,2}-[0-9]{1,2}"`
	TITLE=`echo "$OSVDBPAGE"  | tr '\n' ' ' | tr '\r' ' ' | grep -Pio "\<title\>.*?\<\/title\>" | perl -pe "s|\<title\>[0-9]{1,7}: ||" | perl -pe "s|\<\/title\>||"`

	DESCR=`echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | sed "s|.*Description<\/h1><\/td>||" | sed "s|<\/td>.*||" | perl -pe "s|^.*?>||" | sed "s|  ||g" | sed "s|  ||g" | sed "s|^ ||"`	
	DESCR=`echo "$DESCR" | sed "s|\"||g" | sed "s|<em style='font-weight:bold;'>.||g" | sed "s|)<\/em> ||g" | sed "s|<a href=||g" | sed "s|</a>||g" | sed "s|<br\/>||g" | perl -pe "s|target=.*?>||" | sed "s|&quot;|\"|g"`
	
	echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | grep -E "Solution<\/h1><\/td>" > /dev/null
	
	if [ $? -eq 0 ]; then
		SOL=`echo "$OSVDBPAGE" | tr '\n' ' ' | tr '\r' ' ' | sed "s|.*Solution<\/h1><\/td>||" | sed "s|<\/td>.*||" | perl -pe "s|^.*?>||" | sed "s|  ||g" | sed "s|  ||g" | sed "s|^ ||"`	
		SOL=`echo "$SOL" | sed "s|\"||g" | sed "s|<em style='font-weight:bold;'>.||g" | sed "s|)<\/em> ||g" | sed "s|<a href=||g" | sed "s|</a>||g" | sed "s|<br\/>||g" | perl -pe "s|target=.*?>||" | sed "s|&quot;|\"|g"`
	else
		SOL=""
	fi
	
	RISK="-1"
	
	if [ ${#CVSSSCORE} -gt 0 ]; then
		PRIMARYSCORE=`echo "$CVSSSCORE" | sed "s|\..*||"`
	
		# Vulnerabilities are labeled Low severity if they have a CVSS base score of 0.0-3.9.
		# Vulnerabilities will be labeled Medium severity if they have a base CVSS score of 4.0-6.9.
		# Vulnerabilities will be labeled High severity if they have a CVSS base score of 7.0-10.0.
	
		if [ ${#PRIMARYSCORE} -gt 0 ]; then					
			if [ $PRIMARYSCORE -lt 4 ]; then
				RISK=2
			else
				if [ $PRIMARYSCORE -lt 7 ]; then
					RISK=3
				else
					RISK=4
				fi
			fi
		fi
	fi

	echo \"$DATESTR\",\"$OSVDBID\",\"$RISK\",\"$TITLE\",\"$DESCR\",\"$SOL\"
done


