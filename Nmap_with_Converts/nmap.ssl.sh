#!/bin/bash

# Functions
# --------------------------------
ShowUsage() {
	echo ""
	echo "$0 Usage: $0 [--help] [--proxychains] [-v] [--detail] [--file=<host file>] | <host>"
	echo ""
	echo ""
	echo "$0 scans the specified host or hosts and extracts the certificate's common name."
	echo ""
  	echo -e "\033[1mParameters:\033[0m"
	echo "--help 		This help screen"
	echo "-v		Be verbose"
	echo "--short		Show common name and IP address"
	echo "--detail		Show common name, IP, expiration date, ciphers"
	echo "--file=<file>	Read multiple hosts in from specified file. Host can be <name or ip>[:port]"
	echo "--proxychains	Use proxychains to make calls."
	echo "<host>		Host to scan.  Either provide --file or hostname. Host can be <name or ip>[:port]"
	echo ""

}

ShowMessage() {
	if [ $# -lt 2 ]; then
		echo "ERROR in ShowMessage call.  Please provide message and Verbose flag." 
		exit 4
	fi

	MESSAGE=`echo "$1"`
	VERBOSE=$2

	if [ $VERBOSE -eq 1 ]; then
		echo "$MESSAGE" >&2
	fi
}

# MAIN
# ------------------------------------------

# GLOBALS
VERBOSE=0
SHOWDETAIL=0
SHOWSHORT=0
HOSTFILE=""
HOSTS=""
FROMFILE=0
SSLTHING=1

SSLTHINGEXE="`which sslthing-updated.sh`"
if [ ${#SSLTHINGEXE} -eq 0 ]; then
	SSLTHINGEXE="/usr/bin/sslthing-updates.sh"
fi

OSTYPE=`uname`
PROXYCHAINS=""

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

# Note this part just pulls the cert fields.  No need for the other cipher
# one here.  That's in sslthing-updated.sh
OPENSSLEXE="openssl"

# Parse parameters
if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	-v)
		VERBOSE=1
	;;
	--short)
		SHOWSHORT=1
	;;
	--detail)
		SHOWDETAIL=1
	;;
	--proxychains)
		PROXYCHAINS="proxychains"
	;;
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

if [ ! -e $SSLTHINGEXE ]; then
	if [ -e /usr/local/bin/scripts/sslthing-updated.sh ]; then
	   echo "Warning: Updated sslthing (sslthing-updated.sh) could not be located.  Using standard sslthing.sh."
	   SSLTHINGEXE="/usr/local/bin/sslthing-updated.sh"
	else
	   echo "Warning: Unable to locate sslthing-updated.sh or sslthing.sh.  SSL cipher testing disabled."
	   SSLTHING=0
	fi
fi

# Display run settings
if [ $VERBOSE -eq 1 ]; then
	if [ $FROMFILE -eq 1 ]; then
		echo "Scanning:"
		echo "$HOSTS"		
	else
		echo "Scanning $HOSTS..."
	fi
fi

CURDIR=`pwd`
TMPCERTFILE="/tmp/nmap.ssl.cert.tmp"
TMPCIPHERFILE="/tmp/nmap.ssl.ciphers.tmp"

if [ $SHOWDETAIL -eq 1 ]; then
	echo -e "Common Name\tIP Address\tPort\tIssuer\tExpiration\tSupported Ciphers"
fi

for CURHOST in $HOSTS
do
	HOSTADDR=`echo "$CURHOST" | grep -Eo ".*?:" | sed "s|:||"`
	if [ ${#HOSTADDR} -eq 0 ]; then
		# Host does not contain port.  Use std 443
		HOSTADDR=$CURHOST
		SSLPORT=443
	else
		SSLPORT=`echo "$CURHOST" | grep -Eo ":.*" | sed "s|:||"`

		if [ ${#SSLPORT} -eq 0 ]; then
			echo "WARNING: Unable to find SSL port from $CURHOST specifier.  Using 443..."
			SSLPORT=443
		fi
	fi

	echo "$HOSTADDR" | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" > /dev/null

	if [ $? -eq 0 ]; then
		ISIP=1
		HOSTIP=$HOSTADDR
	else
		ISIP=0

		# NSLookup IP
		ShowMessage "Looking up $HOSTADDR" $VERBOSE
		HOSTIP=`nslookup $HOSTADDR | grep -e "^Name" -e "^Address:" | grep -v "#53" | tr '\n' '\t' | sed "s|Name:\s||" | sed "s|Address:\s||" | sed "s|\sName:\s|\n|g" | sed "s|\sAddress:\s|\t|g"`
		HOSTIP=`echo "$HOSTIP" | head -1 | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
		ShowMessage "Found $HOSTADDR at $HOSTIP" $VERBOSE
	fi

	if [ -e $TMPCERTFILE ]; then
		rm -rf $TMPCERTFILE
	fi

	ShowMessage "Dumping certificate info for $HOSTADDR (on port $SSLPORT)..." $VERBOSE

	$PROXYCHAINS $OPENSSLEXE s_client -connect $HOSTIP:$SSLPORT 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $TMPCERTFILE &
	sleep 2

	if [ $ISLINUX -eq 1 ]; then
		# clean up openssl processes... they have a really long timeout
		OPENSSLPROC=`ps -A | grep "openssl" | grep -Eo "^.*? pts" | sed "s|pts||" | sed "s| ||g" | grep -v "^$"`

		for OSSLPROC in $OPENSSLPROC
		do
			kill $OSSLPROC > /dev/null
		done
	else
		# clean up openssl processes... they have a really long timeout
		OPENSSLPROC=`ps | grep "openssl" | grep -Eo "^     [0-9]{1,5}" | sed "s| ||g" | grep -v "^$"`

		for OSSLPROC in $OPENSSLPROC
		do
			kill $OSSLPROC > /dev/null
		done
	fi

	if [ -e $TMPCERTFILE ]; then
		ShowMessage "Got certificate.  Extracting info..." $VERBOSE

		ShowMessage "Common name..." $VERBOSE
		# Common Name
		CERTCN=`cat $TMPCERTFILE | $OPENSSLEXE x509 -noout -subject | grep -Eo "CN=.*?$" | sed "s|CN=||"`

		if [ $SHOWDETAIL -eq 1 ]; then
			# Expiration
			DATESTR=`cat $TMPCERTFILE | $OPENSSLEXE x509 -noout -dates | grep -Eo "notAfter.*?$" | sed "s|notAfter=||"`
			CERTEXPIRES=`date -d "$DATESTR" '+%m/%d/%Y %I:%M %p %Z'`
		else
			CERTEXPIRES=""
		fi

		# Issuer
		ShowMessage "Issuer..." $VERBOSE
		ISSUER=""
		if [ $SHOWDETAIL -eq 1 ]; then
			ISSUER=`cat $TMPCERTFILE | $OPENSSLEXE x509 -noout -issuer | grep -Eo "CN=.*?\/" | sed "s|CN=||" | sed "s|\/||"`
		fi

		ShowMessage "Ciphers..." $VERBOSE
		# Ciphers
		CIPHERS=""
		if [ $SSLTHING -eq 1 -a $SHOWDETAIL -eq 1 ]; then
			if [ -e $TMPCIPHERFILE ]; then
				rm -rf $TMPCIPHERFILE
			fi

			$PROXYCHAINS $SSLTHINGEXE $HOSTIP:$SSLPORT &>$TMPCIPHERFILE

			if [ -e $TMPCIPHERFILE ]; then
				TMPRESULTS=`cat $TMPCIPHERFILE | sed "s|Testing SSL2\.\.\.|SSLv2:|" | sed "s|Testing SSL3\.\.\.|SSLv3:|" | sed "s|Testing TLS1\.\.\.|TLSv1:|" | sed "s|SSL2|SSLv2|" | sed "s|SSL3|SSLv3|" | sed "s|TLS1|TLSv1|"`
				echo "$TMPRESULTS" | grep "ssl method passed:ssl_lib\.c" > /dev/null

				if [ $? -eq 0 ]; then
					# SSLv2 not supported
					TMPRESULTS=`echo "$TMPRESULTS" | sed "s|^.*error.*ssl method passed:ssl_lib.*$|Unsupported by installed openssl library \(this was changed in the latest release\)|"`
				fi

				echo "$TMPRESULTS" > $TMPCIPHERFILE

				ShowMessage "`cat $TMPCIPHERFILE`" $VERBOSE
				CIPHERS=`cat $TMPCIPHERFILE | tr '\n' ',' | sed "s|SSLv2:,SSLv3|SSLv2: None, SSLv3|" | sed "s|SSLv3:,TLS|SSLv3: None, TLS|" | sed "s|SSLv2:,Unsup|SSLv2: Unsup|" | sed "s|SSLv3:,|SSLv3: |" | sed "s|TLSv1:,|TLSv1: |" | sed "s|,$||"`
				rm -rf $TMPCIPHERFILE
			fi
		fi

		if [ $SHOWSHORT -eq 1 ]; then
			echo -e "$CERTCN\t$HOSTIP"
		else
			if [ $SHOWDETAIL -eq 1 ]; then
				echo -e "$CERTCN\t$HOSTIP\t$SSLPORT\t$ISSUER\t$CERTEXPIRES\t$CIPHERS"
			else
				echo "$CERTCN"
			fi
		fi
	else
		echo "ERROR: Unable to dump certificate for $CURHOST."
	fi

done

# Clean up tmp file.
if [ -e $TMPCERTFILE ]; then
	rm -rf $TMPCERTFILE
fi


