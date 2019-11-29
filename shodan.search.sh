#!/bin/bash

ShowUsage() {
	echo "$0 --key=<Shodan API Key> --ip=<ip> [--detail] [--gnmap]"
	echo "$0 will query the Shodan database regarding the specified IP."
	echo "--detail will dump the raw JSON data which can be further parsed with jq or other tools."
	echo "--gnmap  simply output the result in a sort-of gnmap format for later aggregation through nmap.FormatToCSV.sh"
	echo "Note: a shodan api key is free.  Just sign up for an account."
}


if [ $# -lt 2 ]; then
	ShowUsage
	exit 1
fi

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
		if [ -e /etc/services ]; then
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

USERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"

SEARCH=""
APIKEY=""
DUMPJSON=0
GNMAP=0

GNMAPOUTPUT=0

for i in $*
do
	case $i in
    	--ip=*)
		SEARCH=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--key=*)
		APIKEY=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--detail)
		DUMPJSON=1
		;;
	--gnmap)
		GNMAPOUTPUT=1
		;;
	*)
		ShowUsage
		exit 1
	;;
	esac
done

SHODANRESULT=`wget -nv -O- --user-agent="$USERAGENTSTRING" https://api.shodan.io/shodan/host/$SEARCH?key=$APIKEY 2>/dev/null`

if [ $DUMPJSON -eq 1 ]; then
	echo "$SHODANRESULT"
	exit 0
fi

IFS_BAK=$IFS
IFS="
"

# Can use python -mjson.tool <file> to parse JSON or download the jq executable from http://stedolan.github.io/jq/download/

HASJQ=`which jq | wc -l`

if [ $HASJQ -eq 0 ]; then
	echo "ERROR: Unable to find jq.  Please install with 'apt-get install jq'"
	exit 1
fi

FLATRESULT=`echo "$SHODANRESULT" | jq '. | {ip_str, hostnames, ports}' | tr '\n' ' '`
HOSTNAMES=`echo "$SHODANRESULT" | jq '.hostnames' | tr '\n' ' ' | sed 's|\"||g' | sed 's|\[||' | sed "s| ||g" | sed "s|\]||"`
PORTS=`echo "$SHODANRESULT" | jq '.ports' | tr '\n' ' ' | sed 's|\"||g' | sed 's|\[||' | sed "s| ||g" | sed "s|\]||" | tr ',' '\n' | sort -n`
PORTDETAIL=`echo "$SHODANRESULT" | jq '. | {data}' | jq '.[]' | jq '.[] | {port,transport,timestamp}'`
VULNS=`echo "$SHODANRESULT" | jq '.vulns'| tr '\n' ' ' | sed "s|\[||" | sed  s"|\]||" | sed 's|\"||g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
OS=`echo "$SHODANRESULT" | jq '.os'`

HOSTLOCATION=`echo "$SHODANRESULT" | jq '. | {data}' | jq '.[]' | jq '.[0] | {ip: .ip_str, isp, city: .location.city, state: .location.region_code, country: .location.country_code}' | sed "s|\"||g" | sed "s|,$||g"`

PORTRESULTS=`echo "$SHODANRESULT" | jq '. | {data}' | jq '.[]' | jq '.[] | {port,transport,timestamp}'`
PORTDATA=`echo "$PORTRESULTS" | tr '\n' ' ' | sed "s|} {|\n|g" | sed "s|\"port\": ||g" | sed "s|\"transport\": ||g" | sed "s|\"timestamp\": ||g" | tr '}' '\n' | sed "s|{\s||" | sed "s| ||g" | sed "s|\"||g" | sed "s|,|/|g" | sort -n`

for CURPORT in $PORTS
do
	HASPORT=`echo "$PORTDATA" | grep "^$CURPORT\/" | grep -v "^$" | wc -l`

	if [ $HASPORT -eq 0 ]; then
		# Port was in port list, but no details, so add it.
		PORTDATA=`echo -e "$PORTDATA\n$CURPORT//"`
	fi
done

if [ $GNMAPOUTPUT -eq 0 ]; then
	echo -n Hostname, HOST, OS Guess,
	for CURPORT in $PORTS
	do
		PORTOUTPUT=`echo "$CURPORT" | sed "s|\/.*||"`
		OutputServiceName $PORTOUTPUT
	done

	echo -n vulnerabilities
	echo ""

	# HOST Name
	echo -n \"$HOSTNAMES\",

	# Host IP
	echo -n $SEARCH,

	for CURPORT in $PORTS
	do
		echo -n \"$CURPORT\",
	done

	echo \"$VULNS\"
else
	HOSTISP=`echo "$HOSTLOCATION" | grep "isp" | sed "s|  isp:||"`
	CITY=`echo "$HOSTLOCATION" | grep "city" | sed "s|  city:||"`
	STATE=`echo "$HOSTLOCATION" | grep "state" | sed "s|  state:||"`
	COUNTRY=`echo "$HOSTLOCATION" | grep "country" | sed "s|  country:||"`

	echo -n "Host: $SEARCH ()	Ports: "
	for CURPORT in $PORTDATA
	do
		WRITEDATA=`echo "$CURPORT" | sed "s|/|/open/|"`
		echo -n "$WRITEDATA//, "
	done

	echo "OS: $HOSTISP:$CITY:$STATE:$COUNTRY Seq Index: 0"
#	echo ""
fi

IFS=$IFS_BAK
IFS_BAK=

