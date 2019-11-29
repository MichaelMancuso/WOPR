#!/bin/sh
ShowUsage() {
	echo ""
	echo "Usage: $0 <domain name> [Server IP]"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

DOMAIN="$1"
NAMESERVER=""

if [ $# -gt 1 ]; then
	NAMESERVER="$2"
fi

if [ ${#DOMAIN} -eq 0 ]; then
	echo "No domain name provided."
	echo ""

	ShowUsage
	exit 2
fi

echo "Performing SIP lookups..."
NSRESULT=`nslookup -q=SRV _SipInternalTLS._tcp.$DOMAIN $NAMESERVER`

echo "$NSRESULT" | grep -i "server can't find" > /dev/null

if [ $? -gt 0 ]; then

	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i "no answer" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "Found _SipInternalTLS._tcp.$DOMAIN"
		echo "$NSRESULT"
	else
		echo "_SipInternalTLS._tcp.$DOMAIN: No"
	fi
else
	echo "_SipInternalTLS._tcp.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV _SipInternal._tcp.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i "no answer" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "Found _SipInternal._tcp.$DOMAIN"
		echo "$NSRESULT"
	else
		echo "_SipInternal._tcp.$DOMAIN: No"
	fi
else
	echo "_SipInternal._tcp.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV _Sip._tls.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# _tls is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i "no answer" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "Found _Sip._tls.$DOMAIN"
		echo "$NSRESULT"
	else
		echo "_Sip._tls.$DOMAIN: No"
	fi
else
	echo "_Sip._tls.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV _sip._tcp.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# _tcp is a subdomain.  May also get a "no answer" in response.
	echo "$NSRESULT" | grep -i "no answer" > /dev/null

	if [ $? -gt 0 ]; then
		# Found Record
		echo "Found _sip._tcp.$DOMAIN"
		echo "$NSRESULT"
	else
		echo "_sip._tcp.$DOMAIN: No"
	fi
else
	echo "_sip._tcp.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV _sipinternal.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# Found Record
	echo "Found _sipinternal.$DOMAIN"
	echo "$NSRESULT"
else
	echo "_sipinternal.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV sip.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# Found Record
	echo "Found sip.$DOMAIN"
	echo "$NSRESULT"
else
	echo "sip.$DOMAIN: No"
fi

NSRESULT=`nslookup -q=SRV sipexternal.$DOMAIN $NAMESERVER`

if [ $? -gt 0 ]; then
	# Found Record
	echo "Found sipexternal.$DOMAIN"
	echo "$NSRESULT"
else
	echo "sipexternal.$DOMAIN: No"
fi

