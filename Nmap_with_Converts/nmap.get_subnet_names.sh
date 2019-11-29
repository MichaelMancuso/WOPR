#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <first 3 parts of /24 to test>"
	echo "Attempts dns and SMB techniques to determine active system's names."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

FIRSTOCTETS=$1

for i in `seq 1 254`
do
	FOUNDSYSTEM=0
	IPADDR=`echo "$FIRSTOCTETS.$i"`
	
	ping -c 1 -w 1 $IPADDR > /dev/null
	
	if [ $? -eq 0 ]; then
		NSRESULT=`nslookup -type=PTR $IPADDR | grep "name"`
		SYSNAME=""

		if [ ${#NSRESULT} -gt 0 ]; then
			NSNAME=`echo "$NSRESULT" | grep -Eo "name =.*$" | head -1 | sed "s|name =\s||" | sed "s|\.$||"`
			if [ ${#NSNAME} -gt 0 ]; then
				SYSNAME=$NSNAME
			fi
		else
			NMAPRESULT=`nmap -sT -p 139,445 --script=smb-os-discovery $IPADDR`
	
			NSNAME=`echo "$NMAPRESULT" | grep "Computer name" | sed "s|.*: ||"`
			DNSNAME=`echo "$NMAPRESULT" | grep "Domain name" | sed "s|.*: ||"`

			if [ ${#NSNAME} -gt 0 ]; then
				SYSNAME=`echo "$NSNAME.$DNSNAME"`
			fi
		fi

		if [ ${#SYSNAME} -gt 0 ]; then
			echo -e "$SYSNAME\t$IPADDR"
		else
			echo -e "<Unknown>\t$IPADDR"
		fi
	fi

done

