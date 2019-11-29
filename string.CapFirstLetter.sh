#!/bin/sh

# @(#) s1       Demonstrate quickie perl for uppercase first character.

ShowUsage() { 
	echo "$0 <file>"
	echo "Capitalizes the first letter of each line."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

FILE=$1

if [ ! -e $FILE ]; then
	echo "ERROR: Unable to find file $FILE"
	exit 2
fi


perl -wp -e '$_ = ucfirst' $FILE

