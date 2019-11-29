#!/bin/sh
ShowUsage() {
	echo "Usage: $0 --server=<servername/ip> [--port=<port>] [--usessl] [--nogoogle] [--nonmap] [--nodirbuster]"
	echo "          [--dirbuster-maxtime=<sec>] [--alt-root=<alt root>]"
	echo ""
	echo "$0 will run the following web application related tests:"
	echo ""
	echo "Google for the server name and extract all URL's"
	echo "Download robots.txt and sitemap.xml if available."
	echo "Mirror the site code locally."
	echo "Run nmap against the specified server."
	echo "Run nikto against the specified server and convert to CSV output."
	echo "Run dirbuster against the specified server."
	echo "If ssl is specified, the certificate and transforms will be analyzed."
	echo ""
	echo "--server=<servername/ip>     name or IP address of the system"
	echo "--alt-root=<alt root>        To start application queries at a certain location such as"
	echo "                             /app/myapp/ specify /app/myapp/ as an alternate root."
	echo "--port=<port>                If the app is on a non-standard port, provide the port here"
	echo "--usessl                     If the app should be queried over SSL set this option"
	echo "--nogoogle		   Google queries for the server/app are done by default.  Set"
	echo "--nonmap			   Server will usually be nmap scanned for configuration / listening"
	echo "                             ports.  If this should not be done, set this parameter."
	echo "                             this parameter to disable those checks."
	echo "--nodirbuster                Dirbuster will be run against the URL by default.  Set this to disble it."
	echo "--dirbuster-maxtime=<sec>    Dirbuster will run for a maxmimum of 5 hours by default (18000 sec)."
	echo "                             This can be adjusted with this parameter."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

if [ $ISLINUX -eq 1 ]; then
#  Must be superuser
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root.  Please use sudo $0 to run."
	   exit 2
	fi
fi

ALTROOT=""
PORT=80
SSL=0
HTTPPREFIX="http:"
GOOGLE=1
RUNNMAP=1
DIRBUSTER=1
DIRBUSTER_MAXTIME="18000"
SERVERNAME=""

for i in $*
do
	case $i in
    	--server=*)
		SERVERNAME=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--alt-root=*)
		ALTROOT=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
		;;
    	--port=*)
		PORT=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--usessl)
		SSL=1
		HTTPPREFIX="https:"
	;;
	--nogoogle)
		GOOGLE=0
	;;
	--nonmap)
		RUNNMAP=0
	;;
	--help)
		ShowUsage
		exit 1
	;;
	--nodirbuster)
		DIRBUSTER=0
	;;
	--dirbuster-maxtime=*)
		DIRBUSTER_MAXTIME=`echo "$i" | sed 's/[-a-zA-Z0-9]*=//'`
	;;
	*)
		echo "ERROR: Unknown parameter: $i"
		echo ""

		ShowUsage
		exit 1
	;;
	esac
done

if [ ${#SERVERNAME} -eq 0 ]; then
	echo "ERROR: Please provide a server name."
	exit 2
fi

CURDIR=`pwd`
SSLTHING=1
SSLTHINGEXE="/usr/bin/sslthing-updated.sh"
if [ ! -e /usr/bin/sslthing-updated.sh ]; then
	if [ -e /usr/bin/sslthing.sh ]; then
	   echo "Warning: Updated sslthing (sslthing-updated.sh) could not be located.  Using standard sslthing.sh."
	   SSLTHINGEXE="/usr/bin/sslthing.sh"
	else
	   echo "Warning: Unable to locate sslthing-updated.sh or sslthing.sh.  SSL cipher testing disabled."
	   SSLTHING=0
	fi
fi

REPORTFILE=`echo "$SERVERNAME.rpt"`
echo "------------ Scan started `date` --------------" > $REPORTFILE
echo "Parameters:" >> $REPORTFILE
echo "Server: $SERVERNAME" >> $REPORTFILE
echo "SSL: $SSL" >> $REPORTFILE
echo "Port: $PORT" >> $REPORTFILE
echo "Run NMAP: $RUNNMAP" >> $REPORTFILE
echo "Run Google queries: $GOOGLE" >> $REPORTFILE
echo "Dirbuster: $DIRBUSTER" >> $REPORTFILE
echo "Dirbuster max time: $DIRBUSTER_MAXTIME" >> $REPORTFILE

SERVERURL=`echo "$HTTPPREFIX//$SERVERNAME:$PORT/"`
SERVERURLFULL=`echo "$HTTPPREFIX//$SERVERNAME:$PORT/$ALTROOT"`

# ------------  Information Gathering --------------------
echo "-------------- Information Gathering ------------------ [`date`]"

# ---  Google ---

# ---  Robots.txt ---
wget $SERVERURL/robots.txt 2>/dev/null

if [ -e robots.txt ]; then
	echo "Robots.txt: Found"
	cat robots.txt
	echo "Robots.txt: Found" >> $REPORTFILE
else
	echo "Robots.txt: Not Found"
	echo "Robots.txt: Not Found" >> $REPORTFILE
fi

# ---  sitemap.xml ---
wget $SERVERURLFULL/sitemap.xml 2>/dev/null

if [ -e sitemap.xml ]; then
	echo "sitemap.xml: Found"
	cat sitemap.xml
	echo "sitemap.xml: Found" >> $REPORTFILE
else
	echo "sitemap.xml: Not Found"
	echo "sitemap.xml: Not Found" >> $REPORTFILE
fi

# ------------  Scanning --------------------
# ---  nmap ---
echo "-------------- NMap ------------------ [`date`]"
if [ $RUNNMAP -eq 1 ]; then
	echo "Running nmap..."
	nmap -PN -sV -T3 -O -F --data-length 30 --version-intensity 3 -sS -sU -oA $SERVERNAME $SERVERNAME
else
	echo "Skipping nmap scan..."
fi

# In either case, nmap / profile the web server
# Get version info
nmap -PN -sV --version-intensity 7 -p $PORT $SERVERNAME > $CURDIR/$SERVERNAME.$PORT.http_version.txt

# ---  nikto ---
NIKTODIR=`ls -1d /opt/nikto/nikto-* | grep -o "nikto-.*" | grep -v "\.tar\.gz"`
NIKTODIR=`echo "/opt/nikto/$NIKTODIR"`
cd $NIKTODIR
echo "--- Running nikto ----"
if [ $SSL -eq 1 ]; then
	./nikto.pl -evasion 1 -port $PORT -ssl -host $SERVERNAME -vhost $SERVERNAME 1> $CURDIR/$SERVERNAME.nikto.txt 2> $CURDIR/$SERVERNAME.nikto_errors.txt 
else
	./nikto.pl -evasion 1 -port $PORT -host $SERVERNAME -vhost $SERVERNAME 1> $CURDIR/$SERVERNAME.nikto.txt 2> $CURDIR/$SERVERNAME.nikto_errors.txt 
fi

cd $CURDIR

if [ -e $CURDIR/$SERVERNAME.nikto.txt ]; then
	nikto.ConvertToCSV.sh --cache $SERVERNAME.nikto.txt > $SERVERNAME.nikto.csv
fi

# --- Certificate info ---
if [ $SSL -eq 1 ]; then
	echo "Dumping certificate info for $SERVERNAME SSL/$PORT..."
	openssl s_client -connect $SERVERNAME:$PORT 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CURDIR/$SERVERNAME.$PORT.ssl.certificate.cer&
	sleep 3

	if [ -e $CURDIR/$SERVERNAME.$PORT.ssl.certificate.cer ]; then
		# Common Name
		CERTCN=`cat $CURDIR/$SERVERNAME.$PORT.ssl.certificate.cer | openssl x509 -noout -subject | grep -Eo "CN=.*?$" | sed "s|CN=||"`
		echo "$CERTCN" > $CURDIR/$SERVERNAME.$PORT.ssl.CertCommonName.txt

		# Expiration
		DATESTR=`cat $CURDIR/$SERVERNAME.$PORT.ssl.certificate.cer | openssl x509 -noout -dates | grep -Eo "notAfter.*?$" | sed "s|notAfter=||"`
		CERTEXPIRES=`date -d "$DATESTR"`
		echo "$CERTEXPIRES" > $CURDIR/$SERVERNAME.$PORT.ssl.CertExpiration.txt

		echo "[$SSLPORT] Common Name: $CERTCN   Expires: $CERTEXPIRES" >> $CURDIR/$REPORTFILE
	fi

	echo "[$PORT] Version Info:" >> $CURDIR/$REPORTFILE
	cat $CURDIR/http/$BASEDESCRIPTOR.https.$SSLPORT.http_version.txt | grep "^$SSLPORT" >> $CURDIR/$REPORTFILE

	if [ $SSLTHING -eq 1 ]; then
		$SSLTHINGEXE $SERVERNAME:$PORT > $CURDIR/$SERVERNAME.$PORT.ssl.SupportedCiphers.txt
		echo "Supported Ciphers:" >> $CURDIR/$BASEDESCRIPTOR.rpt
		cat $CURDIR/$SERVERNAME.$PORT.ssl.SupportedCiphers.txt >> $CURDIR/$REPORTFILE 
	fi

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
fi

# ------------  web site download/crawl --------------------
cd $CURDIR
mkdir SiteCopy 2>/dev/null
cd SiteCopy_$SERVERNAME
httrack $SERVERURLFULL --robots=N --user-agent "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.9) Gecko/20100315 Firefox/3.5.9 ( .NET CLR 3.5.30729)"
cd $CURDIR

# --- Dirbuster ---
if [ $DIRBUSTER -eq 1 ]; then
	# Dirbuster will run for a maximum of 5 hours
	echo "Running dirbuster..."
	cd /opt/dirbuster
	dirbuster.run.sh $SERVERURLFULL $CURDIR/$SERVERNAME.dirbuster.txt $DIRBUSTER_MAXTIME
	cd $CURDIR
else
	echo "Skipping dirbuster..."
fi

echo "------------ Scan completed `date` --------------" >> $CURDIR/$REPORTFILE

