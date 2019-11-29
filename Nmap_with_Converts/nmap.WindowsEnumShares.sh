#!/bin/bash

ShowUsage() {
	echo "$0 <smbdomain> <username> <password> <target> [output file descriptor]"
	echo "$0 will query the target system(s) for shares."
	echo "<target> can specify an input file by preceding it with file (e.g. file:myips.txt)"
	echo "If output descriptor is specified, this is used with nmap's -oA option"
}


if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

SMBDOMAIN="$1"
USERNAME="$2"
PASSWORD="$3"
TARGET="$4"

if [ $# -gt 4 ]; then
	OUTPUTDESC="-oA $5"
else
	OUTPUTDESC=""
fi

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

	if [ ! -e $NETFILE ]; then
		echo "ERROR: Unable to find file '$NETFILE'"
		exit 2
	fi

	nmap -sT -p 445 --script=smb-enum-shares --script-args=smbdomain=$SMBDOMAIN,smbuser=$USERNAME,smbpass=$PASSWORD $OUTPUTDESC -iL $NETFILE

else
	nmap -sT -p 445 --script=smb-enum-shares --script-args=smbdomain=$SMBDOMAIN,smbuser=$USERNAME,smbpass=$PASSWORD $OUTPUTDESC $TARGET
fi

# If a descriptor was provided, convert the nmap output file to a flatter format
if [ $# -gt 4 ]; then

	NMAPRESULTSFILE="$5.nmap"

	IFS_BAK=$IFS
	IFS="
	"

	RESULTS=`cat $NMAPRESULTSFILE | grep -E -e "scan report for" -e "^\|   [a-zA-Z0-9]"`
	SYSTEMNAME=""
	SHARES=""

	for CURLINE in $RESULTS
	do
		echo "$CURLINE" | grep -q "scan report for"

		if [ $? -eq 0 ]; then

			if [ ${#SHARES} -gt 0 ]; then
				echo "$SYSTEMNAME,\"$SHARES\"" > $5.csv
			fi
			SYSTEMNAME=`echo "$CURLINE" | sed "s|Nmap scan report for||" | sed "s|)||" | sed "s| (|,|"`
			SHARES=""
		else
			CURSHARE=`echo "$CURLINE" | sed "s/|   //"`

			if [ ${#SHARES} -eq 0 ]; then
				SHARES="$CURSHARE"
			else
				SHARES=`echo "$SHARES,$CURSHARE"`
			fi
		fi
	done

	if [ ${#SHARES} -gt 0 ]; then
		echo "$SYSTEMNAME,\"$SHARES\""  > $5.csv
	fi

	IFS=$IFS_BAK
	IFS_BAK=
fi

