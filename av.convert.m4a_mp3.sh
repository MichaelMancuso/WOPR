#!/bin/sh
# Note that this must include:
# faad: apt-get -y install faad
# lame: apt-get -y install lame

if [ $# -eq 0 ]; then
	echo ""
	echo "Usage: $0 [--convertdir=<dir> | <inputfile>]"
	echo "$0 will convert the m4a/mp4 audio files or mp4 video files"
	echo "to mp3 audio files."
	echo ""
	echo "Either an input file may be specified as <inputfile> or "
	echo "--convertdir=<dir> to convert all files in the specified "
	echo "directory.  Output mp3 files will have the same name as"
	echo "the original with an mp3 extension."

	exit 1
fi

# check for required modules...
faad -h 2> /dev/null 1> /dev/null

if [ $? -gt 1 ]; then
	echo "Unable to find faad.  Please use 'sudo apt-get -y install faad' to install."
	exit 1
fi

lame --help 2> /dev/null 1> /dev/null

if [ $? -gt 0 ]; then
	echo "Unable to find lame.  Please use 'sudo apt-get -y install lame' to install."
	exit 1
fi

CWD=`pwd`

echo $1 | grep "convertdir=" > /dev/null

if [ $? -eq 0 ]; then
	# using directory
	SRCDIR=`echo "$1" | sed 's/[-a-zA-Z0-9]*=//' | sed 's|\"||g'`

	cd "$SRCDIR"

	if [ $? -gt 0 ]; then
		echo "ERROR: Unable to cd into $SRCDIR"

		exit 2
	fi

	echo "Reading file list from $SRCDIR..."

	INPUTFILELIST=`ls -1 | grep -E "\.m[p4][4a]"`

	NUMFILES=`echo "$INPUTFILELIST" | wc -l`

	if [ $NUMFILES -lt 1 ]; then
		echo "ERROR: No mp4 or m4a files found in $SRCDIR"
		exit 2
	fi

	echo "Found $NUMFILES files..."
else
	# single file
	INPUTFILELIST=`echo "$1"`
fi

# for defaults to splitting on whitespace.  Using IFS changes
# it to newline instead
IFS_BAK=$IFS
IFS="
"

for INPUTFILE in $INPUTFILELIST
do
	echo "Converting $INPUTFILE file to mp3..."

	faad "$INPUTFILE"

	# Temp files
	WAVFILE=`echo "$INPUTFILE" | sed 's|\.m4a|\.wav|' | sed 's|\.mp4|\.wav|'`
	AACFILE=`echo "$WAVFILE" | sed 's|\.wav|\.aac|'`

	# output file
	MP3FILE=`echo "$INPUTFILE" | sed 's|\.m4a|\.mp3|' | sed 's|\.mp4|\.mp3|'`


	lame -h -b 192 "$WAVFILE" "$MP3FILE"

	# clean up
	rm "$WAVFILE"

	if [ -e "$AACFILE" ]; then
		rm "$AACFILE"
	fi
done

IFS=$IFS_BAK
IFS_BAK=

cd $CWD

