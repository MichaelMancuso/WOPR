#!/bin/sh

ShowUsage() {
	echo "Usage: $0"
	echo ""
	echo "$0 will read /usr/local/var/log/radius/freeradius-server-wpe.log"
	echo "and extract usernames and passwords to standard NT file format:"
	echo "USERNAME:::response::challenge"
	echo ""
}

if [ $# -gt 0 -a "$1" = "--help" ]; then
	ShowUsage
	exit 1
fi

LOGFILE="/usr/local/var/log/radius/freeradius-server-wpe.log"

if [ ! -e $LOGFILE ]; then
	echo "ERROR: Unable to find $LOGFILE"
	exit 2
fi

RESULTS=`cat $LOGFILE | grep -e "username" -e "challenge" -e "response"	| sed 's|^.*username: ||g' | sed 's|^.*challenge: |::|g' | sed 's|^.*response: |:::|g' | sed 's|^.*\\\||g'`

FULLLINE=""
FIRSTTIME=0
USERNAME=""
CHALLENGE=""
RESPONSE=""

for CURLINE in $RESULTS
do
	echo "$CURLINE" | grep -E "^:" > /dev/null

	if [ $? -gt 0 ];  then
		# New username
		
		if [ ${#CURLINE} -gt 0 ]; then
			USERNAME="$CURLINE"
		else
			USERNAME=""
		fi
	else
		echo "$CURLINE" | grep -E ":::" > /dev/null
	
		if [ $? -eq 0 ]; then
			# Have a response
			RESPONSE=`echo "$CURLINE" | sed "s|:||g"`

			# Response is the 3rd entry so write the string
			FULLLINE=`echo "$USERNAME:::$RESPONSE::$CHALLENGE"`
			echo "$FULLLINE"
		else
			# Have a challenge
			CHALLENGE=`echo "$CURLINE" | sed "s|:||g"`
		fi
	fi
done

