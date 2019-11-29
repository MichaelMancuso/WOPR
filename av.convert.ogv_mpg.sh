#!/bin/sh

ShowUsage() {

	echo "Usage: $0 <inputfile.ogv> <outputfile.mpg>"
	echo ""
	echo "Converts an .ogv file created with a video capture"
	echo "program such as Cheese to an mpg format."
	echo ""

}

if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

INPUTFILE=$1
OUTPUTFILE=$2

if [ ! -e $INPUTFILE ]; then
	echo "ERROR: Unable to find $INPUTFILE."

	exit 2
fi

if [ ! -e $OUTPUTFILE.avi ]; then
	ffmpeg -i $INPUTFILE -b 5000k $OUTPUTFILE.avi
fi

if [ ! -e $OUTPUTFILE.avi ]; then
	echo "ERROR: Intermediate avi file not created.  Conversion stopped."

	exit 2
fi

ffmpeg -i $OUTPUTFILE.avi -target ntsc-vcd $OUTPUTFILE

if [ -e $OUTPUTFILE.avi ]; then
	rm $OUTPUTFILE.avi
fi

