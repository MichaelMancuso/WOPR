#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <DNS File> [--detail] [--countonly]"
	echo "This script will search for cluttered DNS entries (entries with more than 500 entries on the same IP) and remove them after making a backup of the current file)"
	echo "--detail   Show the found IP's and counts"
	echo "--countonly Shows message indicating if file appeared cluttered or not.  Can be combined with --detail"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

CLUTTERTHRESHOLD=600
SHOWDETAIL=0
COUNTONLY=0

for i in $*
do
	case $i in
    	--detail)
		SHOWDETAIL=1
		;;
    	--countonly)
		COUNTONLY=1
		;;
  	esac
done

DNSFILE=$1

if [ ! -e $DNSFILE ]; then
	echo "ERROR: Unable to locate $DNSFILE"
	exit 2
fi

IPSINFILE=`cat $DNSFILE | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u`
WWWRECORD=`cat $DNSFILE | grep -E "^www\."`
RAWDATA=`cat $DNSFILE | grep -v "^$"`

FOUNDCLUTTEREDENTRIES=0

for CURIP in $IPSINFILE
do 
	NUMENTRIES=`grep "$CURIP" $DNSFILE | wc -l`

	if [ $SHOWDETAIL -gt 0 ]; then
		echo -e "$CURIP\t$NUMENTRIES"
	fi

	if [ $NUMENTRIES -gt $CLUTTERTHRESHOLD ]; then
		# This is a cluttered IP
		RAWDATA=`echo "$RAWDATA" | grep -v "$CURIP$"`
		FOUNDCLUTTEREDENTRIES=1
	fi
done

if [ $FOUNDCLUTTEREDENTRIES -eq 1 ]; then
	if [ $COUNTONLY -eq 0 ]; then
		echo "[`date`] $DNSFILE was cluttered.  Writing new file with backup in $DNSFILE.bak."

		# make a backup
		if [ ! -e $DNSFILE.bak ]; then
			cp $DNSFILE $DNSFILE.bak
		fi

		# write out post-processed data
		HASWWW=`echo -e "$RAWDATA" | grep -E "^www\." | wc -l`

		if [ $HASWWW -gt 0 ]; then
			echo -e "$RAWDATA" > $DNSFILE
		else
			# www record was also a cluttered IP.  Rewrite it into the file and resort
			echo -e "$RAWDATA" > $DNSFILE.tmp
			echo -e "$WWWRECORD" >> $DNSFILE.tmp
			cat $DNSFILE.tmp | sort -u > $DNSFILE
			rm $DNSFILE.tmp
		fi
	else
		echo "[`date`] $DNSFILE is cluttered.  Count-only mode specified.  No file rewrites done."
	fi
else
	echo "[`date`] $DNSFILE is clean."
fi

