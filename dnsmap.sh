#!/bin/sh

# -----------------------------------------------------------------------------
# dnsmap
# 
# Written by Michael Piscopo
#
# -----------------------------------------------------------------------------

# --------------- Functions --------------------------
PrintTabs() {
#	echo -e "\n$1" | sed "s|.*?\n||"
	echo -e "$1" | sed "s|^-e ||"
}

# --------------- Main --------------------------

EXPECTED_ARGS=2

if [ $# -lt $EXPECTED_ARGS ]
then
  echo "usage: $0 <dns server ip address> <base domain name> [Alternate input file]"
  echo "Base domain example: mydomain.com"
  exit 1
fi

INPUTFILE="DNSWordList.txt"
if [ $# -gt $EXPECTED_ARGS ]
then
	INPUTFILE=$3
fi

if [ ! -e $INPUTFILE ] 
then
	if [ -e /opt/dnsmap/$INPUTFILE ] 
	then
		INPUTFILE=`echo /opt/dnsmap/$INPUTFILE`
	else
	  echo "File $INPUTFILE and /opt/dnsmap/$INPUTFILE does not exist.  Please check file location."
	  exit 1
	fi
fi

DNSSERVER=$1
DOMAIN=$2

echo "[`date`] Starting DNS dictionary mapping of $DOMAIN via $DNSSERVER..."
NUMFOUND=0

NAMELIST=`cat $INPUTFILE | grep -v "^$" | grep -v "#"`

for line in $NAMELIST
do
	# The Sed replace of \r is a safety check for files moving between
	# Windows an *nix.
	NAME=`echo "$line" | sed "s|\r||"`

	FULLNAME=`echo "$NAME.$DOMAIN"`
	
	DNSRESULT=`nslookup $FULLNAME $DNSSERVER 2>/dev/null`

#	Note: nslookup seems to return a 0 error code $? whether it's
#	Successful or not, so need to check text result.

	if ( echo "$DNSRESULT" | grep "Name:" > /dev/null ); then
		ADDRESSES=`echo "$DNSRESULT" | grep -v "$DNSSERVER" | grep "Address" | sed "s|Addresses:||" | sed "s|Address:||" | sed "s|  ||g" | sed "s|^ |$FULLNAME\t|g"`
#		PrintTabs "$FULLNAME\t$ADDRESSES"
		echo "$ADDRESSES"
		NUMFOUND=$(( NUMFOUND + 1 ))
	fi
done

echo "[`date`] Finished mapping $DOMAIN.  Found $NUMFOUND matched names."

