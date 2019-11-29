#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <target ip> [filter IP]"
	echo "$0 uses mtr to monitor <target ip> for loss."
	echo "If a filter IP is provided, that IP will not trigger a data loss alarm. (Useful if there's one hop which is rate-limiting ICMP"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGETIP="$1"

if [ $# -gt 1 ]; then
	FILTERIP="$2"
else
	FILTERIP="^$"
fi

echo "[`date`] Monitoring $TARGETIP for loss..."

while true; do
	echo -n "."
	MTRREPORT=`mtr --report --report-cycles=10 $TARGETIP`
	HASLOSS=`echo "$MTRREPORT" | grep -v "$FILTERIP" | grep -Eio "[0-9]{1,}%" | sed "s|%||g" | sort -un | grep -v "^0$" | wc -l`

	if [ $HASLOSS -gt 0 ]; then
		DATESEC=`date +%s`
		echo "[`date`] Loss detected" > loss.mtr.$DATESEC.rpt
		echo "$MTRREPORT" >> loss.mtr.$DATESEC.rpt

		echo ""
		echo "[`date`] Loss detected and report written to loss.mtr.$DATESEC.rpt."
		echo "$MTRREPORT"
	fi

done

