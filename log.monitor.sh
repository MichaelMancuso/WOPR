#!/bin/bash

DEBUG=0
# Email settings:
SMTPSERVER="smtp.gmail.com"
# Use 587 for authenticated GMAIL
SMTPPORT=587
# Set AUTHACCOUNT to "" to not use authentication
AUTHACCOUNT="someuser@gmail.com"
AUTHPASSWORD="somepass"
FROMADDRESS="someuser@gmail.com"
TOADDRESS="somepass@gmail.com"
SUBJECT="AUTHALERT: `hostname` Authentication Failures Detected"

if [ ! -e /opt/logmonitor ]; then
	mkdir /opt/logmonitor
fi

ALERTTRACKINGFILE="/opt/logmonitor/alerttrackingfile.txt"
TMPALERTFILE="/tmp/log.monitor.alertdata.tmp"

AUTHFAILURES=`cat /var/log/auth.log | grep "authentication failure"`

if [ ${#AUTHFAILURES} -eq 0 ]; then
	exit 0
fi

if [ $DEBUG -gt 0 ]; then
	NUMENTRIES=`echo "$AUTHFAILURES" | wc -l`
	echo "Found $NUMENTRIES authentication failures in auth.log"
	echo "$AUTHFAILURES"
fi

LASTTIMESTAMP=""

if [ -e $ALERTTRACKINGFILE ]; then
	LASTTIMESTAMP=`cat $ALERTTRACKINGFILE | grep -Pio "201[2-9]\-[0-9]{1,2}\-[0-9]{1,2}\s[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}"`
	if [ $DEBUG -gt 0 ]; then
		echo "Last Timestamp: $LASTTIMESTAMP"
	fi
else
	if [ $DEBUG -gt 0 ]; then
		echo "No time tracking file found"
	fi
fi

IFS_BAK=$IFS
IFS="
"

if [ ${#LASTTIMESTAMP} -gt 0 ]; then
	# Found a timestamp
	if [ $DEBUG -gt 0 ]; then
		echo "Found timestamp in $ALERTTRACKINGFILE.  Processing."
	fi

	# Find all after timestamp

	LASTTIME_AS_SEC=`date --date="$LASTTIMESTAMP" +%s`
	echo "" > $TMPALERTFILE
	NEWALERTTIME="$LASTTIMESTAMP"

	for CURENTRY in $AUTHFAILURES
	do
		CURTIMESTAMP=`echo "$CURENTRY" | grep -Pio "^[a-zA-Z]{1,3} [0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}"`
		CURTIME_AS_SEC=`date --date="$CURTIMESTAMP" +%s`

		if [ $CURTIME_AS_SEC -gt $LASTTIME_AS_SEC ]; then
			echo "$CURENTRY" >> $TMPALERTFILE
			NEWALERTTIME=`date -d @$CURTIME_AS_SEC +"%Y-%m-%d %T"`

			if [ $DEBUG -gt 0 ]; then
				echo "Found a newer entry...."
				echo "$CURENTRY"
			fi
		else
			if [ $DEBUG -gt 0 ]; then
				echo "$CURTIME_AS_SEC is not > $LASTTIME_AS_SEC.  Continuing..."
			fi
		fi
	done

	echo "$NEWALERTTIME" > $ALERTTRACKINGFILE

	if [ -e $TMPALERTFILE ]; then
		ALERTDATA=`cat $TMPALERTFILE | grep -v "^$"`
	fi
else
	# No timestamp or no timestamp file
	# Use all entries
	ALERTDATA="$AUTHFAILURES"

	if [ $DEBUG -gt 0 ]; then
		echo "No timestamp entry found in $ALERTTRACKINGFILE.  Using all data...."
		echo "$ALERTDATA"
	fi

	# Write new timestamp
	CURTIMESTAMP=`echo "$AUTHFAILURES" | tail -1 |  grep -Pio "^[a-zA-Z]{1,3} [0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}"`
	CURTIME_AS_SEC=`date --date="$CURTIMESTAMP" +%s`
	NEWALERTTIME=`date -d @$CURTIME_AS_SEC +"%Y-%m-%d %T"`
	echo "$NEWALERTTIME" > $ALERTTRACKINGFILE
fi

if [ -e $TMPALERTFILE ]; then
	rm $TMPALERTFILE
fi

if [ ${#ALERTDATA} -gt 0 ]; then
	# Send email alert
	if [ $DEBUG -gt 0 ]; then
		NUMALERTS=`echo "$ALERTDATA" | wc -l`
		echo "$NUMALERTS authentication failures found.... sending notification."
	fi
	
	ALERTHTML=`echo "$ALERTDATA" | tr '\n' '~' | sed "s|~|<br>|g"`
	MSGBODY="<HTML><BODY>$ALERTHTML</BODY></HTML>"

	if [ $DEBUG -eq 1 ]; then
		echo "Sending '$MSGBODY' to $TOADDRESS"
	fi

	smtp-cli --host=$SMTPSERVER --port=$SMTPPORT --auth --user=$AUTHACCOUNT --pass=$AUTHPASSWORD --from=$FROMADDRESS --to=$TOADDRESS --subject="$SUBJECT" --body-html="$MSGBODY"
fi

IFS=$IFS_BAK
IFS_BAK=
