#!/bin/bash

cd /root

OUTPUTPREFIX=""
if [ $# -gt 0 ]; then
	OUTPUTPREFIX="$1"
else
	OUTPUTPREFIX="default"
fi

if [ $# -gt 1 ]; then
	OUTPUTFILE="$2"
	LOGTOFILE=1
else
	LOGTOFILE=0
	OUTPUTFILE=""
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
fi

USEBLINK=0

if [ -e /usr/local/bin/blink1-tool ]; then
	HASBLINK=`blink1-tool --list | grep "^id" | wc -l`
	
	if [ $HASBLINK -gt 0 ]; then
		USEBLINK=1

		if [ $LOGTOFILE -eq 1 ]; then
			echo "[`date`] Info: Using blink for process visualization..." >> $OUTPUTFILE
		else
			echo "[`date`] Info: Using blink for process visualization..."
		fi
	fi
fi


# Colors:
# Red - Starting
# magenta - starting firewall port checks
# Yellow
# cyan
# Green

if [ $USEBLINK -ge 1 ]; then
	blink1-tool --red
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Ethernet Configuration..." >> $OUTPUTFILE
	/sbin/ifconfig >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Ethernet Configuration..."
	/sbin/ifconfig
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] DNS Resolution..." >> $OUTPUTFILE
	cat /etc/resolv.conf  >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] DNS Resolution..."
	cat /etc/resolv.conf 
fi

DOMAINNAME=`cat /etc/resolv.conf | grep "^domain" | sed "s|^domain ||"`
if [ ${#DOMAINNAME} -eq 0 ]; then
	DOMAINNAME="unknown"
fi

NAMESERVER=`cat /etc/resolv.conf | grep "^nameserver" | head -1 | sed "s|^nameserver ||"`

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Routing Table..." >> $OUTPUTFILE
	route -n >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Routing Table..."
	route -n
fi

DEFROUTE_INT=`route -n | grep "^0.0.0.0" | grep -v "tun[0-9]" | head -1 | awk '{print $8}'`

if [ ${#DEFROUTE_INT} -eq 0 ]; then
	if [ $LOGTOFILE -eq 1 ]; then
		echo "ERROR: unable to identify default route adapter from routing table." >> $OUTPUTFILE
		echo "Default route:" >> $OUTPUTFILE
		route -n | grep "^0.0.0.0" >> $OUTPUTFILE
	else
		echo "ERROR: unable to identify default route adapter from routing table."
		echo "Default route:"
		route -n | grep "^0.0.0.0"
	fi

	exit 1
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Proxy Check..." >> $OUTPUTFILE
	http.check_proxy.sh >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Proxy Check..."
	http.check_proxy.sh
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] VPN Connection..." >> $OUTPUTFILE
	netstat -auntp | grep -i openvpn >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] VPN Connection..."
	netstat -auntp | grep -i openvpn
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Anti-virus check..." >> $OUTPUTFILE
	av.check-via-dns.sh $NAMESERVER >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Anti-virus check..."
	av.check-via-dns.sh $NAMESERVER
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Active Directory DC's..." >> $OUTPUTFILE
	DCNAMES=`dns.lookup.DCs.sh $DOMAINNAME | grep -Eio "=.*" | sed "s|= ||g" | sed "s|\.$||g"
	for CURNAME in $DCNAMES; do dns.lookup.name.sh $CURNAME >> $OUTPUTFILE;done

	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Active Directory GC's..." >> $OUTPUTFILE
	DCNAMES=`dns.lookup.GCs.sh $DOMAINNAME | grep -Eio "=.*" | sed "s|= ||g" | sed "s|\.$||g"
	for CURNAME in $DCNAMES; do dns.lookup.name.sh $CURNAME >> $OUTPUTFILE;done
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Active Directory DC's..."
	DCNAMES=`dns.lookup.DCs.sh $DOMAINNAME | grep -Eio "=.*" | sed "s|= ||g" | sed "s|\.$||g"
	for CURNAME in $DCNAMES; do dns.lookup.name.sh $CURNAME;done
	echo "--------------------------------------------------------------"
	echo "[`date`] Active Directory GC's..."
	DCNAMES=`dns.lookup.GCs.sh $DOMAINNAME | grep -Eio "=.*" | sed "s|= ||g" | sed "s|\.$||g"
	for CURNAME in $DCNAMES; do dns.lookup.name.sh $CURNAME;done
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Firewall Outbound Port Check..." >> $OUTPUTFILE
	nmap -Pn -n -sT --max-retries 1 portquiz.net >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Firewall Outbound Port Check..."
	nmap -Pn -n -sT --max-retries 1 portquiz.net
fi

if [ $USEBLINK -ge 1 ]; then
	blink1-tool --magenta
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Private Subnets..." >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Private Subnets..."
fi

# nmap.SearchForAllPrivateGateways.sh /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt
# For debug purposes...
# echo "Found 192.168.113.1" > /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt

#if [ $LOGTOFILE -eq 1 ]; then
#	cat /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt >> $OUTPUTFILE
#else
#	cat /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt
#fi

if [ $USEBLINK -ge 1 ]; then
	blink1-tool --yellow
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Packet Capture..." >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Packet Capture..."
fi

if [ -e /PenTests ]; then
	timeout 5m /usr/sbin/tcpdump -nqi $DEFROUTE_INT -w /PenTests/$DOMAINNAME.$OUTPUTPREFIX.cap
else
	timeout 5m /usr/sbin/tcpdump -nqi $DEFROUTE_INT -w /root/$DOMAINNAME.$OUTPUTPREFIX.cap
fi

if [ $USEBLINK -ge 1 ]; then
	blink1-tool --cyan
fi

if [ $LOGTOFILE -eq 1 ]; then
	echo "--------------------------------------------------------------" >> $OUTPUTFILE
	echo "[`date`] Server Port Scan..." >> $OUTPUTFILE
else
	echo "--------------------------------------------------------------"
	echo "[`date`] Server Port Scan..."
fi

# Server subnet will be one that has the name server(s) in it.  Grab 1st 3 octets
NAMESERVERSUBNETS=`cat /etc/resolv.conf | grep "^nameserver" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
SERVERSUBNET=`echo "$NAMESERVERSUBNETS" | head -1`

IFS_BAK=$IFS
IFS="
"

for CURNAMESERVERSUBNET in $NAMESERVERSUBNETS
do
	if [ -e  /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt ]; then

		cat /root/$DOMAINNAME.$OUTPUTPREFIX.gateways.txt | grep -q "$CURNAMESERVERSUBNET"
		if [ $? -eq 0 ]; then
			SERVERSUBNET="$CURNAMESERVERSUBNET"
			break
		fi
	fi
done

if [ ${#SERVERSUBNET} -gt 0 ]; then
	cd /root

	if [ $LOGTOFILE -eq 1 ]; then
		echo "[`date`] nmap scanning $SERVERSUBNET.0/24..." >> $OUTPUTFILE
	else
		echo "[`date`] nmap scanning $SERVERSUBNET.0/24..."
	fi

# Skip for debug
	nmap.CustomPortScan.sh $SERVERSUBNET.0/24 $DOMAINNAME.$OUTPUTPREFIX --no-microsoft --ping-first
fi

IFS=$IFS_BAK
IFS_BAK=

if [ $LOGTOFILE -eq 1 ]; then
	echo "[`date`] Done." >> $OUTPUTFILE
else
	echo "[`date`] Done."
fi

if [ $USEBLINK -ge 1 ]; then
	blink1-tool --green
fi

if [ -e /sys/class/leds/led0 ]; then
	# We're on a pi
	rpi.green_led_on.sh
	rpi.notify_on_status.sh "[`date`] Scan complete."
fi
