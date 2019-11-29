#!/bin/bash

LOGDIR="/var/log/rubyServe"
LOGFILE="/var/log/rubyServe/log.txt"
ALERTTRACKINGFILE="/var/log/rubyServe/alerttrackingfile.txt"
TMPALERTFILE="/tmp/alertdata.tmp"
DEBUG=0

if [ ! -e $LOGFILE ]; then
	echo "ERROR: Unable to find log file $LOGFILE"
	exit 2
fi

# Get logged storeInfo.rb requests
# Filter through strings to remove non-printables from hacking attempts
PHONEHOMES=`cat $LOGFILE | strings | grep -a "storeInfo.rb"`
# Filter out any of our own testing from alerting
PHONEHOMES=`echo "$PHONEHOMES" | grep -v "domain=AIS\&"`

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
	echo "$NUMALERTS new alerts found.... sending notification."

	# read recipient list.
	if [ -e /opt/phishing/usb/usb_notification_recipients.cfg ]; then
		# send notifications
		RECIPIENTLIST=`cat /opt/phishing/usb/usb_notification_recipients.cfg | grep -v "^$"`

		for CURRECIPIENT in $RECIPIENTLIST
		do
			sendemail-full 172.22.14.11 usbphish@wopr.alliedinfosecurity.com $CURRECIPIENT "USB Phish Alert" "$ALERTDATA"
		done
	else
		echo "WARNING: No recipients configured in /opt/phishing/usb/usb_notification_recipients.cfg"
	fi
fi

