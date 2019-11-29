#!/bin/bash
ShowUsage() {
	echo "Usage: $0 [--vlan=<id>] [--verbose]"
	echo "--vlan=<id> allows scanning over an 802.1Q trunk port."
	echo "--verbose   Attempt to resolve IP -> DNS Name and indicate discovery was via ARP"
	echo ""
}

USEVLAN=0
VLANID=0
VERBOSE=0

for i in $*
do
	case $i in
    	--vlan=*)
			VLANID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
			USEVLAN=1
		;;
		--verbose)
			VERBOSE=1
		;;
		*)
			ShowUsage
			exit 1
		;;
	esac
done

IFS_BAK=$IFS
IFS="
"

RESULTS=""

if [ $USEVLAN -eq 0 ]; then
	echo "[`date`] Scanning local subnet..."
	if [ $VERBOSE -eq 0 ]; then
		arp-scan --localnet --quiet
	else
		RESULTS=`arp-scan --localnet --quiet`
	fi
else
	echo "[`date`] Scanning VLAN $VLANID..."
	if [ $VERBOSE -eq 0 ]; then
		arp-scan --vlan=$VLANID --quiet
	else
		RESULTS=`arp-scan --vlan=$VLANID --quiet`
	fi
fi

if [ $VERBOSE -eq 1 ]; then
#		Only get lines with IP and mac
		RESULTS=`echo "$RESULTS" | grep -E "^[0-9]{1,3}\." | sort -u`
		
		for CURRESULT in $RESULTS; do
			IPADDR=`echo "$CURRESULT" | cut -f1`
			MACADDR=`echo "$CURRESULT" | cut -f2`
			
			SYSNAME="<NONE>"
			
			NSRESULT=`nslookup -type=PTR $IPADDR | grep "name"`

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
			
			echo -e "$SYSNAME\tARP Scan\t$IPADDR\t$MACADDR"
		done
fi

echo "[`date`] Done."

IFS=$IFS_BAK
IFS_BAK=
