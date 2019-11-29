#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <username> <password> <command line>"
	echo "Username should be <DOMAIN>/<User>"
	echo "Can redirect with >> in command.  For example:"
	echo "dir >> \\[yourIP\YourShare\results.txt or dir >> c:\users\<username>\results.txt"
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
winexe -d 1 -U $USERNAME%$PASSWORD //$TARGET "cmd /c $QUERY"

