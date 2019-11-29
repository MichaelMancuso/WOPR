#!/bin/bash

ShowUsage() {
	echo "$0 <username> <password> <target> [output file descriptor]"
	echo "$0 will query the target LDAP server for computers and SAMAccountNames"
}


echo "This script still needs work for the ldap authentication." 
exit 2

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

USERNAME="$1"
PASSWORD="$2"
TARGET="$3"

if [ $# -gt 4 ]; then
	OUTPUTDESC="-oA $5"
else
	OUTPUTDESC=""
fi

# Computers
if [ ${#OUTPUTDESC} -gt 0 ]; then
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=computers,ldap.maxobjects=-1,ldap.attrib="{sAMAccountName,operatingSystem,OperatingSystemServicePack}" $TARGET > $OUTPUTDESC.computers.txt
else
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=computers,ldap.maxobjects=-1,ldap.attrib="{sAMAccountName,operatingSystem,OperatingSystemServicePack}" $TARGET
fi

# Groups
if [ ${#OUTPUTDESC} -gt 0 ]; then
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=custom,ldap.searchattrib="objectCategory",ldap.searchvalue="group",ldap.maxobjects=-1,ldap.attrib="{sAMAccountName}" $TARGET > $OUTPUTDESC.groups.txt
else
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=custom,ldap.searchattrib="objectCategory",ldap.searchvalue="group",ldap.maxobjects=-1,ldap.attrib="{sAMAccountName}" $TARGET
fi

# Users
if [ ${#OUTPUTDESC} -gt 0 ]; then
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=users,ldap.maxobjects=-1,ldap.attrib="{sAMAccountName}" $TARGET > $OUTPUTDESC.users.txt
else
	nmap -p 389 --script=ldap-search --script-args=ldap.username="$USERNAME",ldap.password="$PASSWORD",ldap.qfilter=users,ldap.maxobjects=-1,ldap.attrib="{sAMAccountName}" $TARGET
fi

