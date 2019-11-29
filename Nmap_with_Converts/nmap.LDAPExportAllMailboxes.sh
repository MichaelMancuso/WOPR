#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Output Base Name> <LDAP Server> <LDAP Domain Base> <Username> [password]"
	echo "$0 will query the specified LDAP server for the samaccountname and email (mail) fields for users."
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

ldapsearch  -L -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=1000/noprompt -b "$LDAPDOMAIN" "(&(objectclass=user)(mail=*))" samaccountname mail > $BASEDESCRIPTOR.ldif

echo "\"sAMAccountName\",\"EMail\"" > $BASEDESCRIPTOR.csv
cat $BASEDESCRIPTOR.ldif | ldif-to-csv.sh sAMAccountName mail | grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.csv

echo ""
cat $BASEDESCRIPTOR.csv

