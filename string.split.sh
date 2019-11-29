#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <file> [# of characters to split on]"
	echo "$0 will split a file every n many characters.  The default is 69 characters."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ $# -gt 1 ]; then
	SPLITCHARS=$2
else
	SPLITCHARS=69
fi
# sed -e 's/.\{69\}/&\n/g' $1
sed -e "s/.\{$SPLITCHARS\}/&\n/g" $1
