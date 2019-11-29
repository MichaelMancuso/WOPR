#!/bin/bash
TRACKINGFILE="/opt/iptracking/mypublicip.txt"

if [ ! -e /opt/iptracking ]; then
	mkdir /opt/iptracking
fi

# Email settings:
SMTPSERVER="smtp.gmail.com"
# Use 587 for authenticated GMAIL
SMTPPORT=587
# Set AUTHACCOUNT to "" to not use authentication
AUTHACCOUNT="some.user@gmail.com"
AUTHPASSWORD="somepass"
FROMADDRESS="some.user@gmail.com"
TOADDRESS="some.user@gmail.com"
SUBJECT="IP Change: A monitored network's public IP has changed"

MYIP=`ip.mypublicip.sh | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
NOTIFY=0

if [ ${#MYIP} -gt 0 ]; then
	if [ -e $TRACKINGFILE ]; then
		OLDIP=`cat $TRACKINGFILE | grep -v "^$" | grep -v "^#" | head -1 | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
		
		IPSMATCH=`echo "$OLDIP" | grep "^$MYIP$" | wc -l`

		if [ $IPSMATCH -eq 0 ]; then
			echo "[`date`] IP Change! Old IP: $OLDIP, New IP: $MYIP"
			# Alert
			NOTIFY=1
			# Save new IP
			echo "$MYIP" > $TRACKINGFILE
		fi
	else
		echo "[`date`] No previously recorded IP.  Recording current IP ($MYIP) to tracking file."
		echo "$MYIP" > $TRACKINGFILE
	fi
	
	if [ $NOTIFY -eq 1 ]; then
		DATESTR=`date`
		MSGBODY=`echo "<HTML><BODY>Event Time: $DATESTR<BR>Old IP Address: $OLDIP<BR>New IP Address: $MYIP<BR></BODY></HTML>"`

		if [ ${#AUTHACCOUNT} -gt 0 ]; then
				smtp-cli --host=$SMTPSERVER --port=$SMTPPORT --auth --user=$AUTHACCOUNT --pass=$AUTHPASSWORD --from=$FROMADDRESS --to=$TOADDRESS --subject="$SUBJECT" --body-html="$MSGBODY"
		else
				smtp-cli --host=$SMTPSERVER --port=$SMTPPORT --from=$FROMADDRESS --to=$TOADDRESS --subject="$SUBJECT" --body-html="$MSGBODY"
		fi
	fi
else
	echo "[`date`] ERROR retrieving curent public IP."
fi
