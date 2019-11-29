#!/bin/bash

ShowUsage() {
	echo ""
	echo "$0 Usage: $0 [--file=<host file>] | <host>"
	echo ""
	echo ""
	echo "$0 scans the specified host or hosts and lists all enabled ciphers.  However because the native openssl that is used by nmap does not include SSLv2 support, 2 separate tools are required to produce a complete list."
	echo ""
  	echo -e "\033[1mParameters:\033[0m"
	echo "--file=<file>	Read multiple hosts in from specified file. Host can be <name or ip>[:port]"
	echo "<host>		Host to scan.  Either provide --file or hostname. Host can be <name or ip>[:port]"
	echo ""

}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

HOSTFILE=""
HOSTS=""
FROMFILE=0

for i in $*
do
	case $i in
    	--file=*)
		HOSTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		FROMFILE=1
	;;
	*)
		HOSTS=$i
	esac
done

# Perform safety and setting checks
if [ ${#HOSTFILE} -eq 0 -a ${#HOSTS} -eq 0 ]; then
	echo "ERROR:  Please either specify a host to scan or a file of hosts."
	echo ""
	exit 2
fi

if [ $FROMFILE -eq 1 ]; then
	if [ ! -e $HOSTFILE ]; then
		echo "ERROR: Unable to find file $HOSTFILE"
		exit 3
	fi

	HOSTS=`cat $HOSTFILE | grep -Ev -e "^$" -e "^#"`
fi

echo "[`date`] Running detailed cipher tests..."
if [ $FROMFILE -eq 1 ]; then
	nmap.ssl.sh --detail --file=$HOSTFILE
	HOSTS=`cat $HOSTFILE | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tr '\n' ',' | sed "s|,$||"`
	PORTS=`cat $HOSTFILE | grep -Eo ":[0-9]{1,}" | sed "s|:||g" | sort -n | tr '\n' ',' | sed "s|,$||"`

	if [ ${#PORTS} -eq 0 ]; then
		PORTS=443
	fi

	nmap -Pn -n -p $PORTS --script=+ssl-enum-ciphers $HOSTS
else
	nmap.ssl.sh --detail $HOSTS

	HOSTS=`echo "$HOSTS" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | tr '\n' ',' | sed "s|,$||"`
	PORTS=`echo "$HOSTS" | grep -Eo ":[0-9]{1,}" | sed "s|:||g" | sort -n | tr '\n' ',' | sed "s|,$||"`

	if [ ${#PORTS} -eq 0 ]; then
		PORTS=443
	fi

	nmap -Pn -n -p $PORTS --script=+ssl-enum-ciphers $HOSTS
fi

