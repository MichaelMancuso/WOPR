#!/bin/bash

ShowUsage() {
	echo "$0 [--null-enum] <target>"
	echo "$0 will query the target system for its operating system information."
	echo "If --null-enum is specified, the script will attempt to enumerate, groups, users, and shares via a null session"
}


if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

NULLENUM=0
TARGET=""

for i in $*
do
	case $i in
    	--null-enum)
		NULLENUM=1
	;;
	*)
		TARGET=$i
	;;
  	esac
done

nmap -p 445 --script=smb-os-discovery,smb-security-mode,smb-system-info $TARGET

if [ $NULLENUM -eq 1 ]; then
	nmap -p 445 --script=smb-enum-domains,smb-enum-groups,smb-enum-users,smb-enum-shares $TARGET
fi

