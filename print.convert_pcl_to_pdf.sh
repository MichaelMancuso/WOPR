#!/bin/bash

ShowUsage() {
	echo "$0 Usage: $0 <input pcl file>"
	echo "Converts pcl print job captured over TCP/9100 to a PDF document."
	echo "These streams can be captured with MitM / Wireshark then the streams"
	echo "can be extracted with capture.extract_flows.sh"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE="$1"
echo "$INPUTFILE" | grep -Eioq "\.pcl"

if [ $? -gt 0 ]; then
	echo "ERROR: Did not find .pcl extension on input file."
	echo "END."
	echo ""
	exit 2
fi

OUTPUTFILE=`echo "$INPUTFILE" | sed "s|\.pcl|\.pdf|"`

if [ -e ./pcl6 ]; then
	./pcl6 -sDEVICE=pdfwrite -sOutputFile="$OUTPUTFILE" "$INPUTFILE"
else
	pcl6 -sDEVICE=pdfwrite -sOutputFile="$OUTPUTFILE" "$INPUTFILE"
fi
