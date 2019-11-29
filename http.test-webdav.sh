#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <URL>"
	echo "$0 will test the specified URL to see if webdav is available."
	echo "Example: $0 http://myhost.mydomain.com/"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

URL="$1"


davtest -url $URL

