#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Usage: $0 <cain file>"
	echo ""
	exit 1
fi

CAINFILE=$1

if [ ! -e $CAINFILE ]; then
	echo "ERROR: $CAINFILE does not exist."
	exit 2
fi

CAINCONTENTS=`cat $CAINFILE`
CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s| - | |g"`
CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s|\t$||g"`
CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\t||g"`

IFS_BAK=$IFS
IFS="
"

for CAINENTRY in $CAINCONTENTS
do
	HASH=`echo "$CAINENTRY" | grep -Eo "[0-9a-fA-F]{104,}"`
	USERNAME=`echo "$CAINENTRY" | grep -Eo '[A-Za-z0-9_-.]{1,}\\\\[A-Za-z0-9_-.]{1,}'`
	MSKRBTAG="\$mskrb5\$\$\$"
	DOLLARSIGN="$"

	HASHPART1=`echo "$HASH" | grep -Eo "^[0-9a-fA-F]{32,32}"`
	HASHPART2=`echo "$HASH" | grep -Eo "[0-9a-fA-F]{72,72}$"`
	echo "$USERNAME:$MSKRBTAG$HASHPART1$DOLLARSIGN$HASHPART2"

done

echo "[`date`] done.  use ./john --format:[krb5pa-md5 | krb5pa-sha1 | mskrb5] --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=4  <password file>  to crack" >&2

IFS=$IFS_BAK
IFS_BAK=

