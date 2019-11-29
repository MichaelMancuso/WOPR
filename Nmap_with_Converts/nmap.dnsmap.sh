#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 [--noversion] <domain name>"
	echo "$0 will perform basic mapping queries for the specified domain."
	echo "These include whois, dns dictionary lookup, MX retrieval, DNS server retrieval,"
	echo "Active Directory, and SIP record retrieval to map systems."
	echo "$0 will also use Metasploit to query Google, Bing, and Yahoo"
	echo "and extract any valid email addresses."
	echo ""
	echo "Output will be written to <domain>.dns.txt"
	echo ""
	echo "Options:"
	echo "--noversion Disables nmap version detection."
	echo "--no-dict   Do not run dictionary lookups."
	echo "--no-whois  Do not perform whois lookups."
	echo "--noemail   Do not look for email addresses in search engines."
	echo "--help      Show usage."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

RUNWHOIS=1
DICTIONARY=1
DETECTVERSION=1
DOMAIN=""
FINDEMAIL=1
ZONETRANSFERSUCCESSFUL=0

for i in $*
do
	case $i in
	--no-dict)
		DICTIONARY=0
	;;
    	--noversion)
		DETECTVERSION=0
	;;
	--noemail)
		FINDEMAIL=0
	;;
	--no-whois)
		RUNWHOIS=0
	;;
	--help)
		ShowUsage
		exit 1
	;;
	*)
		DOMAIN=$i
	;;
	esac
done

METASPLOIT=1
which msfconsole > /dev/null

if [ $? -gt 0 ]; then
	# Enabled or not, if not present, disable.

	if [ $METASPLOIT -eq 1 -a $FINDEMAIL -eq 1 ]; then
		echo "Unable to locate msfconsole.  Disabling Metasploit-based email lookup..."
	fi

	METASPLOIT=0
	FINDEMAIL=0
fi

if [ ${#DOMAIN} -eq 0 ]; then
	echo "No domain name provided."
	echo ""

	ShowUsage
	exit 2
fi

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

if [ $DETECTVERSION -eq 1 -a $ISLINUX -eq 1 ]; then
#  Must be superuser
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root to perform version detection."
	   echo "Either disable version detection with --noversion or use sudo to run as root."
	   exit 2
	fi
fi

# ------------------------- Core ---------------------------------
# WHOIS
if [ $RUNWHOIS -eq 1 ]; then
	echo "Performing WHOIS lookup for $DOMAIN [$DATESTR]..."
	echo ""
	echo "Performing WHOIS lookup for $DOMAIN" > $DOMAIN.dns.txt
	echo "------------------------------------------------------" >> $DOMAIN.dns.txt
	TMPRESULT=`whois -H $DOMAIN`
	echo "$TMPRESULT" > $DOMAIN.whois.txt
	echo "$TMPRESULT" >> $DOMAIN.dns.txt
else
echo "Skipping whois lookup for $DOMAIN"
fi

# NS
NSRESULTS=`nslookup -type=NS $DOMAIN`

if [ $? -gt 0 ]; then
	# something went wrong.  Can't even look up name servers. abort.
	echo "ERROR: Cannot look up $DOMAIN dns servers.  Check network "
	echo "connectivity and try again."
	
	echo "DNS Response for $DOMAIN:"
	echo "$NSRESULTS"

	exit 1
fi

# extract NS list
NSLIST=`echo "$NSRESULTS" | grep "internet address" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`

NAMESERVER=`echo "$NSLIST" | head -1`

if [ ${#NAMESERVER} -eq 0 ]; then
	# Sometimes this can happen when the DNS server is also the NS on an internal domain
	NSLIST=`echo "$NSRESULTS" | grep -E "^Address" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`

	NAMESERVER=`echo "$NSLIST" | head -1`

	if [ ${#NAMESERVER} -eq 0 ]; then
		NAMESERVER=`cat /etc/resolv.conf | grep nameserver | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | grep -v "^$"`
	fi

	if [ ${#NAMESERVER} -eq 0 ]; then
		echo "An error occurred finding a viable name server."
		exit 2
	fi

fi

echo "Using DNS Server $NAMESERVER for $DOMAIN queries..."

DATESTR=`date`

echo "Starting DNS mapping for $DOMAIN using primary server $NAMESERVER [$DATESTR]..."
echo ""
echo "DNS Map run $DATESTR for $DOMAIN using primary server $NAMESERVER" > $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo "Name Servers:" >> $DOMAIN.dns.txt
echo "$NSLIST" >> $DOMAIN.dns.txt
echo "Name Servers:"
echo "$NSLIST"
echo ""
echo "" >> $DOMAIN.dns.txt

echo "NS Response:" >> $DOMAIN.dns.txt
echo "$NSRESULTS" >> $DOMAIN.dns.txt
# SOA
NSRESULT=`nslookup -type=SOA $DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	echo "SOA:"  >> $DOMAIN.dns.txt
	echo "$NSRESULT"  >> $DOMAIN.dns.txt
else
	echo "ERROR: Unable to retrieve SOA information for $DOMAIN"  >> $DOMAIN.dns.txt
fi

echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
# Recursive
echo "Checking for server redundancy..."
echo "DNS Server Redundancy" >> $DOMAIN.dns.txt

# Redundancy
NUMDNSSERVERS=`echo "$NSLIST" | wc -l`

if [ $NUMDNSSERVERS -ge 2 ]; then
	SUBNETS=`echo "$NSLIST" | grep -o -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u`
	NUMSUBNETS=`echo "$SUBNETS" | wc -l`

	if [ $NUMSUBNETS -le 1 ]; then
		echo "Redundancy:  Insufficient (?) - Found DNS servers in $NUMSUBNETS potential subnets.  Assuming /24."
		echo "Redundancy:  Insufficient (?) - Found DNS servers in $NUMSUBNETS potential subnets.  Assuming /24." >> $DOMAIN.dns.txt
		
		for NSSUBNET in $SUBNETS
		do
			echo "$NSSUBNET.0"
			echo "$NSSUBNET.0" >> $DOMAIN.dns.txt
		done
	else
		echo "Redundancy:  Sufficient(?) - Found $NUMSUBNETS different potential subnets."
		echo "Redundancy:  Sufficient(?) - Found $NUMSUBNETS different potential subnets." >> $DOMAIN.dns.txt

		for NSSUBNET in $SUBNETS
		do
			echo "$NSSUBNET.0"
			echo "$NSSUBNET.0" >> $DOMAIN.dns.txt
		done
	fi
else
	echo "Redundancy: Less than two name servers found ($NUMDNSSERVERS)."
	echo "Redundancy: Less than two name servers found ($NUMDNSSERVERS)." >> $DOMAIN.dns.txt
fi

if [ $DETECTVERSION -eq 1 ]; then
	echo "Detecting server versions..."
	echo "------------------------------------------------------" >> $DOMAIN.dns.txt
	# Version
	echo "DNS Server Versions:" >> $DOMAIN.dns.txt
	# Version
	for DNSIP in $NSLIST
	do
		echo "Checking $DNSIP..."
		echo "$DNSIP Version Detection:" >> $DOMAIN.dns.txt
		NMAPRESULT=`nmap -PN -sV --version-intensity 7 -p 53 -sU $DNSIP | grep -i "^53"`

		NMAPCOUNT=`echo "$NMAPRESULT" | wc -l`

		if [ $NMAPCOUNT -gt 0 ]; then
			echo "$DNSIP Version: $NMAPRESULT"
			echo "$NMAPRESULT" >> $DOMAIN.dns.txt
		else
			echo "Unable to determine version for $DNSIP"
			echo "Unable to determine version for $DNSIP" >> $DOMAIN.dns.txt
		fi
	done
fi

echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
# Recursive
echo "Checking recursion..."
echo "Recursive Lookup for www.google.com:" >> $DOMAIN.dns.txt
NSRESULT=`nslookup www.google.com $NAMESERVER`

echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

if [ $? -eq 0 ]; then
	# No response.  No recursive lookup
	echo "Recursion: Disabled"  >> $DOMAIN.dns.txt
	echo "Cache Snooping: N/A"  >> $DOMAIN.dns.txt
else
	echo "Recursion: Enabled"  >> $DOMAIN.dns.txt
	# Recursion!
	echo "Recursion enabled!"

	# Snooping
	echo "Checking for cache snooping..."
	NSRESULT=`dig @$NAMESERVER www.google.com A +norecurse | grep "ANSWER:" | grep -o "ANSWER: \w," | sed "s|[1-9],|Yes|" | sed "s|0,|No|" | sed "s|,||g" | sed "s|ANSWER: ||"`

	echo "Cache Snooping: $NSRESULT"
	echo "Cache Snooping: $NSRESULT"  >> $DOMAIN.dns.txt
fi

# ------------------------- AD ---------------------------------
echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo "Active Directory Records:" >> $DOMAIN.dns.txt
echo "Checking for Active Directory records..."
# Active Directory DC/GC

NSRESULT=`nslookup -q=SRV _ldap._tcp.$DOMAIN $NAMESERVER`

FOUNDRESULTS=1
echo "$NSRESULT" | grep -i "no answer" > /dev/null

if [ $? -eq 0 ]; then
	FOUNDRESULTS=0
else
	echo "$NSRESULT" | grep -i "server can't find _ldap._tcp.$DOMAIN" > /dev/null

	if [ $? -eq 0 ]; then
		FOUNDRESULTS=0
	fi
fi

if [ $FOUNDRESULTS -eq 0 ]; then
	# No record
	echo "DC Records: No"
	echo "GC Records: No"
	echo "DC Records: No" >> $DOMAIN.dns.txt
	echo "GC Records: No" >> $DOMAIN.dns.txt
else
	# Found Records
	echo "DC Records:"  >> $DOMAIN.dns.txt

	SERVERLIST=`echo "$NSRESULTS" | grep -i "_ldap.tcp.$DOMAIN" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
	echo "DC's:" >> $DOMAIN.dns.txt
	echo "$SERVERLIST" >> $DOMAIN.dns.txt

	echo "$NSRESULT"  >> $DOMAIN.dns.txt

	echo "Found DC records!"
	echo "$SERVERLIST"

	# Look for GC records too.
	NSRESULT=`nslookup -q=SRV _ldap._tcp.gc._msdcs.$DOMAIN $NAMESERVER`

	FOUNDRESULTS=1
	echo "$NSRESULT" | grep -i "no answer" > /dev/null

	if [ $? -eq 0 ]; then
		FOUNDRESULTS=0
	else
		echo "$NSRESULT" | grep -i "server can't find _ldap._tcp.$DOMAIN" > /dev/null

		if [ $? -eq 0 ]; then
			FOUNDRESULTS=0
		fi
	fi

	if [ $FOUNDRESULTS -eq 0 ]; then
		echo "GC Records: No"
		echo "GC Records: No" >> $DOMAIN.dns.txt
	else
		echo "GC Records:"  >> $DOMAIN.dns.txt

		SERVERLIST=`echo "$NSRESULTS" | grep -i "_ldap._tcp.gc._msdcs.$DOMAIN" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		echo "GC's:" >> $DOMAIN.dns.txt
		echo "$SERVERLIST" >> $DOMAIN.dns.txt

		echo "$NSRESULT"  >> $DOMAIN.dns.txt

		echo "Found GC records!"
		echo "$SERVERLIST"
	fi
fi

# ------------------------- Zone Transfer ---------------------------------
echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo "Zone Transfers:" >> $DOMAIN.dns.txt
echo "Checking for zone transfers..."

for DNSIP in $NSLIST
do
	echo "Checking $DNSIP..."
	NSRESULT=`dig @$DNSIP $DOMAIN axfr`
	
	echo "$NSRESULT" | grep -i -e "transfer failed" -e "communications error" -e "no servers could be reached" > /dev/null

	if [ $? -eq 0 ]; then
		# Transfer failed.
		echo "$DNSIP: Failed" >> $DOMAIN.dns.txt
		echo "Failed"
	else
		# Transfer successful
		echo "$DNSIP: Successful" >> $DOMAIN.dns.txt
		echo "$NSRESULT" >> $DOMAIN.dns.txt
		echo "$NSRESULT" > $DOMAIN.zonetransfer.txt
		cat $DOMAIN.zonetransfer.txt | grep -vi "^;" | grep -Eio "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u > $DOMAIN.zonetransfer.uniquesubnets.txt
		echo "Zone transfer for $DOMAIN from $DNSIP successful!"
		ZONETRANSFERSUCCESSFUL=1
	fi
done

# ------------------------- Mail ---------------------------------
# MX
echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo "Mail Records:" >> $DOMAIN.dns.txt
echo "Checking for mail records..."

NSRESULT=`nslookup -type=MX $DOMAIN $NAMESERVER`

MXLIST=`echo "$NSRESULT" | grep "internet address" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
NUMSERVERS=`echo "$MXLIST" | wc -l`

if [ $NUMSERVERS -gt 0 ]; then
	echo "Mail Servers:"
    echo "$NSRESULT"
	echo ""
	echo "Mail Server IP Addresses:"
	echo "$MXLIST"

	echo "Mail Servers:" >> $DOMAIN.dns.txt
    echo "$NSRESULT" >> $DOMAIN.dns.txt
	echo "" >> $DOMAIN.dns.txt
	echo "Mail Server IP Addresses:" >> $DOMAIN.dns.txt
	echo "$MXLIST" >> $DOMAIN.dns.txt
else
	echo "No mail servers found!"
	echo "No mail servers found!" >> $DOMAIN.dns.txt
	echo "$NSRESULT" >> $DOMAIN.dns.txt
fi

# SPF
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo ""
echo "" >> $DOMAIN.dns.txt
echo "Checking for SPF record..."
NSRESULT=`nslookup -type=TXT $DOMAIN $NAMESERVER`

echo "$NSRESULT" | grep -i "no answer" > /dev/null

if [ $? -eq 0 ]; then
	echo "SPF Record: No" >> $DOMAIN.dns.txt

else
	SPFRECORD=`echo $NSRESULT | grep "spf1"`
	echo "SPF Record: Yes"  >> $DOMAIN.dns.txt
	echo "$SPFRECORD" >> $DOMAIN.dns.txt

	echo "$NSRESULT" >> $DOMAIN.dns.txt

	echo "Found SPF record: $SPFRECORD"
fi

# ------------------------- SIP Server ---------------------------------
echo ""
echo "" >> $DOMAIN.dns.txt
echo "------------------------------------------------------" >> $DOMAIN.dns.txt
echo "SIP Server Lookups:" >> $DOMAIN.dns.txt
echo "Performing SIP lookups..."
NSRESULT=`nslookup -q=SRV _SipInternalTLS._tcp.$DOMAIN $NAMESERVER`

echo "$NSRESULT" | grep -i "server can't find" > /dev/null

if [ $? -eq 0 ]; then

	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "_SipInternalTLS._tcp.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found _SipInternalTLS._tcp.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "_SipInternalTLS._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "_SipInternalTLS._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV _SipInternal._tcp.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "_SipInternal._tcp.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found _SipInternal._tcp.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "_SipInternal._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "_SipInternal._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV _Sip._tls.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	# _tls is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "_Sip._tls.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found _Sip._tls.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "_Sip._tls.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "_Sip._tls.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV _sip._tcp.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "_sip._tcp.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found _sip._tcp.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "_sip._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "_sip._tcp.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV _sipinternal.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
	# Found Record
		echo "_sipinternal.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found _sipinternal.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "_sipinternal.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "_sipinternal.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV sip.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "sip.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found sip.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "sip.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "sip.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

NSRESULT=`nslookup -q=SRV sipexternal.$DOMAIN $NAMESERVER`

if [ $? -eq 0 ]; then
	echo "$NSRESULT" | grep -i -e "no answer" -e "server can't find" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "sipexternal.$DOMAIN: Yes" >> $DOMAIN.dns.txt
		echo "Found sipexternal.$DOMAIN"
		echo "$NSRESULT"

		echo "$NSRESULT" >> $DOMAIN.dns.txt
	else
		echo "sipexternal.$DOMAIN: No" >> $DOMAIN.dns.txt
	fi
else
	echo "sipexternal.$DOMAIN: No" >> $DOMAIN.dns.txt
fi

# ------------------------- Dictionary ---------------------------------
echo ""
echo "" >> $DOMAIN.dns.txt
if [ $DICTIONARY -eq 1 ]; then
	echo "------------------------------------------------------" >> $DOMAIN.dns.txt
	echo "Dictionary Lookups:" >> $DOMAIN.dns.txt
	if [ $ZONETRANSFERSUCCESSFUL -eq 0 ]; then
		echo "Performing dictionary lookups..."
		if [ -e /opt/dnsmap/dnsmap.sh ]; then
			DICT_RESULT=`/opt/dnsmap/dnsmap.sh $NAMESERVER $DOMAIN`
		
			DICT_FINDINGS=`echo "$DICT_RESULT" | grep -v "\[" | grep -v "^$"`

			NUMRESULTS=`echo "$DICT_FINDINGS" | wc -l`

			if [ $NUMRESULTS -gt 0 ]; then
				echo "Found DNS entries:"
				echo "$DICT_FINDINGS"
				echo "$DICT_FINDINGS" > $DOMAIN.hosts.txt
				echo "Dictionary Lookup: Successful" >> $DOMAIN.dns.txt
				echo "$DICT_RESULT" >> $DOMAIN.dns.txt
			else
				echo "Dictionary Lookup: Failed.  (No results)" >> $DOMAIN.dns.txt
			fi
		else
			echo "ERROR: Unable to find /opt/dnsmap/dnsmap.sh.  Skipping dictionary lookup..."
		fi
	else
		echo "Dictionary lookups skipped because zone transfer succeded..."
		echo "Dictionary lookups skipped because zone transfer succeded..." >> $DOMAIN.dns.txt
		
	fi
else
	echo "Dictionary Lookup: Not performed" >> $DOMAIN.dns.txt
	echo "Skipping dictionary lookups..."
fi

if [ $FINDEMAIL -eq 1 ]; then
	echo "Looking up email addresses..."
	
	EMAILFILE=`echo email_addresses.$DOMAIN.txt`

#	msfcli auxiliary/gather/search_email_collector DOMAIN=$DOMAIN OUTFILE=$EMAILFILE E >> $DOMAIN.dns.txt
	msfconsole -x "use auxiliary/gather/search_email_collector; set DOMAIN $DOMAIN; set OUTFILE $EMAILFILE; exploit; exit" >> $DOMAIN.dns.txt

	if [ -e $EMAILFILE ]; then
		NUMEMAILS=`cat $EMAILFILE | wc -l`
		echo "Found $NUMEMAILS email addresses!"
		echo "Found $NUMEMAILS email addresses!" >> $DOMAIN.dns.txt

		if [ $NUMEMAILS -eq 0 ]; then
			rm $EMAILFILE
		else
			cat $EMAILFILE >> $DOMAIN.dns.txt
		fi
	else
		echo "Found 0 email addresses!"
		echo "Found 0 email addresses!" >> $DOMAIN.dns.txt
	fi
	
else
	echo "EMail Lookup: Not performed" >> $DOMAIN.dns.txt
	echo "Skipping email lookups..."
fi

DATESTR=`date`
echo ""
echo "Done [$DATESTR]."
echo "" >> $DOMAIN.dns.txt
echo "Done [$DATESTR]." >> $DOMAIN.dns.txt
echo "" >> $DOMAIN.dns.txt



