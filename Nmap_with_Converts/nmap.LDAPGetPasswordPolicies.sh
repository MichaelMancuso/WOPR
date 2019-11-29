#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Output Base Name> <LDAP Server> <LDAP Domain Base> <Username> [password]"
	echo "$0 will query the specified LDAP server for the root password policy."
	echo "<Output base name> Used for the LDIF and CSV outputs"
	echo "<LDAP Server> can be IP or name (e.g. dc1.mydomain.com)"
	echo "<LDAP Domain Base> LDAP format: dc=mydomain,dc=com"
	echo "<username> can be MYDOMAIN\\\\Username"
	echo "[Password] If not supplied you will be prompted."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

BASEDESCRIPTOR="$1"
SERVER="$2"
LDAPDOMAIN="$3"
USERNAME="$4"

if [ $# -gt 4 ]; then
	HASPASSWORD=1
	PASSWORD="$5"
else
	echo -n "Password: "
	read -s PASSWORD
fi

ldapsearch -L -H ldap://$SERVER -x -D "$USERNAME" -w "$PASSWORD" -E pr=10000/noprompt -s base -b "$LDAPDOMAIN" "(objectclass=*)" > $BASEDESCRIPTOR.ldif

LDIFFILESIZE=`cat $BASEDESCRIPTOR.ldif | wc -l`

if [ $LDIFFILESIZE -eq 0 ]; then
	exit 1
fi

echo "\"Domain SMB Name\",\"minPwdLength\",\"lockoutThreshold (min)\",\"lockoutDuration (min)\",\"minPwdAge (days)\",\"maxPwdAge (days)\",pwdHistoryLength,forceLogoff" > $BASEDESCRIPTOR.csv

# Number fields are netative nano-second intervals.  Drop the negative, drop last 7 zeros, divide by 60 = minutes 
cat $BASEDESCRIPTOR.ldif | perl -p00e 's/\r?\n //g' | ldif-to-csv.sh name minPwdLength lockoutThreshold lockoutDuration minPwdAge maxPwdAge pwdHistoryLength forceLogoff| grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.csv

# Fix lockout duration
RAWDURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f4 | tail -1 | sed "s|\"||g"`
DURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f4 | sed "s|-||" | tail -1 | sed "s|\"||g"`
DURATIONMIN=$((DURATION/600000000))
sed -i "s|\"$RAWDURATION\"|\"$DURATIONMIN\"|" $BASEDESCRIPTOR.csv
# Fix min pwd age
RAWDURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f5 | tail -1 | sed "s|\"||g"`
DURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f5 | sed "s|-||" | tail -1 | sed "s|\"||g"`
DURATIONMIN=$((DURATION/600000000/60/24))
sed -i "s|\"$RAWDURATION\"|\"$DURATIONMIN\"|" $BASEDESCRIPTOR.csv
# Fix max pwd age
RAWDURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f6 | tail -1 | sed "s|\"||g"`
DURATION=`cat $BASEDESCRIPTOR.csv | cut -d',' -f6 | tail -1 | sed "s|-||" | sed "s|\"||g"`
DURATIONMIN=$((DURATION/600000000/60/24))
sed -i "s|\"$RAWDURATION\"|\"$DURATIONMIN\"|" $BASEDESCRIPTOR.csv

echo ""
cat $BASEDESCRIPTOR.csv

