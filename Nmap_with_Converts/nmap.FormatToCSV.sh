#!/bin/bash

ShowUsage() {
	echo "$0 converts an nmap gnmap output file to an importable csv"
	echo ""
	echo "Usage: $0 <nmap gnmap file> [Optional DNS Name to IP File]"
	echo "If a dns/ip file is provided, the IP will be searched in the file"
	echo "and the dns name included in the output."
}

OutputServiceName() {
	SVCNAME=""
	case $1 in
	21)
		SVCNAME="FTP"
	;;
	22)
		SVCNAME="SSH"
	;;
	23)
		SVCNAME="Telnet"
	;;
	25)
		SVCNAME="SMTP"
	;;
	53)
		SVCNAME="DNS"
	;;
	80)
		SVCNAME="HTTP"
	;;
	110)
		SVCNAME="POP3"
	;;
	143)
		SVCNAME="IMAP"
	;;
	161)
		SVCNAME="SNMP"
	;;
	179)
		SVCNAME="PGP"
	;;
	443)
		SVCNAME="HTTPS"
	;;
	123)
		SVCNAME="NTP"
	;;
	161)
		SVCNAME="SNMP"
	;;
	515)
		SVCNAME="LPR"
	;;
	587)
		SVCNAME="SMTP/Submission"
	;;
	990)
		SVCNAME="ftps"
	;;
	993)
		SVCNAME="imaps"
	;;
	902)
		SVCNAME="VMWare Auth"
	;;
	995)
		SVCNAME="pop3s"
	;;
	1080)
		SVCNAME="socks proxy"
	;;
	1433)
		SVCNAME="MS SQL Server"
	;;
	1434)
		SVCNAME="MS SQL Server"
	;;
	1521)
		SVCNAME="Oracle Listener"
	;;
	1522)
		SVCNAME="Oracle Listener"
	;;
	1720)
		SVCNAME="H.323"
	;;
	1723)
		SVCNAME="PPTP"
	;;
	2000)
		SVCNAME="SCCP (Cisco Skinny)"
	;;
	3128)
		SVCNAME="Squid Proxy"
	;;
	3260)
		SVCNAME="iSCSI Target"
	;;
	3306)
		SVCNAME="MySQL"
	;;
	3389)
		SVCNAME="RDP"
	;;
	5060)
		SVCNAME="SIP"
	;;
	5061)
		SVCNAME="SIP-TLS"
	;;
	5432)
		SVCNAME="Postgresql"
	;;
	5800)
		SVCNAME="VNC-HTTP"
	;;
	5900)
		SVCNAME="VNC"
	;;
	8080)
		SVCNAME="Tomcat or Proxy"
	;;
	9100)
		SVCNAME="RAW-Print"
	;;
	9990)
		SVCNAME="JBoss Management Console"
	;;
	10000)
		SVCNAME="NAT-T"
	;;
	*)
	# Look up in service file if it exists
		if [ ${#SVCNAME} -eq 0 -a -e /etc/services ]; then
			SVCNAME=`cat /etc/services | grep -Ei "\s$1\/" | sed "s|\s.*$||" | head -1`
		fi
	;;
	esac

	if [ ${#SVCNAME} -gt 0 ]; then
		echo -n \"$SVCNAME \($1\)\",
	else
		echo -n \" $1\",
	fi
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

NMAPFILE=$1
DNSFILE=""
if [ $# -gt 1 ]; then
	DNSFILE=$2
fi

if [ ! -e $NMAPFILE ]; then
	echo "ERROR: Unable to locate $NMAPFILE"
	exit 2
fi

if [ ${#DNSFILE} -gt 0 ]; then
	USEDNSFILE=1
	if [ ! -e $DNSFILE ]; then
		echo "ERROR: Unable to find dns file $DNSFILE"
		exit 2
	fi
else
	USEDNSFILE=0
fi

# HOSTENTRIES=`cat $NMAPFILE  | grep  -i "Ports: " | grep -i "/open/" | sed "s|Seq Index.*$||g"`
HOSTENTRIES=`cat $NMAPFILE  | grep  -i "Ports: " | grep -i "/open/"`
ACTIVEHOSTS=`echo "$HOSTENTRIES" | grep -o -E "Host: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "^$" | sort -u`
NUMACTIVEHOSTS=`echo "$ACTIVEHOSTS"  | grep -v "^$" | wc -l`
UNIQUEPORTS=`cat $NMAPFILE | grep -Eio "[0-9]{1,5}/open/" | sort -nu`
NUMUNIQUEPORTS=`echo "$UNIQUEPORTS" | grep -v "^$" | wc -l`

which geoiplookup > /dev/null

if [ $? -gt 0 ]; then
	echo "[`date`] geoiplookup missing.  Installing geoip-bin..." >&2
	
	apt-get -y install geoip-bin
fi

if [ ! -e /usr/share/GeoIP/GeoLiteCity.dat ]; then
	echo "[`date`] GeoIP databases missing.  Getting latest..." >&2
	
	CURDIR=`pwd`

	cd /tmp

	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
	wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
	wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
	gunzip GeoIP.dat.gz
	gunzip GeoIPASNum.dat.gz
	gunzip GeoLiteCity.dat.gz
	cp GeoIP.dat GeoIPASNum.dat GeoLiteCity.dat /usr/share/GeoIP/ 

	cd $CURDIR
fi

echo "Found $NUMACTIVEHOSTS hosts with $NUMUNIQUEPORTS unique ports open..." >&2
if [ $USEDNSFILE -eq 1 ]; then
	echo "Generating csv output and cross-referencing IP addresses with $DNSFILE..." >&2
else
	echo "Generating csv output..." >&2
fi

# echo "Hosts: " >&2
# echo "$ACTIVEHOSTS" >&2
# echo "Ports: " >&2
# echo "$UNIQUEPORTS" >&2

# Loop through each host entry
# Loop through each port.  If found, extract the entry and write it
# preceded by a comma, else just write a comma

# Change whitespace to a new line
IFS_BAK=$IFS
IFS="
"

# if [ $USEDNSFILE -eq 1 ]; then
#	echo -n Hostname,
# fi
echo -n Hostname, HOST, ISP and GeoLocation,
for CURPORT in $UNIQUEPORTS
do
	PORTOUTPUT=`echo "$CURPORT" | sed "s|\/.*||"`
	OutputServiceName $PORTOUTPUT
done

echo ""

# Original This loop assumed that all ports for a host are on a single line
# Now cycle through by active IP...

#for CURENTRY in $HOSTENTRIES
for CURHOST in $ACTIVEHOSTS
do
	# Removed for loop-by-active-IP
#	CURHOST=`echo "$CURENTRY" | grep -o -E "Host: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

	if [ $USEDNSFILE -eq 1 ]; then
		# Search for IP

		SEARCHSTR=`echo "$CURHOST" | sed 's|\.|\\\.|g'`
		cat $DNSFILE | sed "s|\s$||g" | grep -Ei "$SEARCHSTR$" > /dev/null

		if [ $? -eq 0 ]; then
		# Extract hostname
			HOSTENTRY=`cat $DNSFILE | sed "s|\s$||g" | grep -Ei --max-count=1 "$SEARCHSTR$" | sed "s|\t| |g" | sed "s| .*$||g"`
		else
			HOSTENTRY=""
		# if not found, just write ""
		fi

		# HOST Name
		echo -n \"$HOSTENTRY\",

		# Host IP
		echo -n $CURHOST,
	else
		# Host IP
		echo -n \"N/A\",$CURHOST,
	fi

	# Changed / added to support multiple host entries w different ports
	CURENTRY=`echo "$HOSTENTRIES" | grep " $CURHOST " | grep -Eio "Ports:.*" | sed "s|Ports:||g" | tr '\n' ',' | sed "s|,$||"`
	
	# Find OS type
	#OSTYPE=`echo "$CURENTRY" | grep -Eo "OS: .*Seq Index" | head -1 | sed "s|OS: ||" | sed "s|Seq Index||"`
	#echo -n \"$OSTYPE\",

	# Updated 2/29/2016 - Changed OS to ISP and GeoLocation
	#OSTYPE=`echo "$CURENTRY" | grep -Eo "OS: .*Seq Index" | head -1 | sed "s|OS: ||" | sed "s|Seq Index||"`
	#echo -n \"$OSTYPE\",

	ISPRIVATE=`echo "$CURHOST" | grep -E "(^127\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)" | grep -v "^$" | wc -l`

	if [ $ISPRIVATE -eq 1 ]; then
		COUNTRYSHORT="RFC1918 Private"
		COUNTRYLONG="N/A"
	else
		if [ -e /usr/share/GeoIP/GeoIP.dat ]; then
			COUNTRYSHORT=`geoiplookup -f /usr/share/GeoIP/GeoIP.dat $CURHOST 2>&1 | grep "GeoIP Country Edition:" | sed "s|GeoIP Country Edition: ||" | cut -f2 -d","`
		else
			COUNTRYSHORT="No GeoIP database"
		fi

		if [ -e /usr/share/GeoIP/GeoLiteCity.dat ]; then
			COUNTRYLONG=`geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $CURHOST | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
		else
			COUNTRYLONG="N/A"
		fi

		if [ -e /usr/share/GeoIP/GeoIPASNum.dat ]; then
			ISP=`geoiplookup -f /usr/share/GeoIP/GeoIPASNum.dat $CURHOST | sed "s|^GeoIP .*: ||" | cut -f1-4 -d"," | sed "s|, (null)||g"`
		else
			ISP="No ISP database"
		fi
	fi

	COUNTRY=`echo "$COUNTRYSHORT, $COUNTRYLONG" | sed "s|^ ||g"`
	echo -n \"$ISP \($COUNTRY\)\",

	for CURPORT in $UNIQUEPORTS
	do
		SEARCHSTR=`echo "$CURPORT"  | sed  's|\/|\\\/|'`
		# Needed to add a space before $CURENTRY to get search to work correctly
		echo " $CURENTRY" | grep " $SEARCHSTR" > /dev/null

		if [ $? -eq 0 ]; then
			echo " $CURENTRY" | grep -Eio " $SEARCHSTR.*?,"  > /dev/null
			# Found with others
			if [ $? -eq 0 ]; then
				PORTOUTPUT=`echo " $CURENTRY" | grep -Eio " $SEARCHSTR.*?\/\," | head -1 | sed "s|\t||g" | sed "s|, .*?$||" | sed "s|,$||" | sed "s|^ ||"`
				PORTOUTPUT=`echo "$PORTOUTPUT" | sed "s|, .*$||"`
			else
				PORTOUTPUT=`echo " $CURENTRY" | grep -Eio " $SEARCHSTR.*?$" | head -1 | sed "s|^ ||"`
			fi
		else
			PORTOUTPUT=""
		fi

		PORTOUTPUT=`echo "$PORTOUTPUT" | sed "s|\t||"`
		echo -n \"$PORTOUTPUT\",
	done

	echo ""
done

# Change whitespace back
IFS=$IFS_BAK
IFS_BAK=

