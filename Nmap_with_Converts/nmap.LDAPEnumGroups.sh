#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Output Base Name> <LDAP Server> <LDAP Domain Base> <Username> [password]"
	echo "$0 will query the specified LDAP server for all groups."
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

ldapsearch  -LLL -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=10000/noprompt -b "$LDAPDOMAIN" "(objectclass=group)" > $BASEDESCRIPTOR.ldif

echo "\"Computer Name\",\"Distinguished Name\"" > $BASEDESCRIPTOR.csv
cat $BASEDESCRIPTOR.ldif | perl -p00e 's/\r?\n //g' | ldif-to-csv.sh sAMAccountName distinguishedName | grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.csv

# There's an issue with long lines that the perl pipe addresses
LDAPGROUPS=`cat $BASEDESCRIPTOR.ldif | perl -p00e 's/\r?\n //g' | grep -Eio "CN=.*" | sort -u`

if [ -e $BASEDESCRIPTOR.groups_and_users.txt ]; then
	rm $BASEDESCRIPTOR.groups_and_users.txt
fi

IFS_BAK=$IFS
IFS="
"

for CURGROUP in $LDAPGROUPS
do
	GROUPNAME=`echo "$CURGROUP" | grep -Pio "^CN=.*?," | sed "s|CN=||g" | sed "s|,||g"`
	SAMACCOUNTNAME=`cat $BASEDESCRIPTOR.csv | grep "CN=$GROUPNAME" | grep -Pio "^.*?," | sed "s|\"||g" | sed "s|,||g"`

	GROUPMEMBERS=`ldapsearch  -L -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=1000/noprompt -b "$LDAPDOMAIN" "(&(objectCategory=user)(memberOf=$CURGROUP))" sAMAccountName | ldif-to-csv.sh sAMAccountName | sed "s|\"||g" | grep -v "^$" | sort -u`
	
	echo "$SAMACCOUNTNAME ($CURGROUP)" >> $BASEDESCRIPTOR.groups_and_users.txt
	for CURUSER in $GROUPMEMBERS
	do
		echo -e "\t$CURUSER" >> $BASEDESCRIPTOR.groups_and_users.txt
	done
done

IFS=$IFS_BAK
IFS_BAK=

echo ""
cat $BASEDESCRIPTOR.groups_and_users.txt

