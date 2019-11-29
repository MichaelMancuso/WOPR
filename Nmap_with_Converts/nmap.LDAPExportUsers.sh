#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <Output Base Name> <LDAP Server> <LDAP Domain Base> <Username> [password]"
	echo "$0 will query the specified LDAP server for the samaccountname and other fields for users."
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

# Get user accounts
echo "Getting all user accounts..." >&2
ldapsearch  -L -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=10000/noprompt -b "$LDAPDOMAIN" "(objectclass=user)" > $BASEDESCRIPTOR.ldif
echo "\"sAMAccountName\",\"displayName\",\"description\",\"distinguishedName\"" > $BASEDESCRIPTOR.csv
cat $BASEDESCRIPTOR.ldif | perl -p00e 's/\r?\n //g' | ldif-to-csv.sh sAMAccountName displayName description distinguishedName | grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.csv

# Get disabled accounts
echo "Getting disabled accounts..." >&2
ldapsearch  -L -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=10000/noprompt -b "$LDAPDOMAIN" "(&(objectclass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))" > $BASEDESCRIPTOR.disabled.ldif
echo "\"sAMAccountName\",\"displayName\",\"description\",\"distinguishedName\"" > $BASEDESCRIPTOR.disabled.csv
cat $BASEDESCRIPTOR.disabled.ldif | perl -p00e 's/\r?\n //g' | ldif-to-csv.sh sAMAccountName displayName description distinguishedName | grep -v '^""' | grep -v "{"  >> $BASEDESCRIPTOR.disabled.csv

echo "Building output files..." >&2
LDAPUSERS=`cat $BASEDESCRIPTOR.ldif | perl -p00e 's/\r?\n //g' | grep -Eio "CN=.*" | sort -u`

if [ -e $BASEDESCRIPTOR.users_and_groups.txt ]; then
	rm $BASEDESCRIPTOR.users_and_groups.txt
fi

IFS_BAK=$IFS
IFS="
"

for CURUSER in $LDAPUSERS
do
	LDAPUSERNAME=`echo "$CURUSER" | grep -Pio "^CN=.*?," | sed "s|CN=||g" | sed "s|,||g"`
	SAMACCOUNTNAME=`cat $BASEDESCRIPTOR.csv | grep "CN=$LDAPUSERNAME" | grep -Pio "^.*?," | sed "s|\"||g" | sed "s|,||g"`

	GROUPMEMBERS=`ldapsearch  -L -H ldap://$SERVER -x  -D "$USERNAME" -w "$PASSWORD" -E pr=1000/noprompt -b "$LDAPDOMAIN" "(&(objectCategory=group)(member=$CURUSER))" sAMAccountName 2>/dev/null | ldif-to-csv.sh sAMAccountName | sed "s|\"||g" | grep -v "^$" | sort -u`
	
	echo "$SAMACCOUNTNAME ($CURUSER)" >> $BASEDESCRIPTOR.users_and_groups.txt
	for CURGROUP in $GROUPMEMBERS
	do
		echo -e "\t$CURGROUP" >> $BASEDESCRIPTOR.users_and_groups.txt
	done
done

# Now determine account status and update csv
#mv $BASEDESCRIPTOR.csv $BASEDESCRIPTOR.tmp

#echo "\"sAMAccountName\",\"displayName\",\"description\",\"distinguishedName\",\"Status\"" > $BASEDESCRIPTOR.csv

#USERFILE=`cat $BASEDESCRIPTOR.tmp | grep -v "^\"sAMAccountName"`

#for CURENTRY in $USERFILE
#do
#	USERDN=`echo "$CURENTRY" | grep -Pio "\"CN=.*" | sed "s|CN=||g" | sed "s|\"||g"`
#	echo "$CURENTRY" | grep -q "$USERDN"
#	if [ $? -eq 0 ]; then
#		STATUS="Disabled"
#	else
#		STATUS="Enabled"
#	fi
#
#	echo -e "$CURENTRY,\"$STATUS\"" >> $BASEDESCRIPTOR.csv
#done

IFS=$IFS_BAK
IFS_BAK=

echo "[`date`] Done." >&2

echo ""
cat $BASEDESCRIPTOR.csv

