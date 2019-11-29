#!/bin/sh

ShowUsage() {
	echo "$0 Usage:"
	echo "$0 [--help] [--file=<pattern file> | --pattern=<pattern>] [<directory>]"
	echo ""
	echo "$0 will search a directory structure for a series of "
	echo "regular expressions contained the specified a file or the "
	echo "specified regex pattern.  This type of local search facilitates"
	echo "locating sensitive and/or compliance-related information."
	echo ""
	echo "$0 will search the specified directory for the given pattern file"
	echo "entries and report the file and line it was found in."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

PATTERNFILE=""
PATTERN=""
USEFILE=1
DIRECTORY="."

for i in $*
do
	case $i in
    	--file=*)
		PATTERNFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		if [ ! -e $PATTERNFILE ]; then
			echo "ERROR: Unable to find $PATTERNFILE"
			exit 2
		fi
	;;

    	--pattern=*)
		PATTERN=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		USEFILE=0
	;;
	--usetor)
		SOCKSIFY=$SOCKSAPP
		PING=0
		TRACERT=0
		IKESCAN=0

		DNSTESTS=0
		SNMP=0
		NTPTEST=0

		NMAPSCANTYPE="-sT"
		;;
	*)
		DIRECTORY="$i"
	;;
	esac
done

if [ $USEFILE -eq 1 ]; then
	
	if [ ${#PATTERNFILE} -eq 0 ]; then
		echo "ERROR: Please provide a pattern file."
		exit 2
	fi

	find $DIRECTORY -readable -exec grep -H -n --file=$PATTERNFILE '{}' \; -print | grep "#\!"
else
	find $DIRECTORY -readable -exec grep -H -n "$PATTERN" '{}' \; -print | grep "#\!"
fi


