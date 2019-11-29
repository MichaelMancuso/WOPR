#!/bin/bash

ShowUsage() {
	echo "$0 <filespec>"
	echo "$0 will cat all [HTML] files meeting <filespec> and extract email addresses from TheHarvester's HTML output."
	echo ""
}

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

cat $1 | grep -Pio "useritem\">.*?</li>" | sed "s|useritem\">||g" | sed "s|</li>||g" | grep -v "^@" | sort -u

