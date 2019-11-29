#!/bin/bash

ShowUsage() {
	echo "$0 <smbdomain> <username> <password> <target> [output file descriptor]"
	echo "$0 will query the target system for groups and member users."
	echo "If output descriptor is specified, this is used with nmap's -oA option"
}


if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

SMBDOMAIN="$1"
USERNAME="$2"
PASSWORD="$3"
TARGET="$4"

if [ $# -gt 4 ]; then
	OUTPUTDESC="-oA $5"
else
	OUTPUTDESC=""
fi
nmap -sT -p 445 --script=smb-enum-groups --scriptargs=smbdomain=$SMBDOMAIN,smbuser=$USERNAME,smbpass=$PASSWORD $OUTPUTDESC $TARGET

if [ $# -gt 4 ]; then
	nmap.format_smb_groups.sh $5.nmap > $5.txt
fi

