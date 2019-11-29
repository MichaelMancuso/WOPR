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
CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s| - | |g"`
CAINCONTENTS=`echo "$CAINCONTENTS" | sed "s|\t| |g"`

IFS_BAK=$IFS
IFS="
"

for CAINENTRY in $CAINCONTENTS
do
	USERNAME=`echo "$CAINENTRY" | head -1 | grep -Pio "^.*?\s" | sed "s|\s||"`
	NEWLINE=`echo "$CAINENTRY" | sed "s|^$USERNAME ||" | sed "s|^ ||"`

	DOMAIN=`echo "$NEWLINE" | head -1 | grep -Pio "^.*?\s" | sed "s|\s||"`
	NEWLINE=`echo "$NEWLINE" | sed "s|^$DOMAIN ||" | sed "s|^ ||"`

	NTLMv2HASH=`echo "$NEWLINE" | grep -Po "^[0-9a-fA-F]{28,}\s" | sed "s|\s||"`
	NEWLINE=`echo "$NEWLINE" | sed "s|^$NTLMv2HASH ||" | sed "s|^ ||"`

	SERVERCHALLENGE=`echo "$NEWLINE" | grep -Po "^[0-9a-fA-F]{10,}\s" | sed "s|\s||"`
	NEWLINE=`echo "$NEWLINE" | sed "s|^$SERVERCHALLENGE ||" | sed "s|^ ||"`
	CLIENTCHALLENGE=`echo "$NEWLINE" | grep -Po "^[0-9a-fA-F]{10,}\s" | sed "s|\s||"`

	DOLLARSIGN="$"

	HASHPART1=`echo "$HASH" | grep -Eo "^[0-9a-fA-F]{32,32}"`
	HASHPART2=`echo "$HASH" | grep -Eo "[0-9a-fA-F]{72,72}$"`

#       Output format:
#	USERNAME::DOMAIN:SERVER_CHALLENGE:NTLMv2_RESPONSE:CLIENT_CHALLENGE
	echo "$USERNAME::$DOMAIN:$SERVERCHALLENGE:$NTLMv2HASH:$CLIENTCHALLENGE"

done

echo "[`date`] done.  For CPU cracking:" >&2
echo "Use ./john --format:netntlmv2 --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=4  <password file> to crack" >&2
echo "[`date`] done.  For GPU cracking:" >&2
echo "Use ./john --format:ntlmv2-opencl  --fork=3 --dev=0,1,2 --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules <password file> to crack" >&2

IFS=$IFS_BAK
IFS_BAK=

