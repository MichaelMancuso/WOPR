#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target> <port> <username> [passwordfile]"
	echo ""
}


if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"
PORT=$2
USERNAME="$3"
PASSWORDFILE="/opt/wordlists/MikesList.wordlist.txt"

if [ $# -gt 3 ]; then
	if [ -e "$4" ]; then
		PASSWORDFILE="$4"
	else
		echo "ERROR: Unable to find $4"
		exit 2
	fi
fi

# -f = stop after first crack
# -v = verbose
# -T 4 = timing scale 0-5
ncrack -v -f -T 4 --user $USERNAME -P $PASSWORDFILE $TARGET:$PORT

