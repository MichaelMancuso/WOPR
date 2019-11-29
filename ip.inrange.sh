#!/bin/bash

ShowUsage() {
	echo ""
	echo "Usage: $0 <Starting IP> <Ending IP> <IP to Test>"
	echo "$0 looks at the IP to test and returns: "
	echo "0: In range"
	echo "1: Under the low IP"
	echo "2: Over the high IP"
	echo ""
}

inet_aton ()
{
    local IFS=. ipaddr ip32 i
    ipaddr=($1)
    for i in 3 2 1 0
    do
        (( ip32 += ipaddr[3-i] * (256 ** i) ))
    done

    echo $ip32

    return $ip32
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

iMIN=`inet_aton $1`
iMAX=`inet_aton $2`
iIP=`inet_aton $3`

#echo "iMIN: $iMIN"
#echo "iMAX: $iMAX"
#echo "iIP: $iIP"

if [ $iIP -lt $iMIN ]; then
	echo "$3 is 'under' $1"
	exit 1
fi

if [ $iIP -gt $iMAX ]; then
	echo "$3 is 'over' $2"
	exit 2
fi

echo "$3 is in range."
exit 0

