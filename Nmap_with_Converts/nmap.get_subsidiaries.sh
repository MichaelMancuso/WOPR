#!/bin/sh

ShowUsage() {
	echo "Usage:"
	echo "$0 <answers.com company topic designator.>"
	echo "ex: $0 my-co-inc"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

COMPANY=$1
wget http://www.answers.com/topic/$1 -O - | grep -Eio "Principal Subsidiaries.*?Principal Competitors" | sed "s|Principal Subsidiaries<\/p><p>||" | sed "s|Principal Competitors||" | sed "s|; |\n|g"

