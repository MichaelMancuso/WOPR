#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Usage: $0 <cain file>"
	exit 1
fi

CAINFILE=$1

if [ ! -e $CAINFILE ]; then
	echo "ERROR: $CAINFILE does not exist."
	exit 2
fi

CAINCONTENTS=`cat $CAINFILE`
# CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s| - | |g"`
# CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s|\t| |g"`

IFS_BAK=$IFS
IFS="
"

for CAINENTRY in $CAINCONTENTS
do
	USERNAME=`echo "$CAINENTRY" | cut -f 1`
	SERVERCHALLENGE=`echo "$CAINENTRY" | cut -f 7`
	NTHASH=`echo "$CAINENTRY" | cut -f 6`

	DOLLARSIGN="$"

#       Output format:
#	USERNAME:$NETNTLM$:SERVER_CHALLENGE:NTHASH
#	Example: username:$NETNTLM$1122334455667788$B2B2220790F40C88BCFF347C652F67A7C4A70D3BEBD70233
	echo "$USERNAME:\$NETNTLM\$$SERVERCHALLENGE\$$NTHASH:::::::"

done

echo "[`date`] done.  Use ./john --format:netntlm-naive --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=8  to crack" >&2

IFS=$IFS_BAK
IFS_BAK=

