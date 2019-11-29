#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <Qualys Web App Scan 'New' XML report file>"
	echo "$0 takes a Qualys web app scan XML file (not the legacy xml but the save-as from the standard report screen) and converts it to quoted CSV."
	echo ""
	echo "Note: $0 expects the xsl transform file was_scan2csv_multiIP.xsl to be in /opt/qualys"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

XMLFILE="$1"

if [ ! -e "$XMLFILE" ]; then
	echo "ERROR: Unable to find $XMLFILE"
	exit 2
fi

xsltproc /opt/qualys/was_scan2csv_multiIP.xsl $XMLFILE | sed "s|&quot;|'|g"

