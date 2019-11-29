#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <IP Address 1st 3 octets> <4th octet start> <4th octet stop> [Server IP]"
	echo ""
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

NETWORK="$1"
COUNTSTART=$2
COUNTEND=$3

DNSSERVER=""

if [ $# -gt 3 ]; then
	DNSSERVER="$4"
fi

if [ $COUNTSTART -gt $COUNTEND ]; then
	echo "ERROR: $COUNTSTART is greater than $COUNTEND"

	exit 2
fi

echo "Scanning $NETWORK.$COUNTSTART..$COUNTEND" >&2
# for i in {$COUNTSTART..$COUNTEND}
RANGE=`seq $COUNTSTART $COUNTEND`
for i in $RANGE
do
	NSRESULT=`nslookup -type=PTR $NETWORK.$i $DNSSERVER | grep "name"`

	if [ $? -eq 0 ]; then
	# if [ ${#NSRESULT} -gt 0 ]; then
		NSNAME=`echo "$NSRESULT" | grep -Eo "name =.*$" | head -1 | sed "s|name =\s||" | sed "s|\.$||"`
		echo "$NSNAME	$NETWORK.$i"
	fi
done

