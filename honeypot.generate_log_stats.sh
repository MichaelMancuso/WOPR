#!/bin/bash

OUTPUTFILE="/usr/local/awstats/wwwroot/cgi-bin/honeypot_stats.txt"

if [ $# -gt 0 ]; then
	OUTPUTFILE="$1"
fi

echo "[`date`] Starting conversion (this may take some time)..."
/usr/bin/honeypot.show_log_stats.sh > $OUTPUTFILE
echo "[`date`] done."
