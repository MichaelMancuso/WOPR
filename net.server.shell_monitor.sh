#!/bin/bash

LOGDIR="/var/log/net.server"
LOGFILE="/var/log/net.server/connection.log"
ALERTTRACKINGFILE="/var/log/net.server/alerttrackingfile.txt"
TMPALERTFILE="/tmp/net.server.alertdata.tmp"
DEBUG=0

if [ ! -e $LOGFILE ]; then
	echo "ERROR: Unable to find log file $LOGFILE"
	exit 2
fi

# Get logged storeInfo.rb requests
# Filter through strings to remove non-printables from hacking attempts
PHONEHOMES=`cat $LOGFILE | strings | grep -a "shell connected"`
# Filter out any of our own testing from alerting
PHONEHOMES=`echo "$PHONEHOMES" | grep -v ":AIS:"`

if [ ${#PHONEHOMES} -eq 0 ]; then
	exit 0
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

ALERTDATA=""

IFS_BAK=$IFS
IFS="
"

if [ ${#LASTTIMESTAMP} -gt 0 ]; then
	# Found a timestamp

	# Find all after timestamp

	
	LASTTIME_AS_SEC=`date --date="$LASTTIMESTAMP" +%s`
	echo "" > $TMPALERTFILE
	NEWALERTTIME="$LASTTIMESTAMP"

	for CURENTRY in $PHONEHOMES
	do
		CURTIMESTAMP=`echo "$CURENTRY" | grep -Pio "\[201[2-9]\-[0-9]{1,2}\-[0-9]{1,2}\s[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\]" | sed "s|\[||" | sed "s|\]||"`
		CURTIME_AS_SEC=`date --date="$CURTIMESTAMP" +%s`

		if [ $CURTIME_AS_SEC -gt $LASTTIME_AS_SEC ]; then
			echo "$CURENTRY" >> $TMPALERTFILE
			NEWALERTTIME="$CURTIMESTAMP"
		fi

	done

	echo "$NEWALERTTIME" > $ALERTTRACKINGFILE

	if [ -e $TMPALERTFILE ]; then
		ALERTDATA=`cat $TMPALERTFILE | grep -v "^$"`
	fi
else
	# No timestamp or no timestamp file
	# Use all entries
	ALERTDATA="$PHONEHOMES"

	if [ $DEBUG -gt 0 ]; then
		echo "No timestamp entry found in $ALERTTRACKINGFILE.  Using all data...."
		echo "$ALERTDATA"
	fi

	# Write new timestamp
	NEWALERTTIME=`echo "$PHONEHOMES" | tail -1 |  grep -Pio "\[201[2-9]\-[0-9]{1,2}\-[0-9]{1,2}\s[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\]" | sed "s|\[||" | sed "s|\]||"`
	echo "$NEWALERTTIME" > $ALERTTRACKINGFILE
fi

if [ -e $TMPALERTFILE ]; then
	rm $TMPALERTFILE
fi

if [ ${#ALERTDATA} -gt 0 ]; then
	# Send email alert
	NUMALERTS=`echo "$ALERTDATA" | wc -l`
	echo "$NUMALERTS new connections found.... sending notification."

	# read recipient list.
	if [ -e /opt/net.server/shell_notification_recipients.cfg ]; then
		# send notifications
		RECIPIENTLIST=`cat /opt/net.server/shell_notification_recipients.cfg | grep -v "^$"`

		for CURRECIPIENT in $RECIPIENTLIST
		do
			sendemail-full 172.22.14.11 remoteshell@wopr.alliedinfosecurity.com $CURRECIPIENT "Remote Shell Alert" "$ALERTDATA"
		done
	else
		echo "WARNING: No recipients configured in /opt/net.server/shell_notification_recipients.cfg"
	fi
fi

IFS=$IFS_BAK
IFS_BAK=

