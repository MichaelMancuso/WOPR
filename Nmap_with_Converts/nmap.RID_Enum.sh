#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <DC IP>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"

# First need the domain SID
LSARESULT=`rpcclient -U "" -N -c "lsaquery" $TARGET`
SID=`echo "$LSARESULT" | grep "Domain Sid" | grep -Eo "S\-.*"`

if [ ${#SID} -eq 0 ]; then
	echo "ERROR: Unable to extract SID.  Returned data was:"
	echo "$LSARESULT"
	exit 1
else
	echo "Found domain info..."
	echo "$LSARESULT"
fi

echo "[`date`] Enumerating SIDs 500-100000..."

for i in {500..100000}
do
	rpcclient -U "" -N -c "lookupsids $SID-$i" $TARGET
done 

# If you run this by hand, you may be able to issue an lsaenumsid but may get access denied

