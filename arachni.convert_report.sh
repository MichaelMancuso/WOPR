#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <report file> <output type: html/txt>"
	echo "See arachni-reporter --reporters-list for more output options."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE="$1"
OUTPUTTYPE=""
ISHMTL=0

# Get the case right on HTML and Text parameters
echo "$2" | grep -iq "html"

if [ $? -eq 0 ]; then
	OUTPUTTYPE="html"
	ISHTML=1
else
	echo "$2" | grep -iq "txt"
	if [ $? -eq 0 ]; then
		OUTPUTTYPE="txt"
	else
		# If it's not HTML or Text, just pass it through
		OUTPUTTYPE="$2"
	fi
fi

echo "$PATH" | grep -q "\/usr\/share\/arachni"

if [ $? -gt 0 ]; then
	export PATH=$PATH:/usr/share/arachni/bin
fi

echo "$INPUTFILE" | grep -q "\/"

if [ $? -gt 0 ]; then
	CURDIR=`pwd`
	INPUTFILE=`echo "$CURDIR/$INPUTFILE"`
fi

# Note that in their infinite wizdom, they auto-zip HTML.  So the output is really html.zip

if [ $ISHTML -eq 1 ]; then
	OUTPUTFILE=`echo "$INPUTFILE" | sed "s|afr$|html\.zip|"`
else
	OUTPUTFILE=`echo "$INPUTFILE" | sed "s|afr$|$OUTPUTTYPE|"`
fi

arachni_reporter $INPUTFILE --reporter=$OUTPUTTYPE:outfile=$OUTPUTFILE.$OUTPUTTYPE

if [ $ISHTML -eq 1 ]; then
	# Now we need to unzip it.

	# Get the directory... 
#	OUTPUTDIR=`echo "$INPUTFILE" | grep -Eio ".*\/"`
#	FILENAME=`echo "$INPUTFILE"  | sed "s|$FILEPATH||"`
#	FILEBASE=`echo "$FILENAME" | sed "s|\.afr$||"`
	OUTPUTDIR=`echo "$INPUTFILE" | sed "s|\.afr$||"`

	if [ ! -e $OUTPUTDIR ]; then
		mkdir $OUTPUTDIR
	fi
	unzip $OUTPUTFILE -d $OUTPUTDIR
fi

