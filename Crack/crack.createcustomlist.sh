#!/bin/sh

ShowUsage() {
	echo "$0 Usage:"
	echo "$0 [--include-raw] --inputfile=<input file> --designator=<designator>"
	echo ""
	echo "$0 will take the specified input file and the specified designator"
	echo "and create a combination of variant files (as specified by any parameters)"
	echo "in the current directory."
	echo ""
	echo "1.  Raw designator prepended to all entries (not default).  Can be used for mixed case."
	echo "2.  Raw designator appended to all entries (not default).  Can be used for mixed case."
	echo "3.  Lowercase designator prepended to all entries"
	echo "4.  Uppercase designator prepended to all entries"
	echo "5.  Lowercase designator appended to all entries"
	echo "6.  Uppercase designator appended to all entries"
	echo ""
	echo "Options:"
	echo "--include-raw  If specified, an additional set with the raw designator will be used (e.g. mixed case)."
	echo "--help      This screen."
	echo ""
}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE=""
DESIGNATOR=""
INCLUDE_RAW=0

for i in $*
do
	case $i in
	--include-raw)
		INCLUDE_RAW=1
	;;
    	--designator=*)
		DESIGNATOR=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
    	--inputfile=*)
		# Strip off any paths and write it in the current location
		INPUTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | sed 's|^.*/||g'`
		INPUTFILEFULL=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	esac
done

if [ ! -e $INPUTFILEFULL ]; then
	echo ""
	echo "ERROR: Unable to find $INPUTFILEFULL"
	echo ""
	exit 2
fi

CAPDESIGNATOR=`echo "$DESIGNATOR" | tr [a-z] [A-Z]`
LOWERDESIGNATOR=`echo "$DESIGNATOR" | tr [A-Z] [a-z]`

if [ $INCLUDE_RAW -eq 1 ]; then
	echo "Prepending $DESIGNATOR..."
	cat $INPUTFILEFULL | sed "s|^|$DESIGNATOR|g" > $INPUTFILE.pre.$DESIGNATOR.raw
	echo "Appending $DESIGNATOR..."
	cat $INPUTFILEFULL | sed "s|$|$DESIGNATOR|g" > $INPUTFILE.post.$DESIGNATOR.raw
fi

echo "Prepending $LOWERDESIGNATOR..."
cat $INPUTFILEFULL | sed "s|^|$LOWERDESIGNATOR|g" > $INPUTFILE.pre.$DESIGNATOR.lower
echo "Prepending $CAPDESIGNATOR..."
cat $INPUTFILEFULL | sed "s|^|$CAPDESIGNATOR|g" > $INPUTFILE.pre.$DESIGNATOR.upper
echo "Appending $LOWERDESIGNATOR..."
cat $INPUTFILEFULL | sed "s|$|$LOWERDESIGNATOR|g" > $INPUTFILE.post.$DESIGNATOR.lower
echo "Appending $CAPDESIGNATOR..."
cat $INPUTFILEFULL | sed "s|$|$CAPDESIGNATOR|g" > $INPUTFILE.post.$DESIGNATOR.upper


