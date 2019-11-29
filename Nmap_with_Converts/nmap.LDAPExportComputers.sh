#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Output Base Name> <LDAP Server> <LDAP Domain Base> <Username> [password]"
	echo "$0 will query the specified LDAP server for all computers and OS types."
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

ldapsearch  -L -H ldap://$SERVER -x -D "$USERNAME" -w "$PASSWORD" -E pr=10000/noprompt -b "$LDAPDOMAIN" "(objectclass=computer)" name operatingSystem operatingSystemVersion > $BASEDESCRIPTOR.ldif

echo "\"Computer Name\",\"Operating System\",\"OS Version\",\"IP Address\",\"Status\"" > $BASEDESCRIPTOR.csv
cat $BASEDESCRIPTOR.ldif | ldif-to-csv.sh name operatingSystem operatingSystemVersion | grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.tmp

# Now check if they're online
COMPUTERFILE=`cat $BASEDESCRIPTOR.tmp`

IFS_BAK=$IFS
IFS="
"

echo "Validating if computers are online..." >&2

for CURLINE in $COMPUTERFILE
do
	COMPUTERNAME=`echo "$CURLINE" | grep -Pio "^.*?," | sed "s|\"||g" | sed "s|,||g"`

	IPADDR=`dns.lookup.name.sh $COMPUTERNAME 2>/dev/null`

	echo "$IPADDR" | grep -q "Could not find"

	if [ $? -ne 0 ]; then
		# Found name
		IPADDR=`echo "$IPADDR" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
		
		if [ ${#IPADDR} -gt 0 ]; then
			ping -c 1 -W 1 $IPADDR > /dev/null

			if [ $? -eq 0 ]; then
				STATUS="Online"
			else
				STATUS="Unavailable"
			fi
		else
			IPADDR="Unavailable"
			STATUS="Unavailable"
		fi
	else
		IPADDR="Unavailable"
		STATUS="Unavailable"
	fi

	echo "$CURLINE,\"$IPADDR\",\"$STATUS\"" >> $BASEDESCRIPTOR.csv
done

IFS=$IFS_BAK
IFS_BAK=

rm $BASEDESCRIPTOR.tmp

echo ""
cat $BASEDESCRIPTOR.csv

