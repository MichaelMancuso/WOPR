#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <URL to save>"
	echo "$0 will save the specified page as a single HTML file (as 
much as possible."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

URL="$1"

echo "$URL" | grep -iq "^https"

if [ $? -eq 0 ]; then
	wget --no-check-certificate --no-parent --timestamping --convert-links --page-requisites --no-directories --no-host-directories -erobots=off "$URL"
else
	wget --no-parent --timestamping --convert-links --page-requisites --no-directories --no-host-directories -erobots=off "$URL"
fi
