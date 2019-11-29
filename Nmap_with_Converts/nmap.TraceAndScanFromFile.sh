#!/bin/bash

# --------------- Functions -------------------------
ShowUsage() {
  echo ""
  echo "$0 usage:"
  echo ""  
  echo "Automation of initial system-level recon and enumeration."
  echo "Tests include: "
  echo "   ping (off by default.  Use --enable-ping to activate)"
  echo "   traceroute (icmp and on linux udp as well) (off by default.  Use --enable-trace to activate)"
  echo "   ikescan: ike listeners, aggressive mode psk dump, weak transforms"
  echo "   nmap"
  echo ""
  echo "NMap results are then used for additional tests on:"
  echo -e "\033[1mInteractive Management\033[0m"
  echo "   ssh:    Version, Public key dump, SSH v1 support test"
  echo "   telnet: Version, Banner grabbing"
  echo -e "\033[1mCommon Internet Protocols\033[0m"
  echo "   dns:    Version scan, recursion tests, cache snoop (www.google.com)"
  echo "   web:    Version, open proxy test, SSL cert retrieval, "
  echo "           Supported SSL ciphers, Nikto scans (http and https [preferred])."
  echo "   smtp:   Version, ehlo, vrfy, bad verb"
  echo "   ftp:    Version, Anonymous access, ftp bounce scanning"
  echo "           FTPS - version and SSL ciphers supported, anonymous access."
  echo -e "\033[1mDevice/System Management\033[0m"
  echo "   snmp:   Version, Dictionary queries"
  echo "   ntp:    Version, List configured peers, NTP system information, and recent clients (if available)."
  echo -e "\033[1mFirewall\033[0m"
  echo "   nmap fixed source port (80) scan (can be compared against std scan for differences) [off by default.  Use --enable-nmapfixed to activate)"
  echo -e "\033[1mRemote Desktop\033[0m"
  echo "   Citrix: Query for published applications and enumerate servers list."
  echo " "
  echo -e "\033[1mRequired Parameters:\033[0m"
  echo "--networkfile=<file>   where <file> is a list of CIDR network addresses, one per line."
  echo "                       This will then be initially used to nmap the addresses.  Live hosts will be"
  echo "                       extracted and used to create the host file rather than using the --hostfile parameter"
  echo -e "\033[1m[or]\033[0m --hostfile=<file>   where <file> is a list of host IP addresses, one per line."  | sed "s|-e||"
  echo "--basedescriptor=<base>  A text descriptor to include with each file name that describes this scan"
  echo " "
  echo -e "\033[1mOptions:\033[0m"
  echo "--usetor    [EXPERIMENTAL!  Not completely reliable!]"
  echo "            test with wireshark, proxychains, and 'nmap -sT -p 80 scanme.nmap.org' to ensure anonymity!"
  echo "            Attempt to perform all tests through tor (listening on 127.0.0.1:9050) with a 'torify' wrapper"
  echo "            NOTE: Using tor will disable ping, trace, and ikescan (which is timing-dependent)"
  echo "                  as well as SNMP, NTP, and DNS which use UDP and is not proxied."
  echo " "
  echo "--nmapfile=<previous scan>   Do not perform new scan but use old scan results.  This also disables nmap scanning."
  echo "                             Note that previous nmap scans must include the gnmap format and expects to cover"
  echo "                             the provided host list (no new scan will be performed)."
  echo "--snmpfile=<snmp string file>  When performing SNMP dictionary queries, use this file."
  echo "--dnsfile=<DNS Name/IP map file> For enhanced web scanning, use this DNS file to map IPs to vhost names"
  echo " "
  echo "--noping    Do not perform ping tests. (Default setting)"
  echo "--notrace   Do not perform traceroute tests.  Note trace tests are done last as they can take some time. (Default setting)"
  echo "--noike     Do not perform IPSec location via ikescan."
  echo " "
  echo "--nonmap    Disables nmap and ALL post-nmap tests: ssh, telnet, snmp, ntp, web, ftp, smtp.  Only ping/trace/ike are run"
  echo "--nonmapfixed    Disables nmap fixed port scan."
  echo "--nossh     Do not perform additional SSH testing."
  echo "--notelnet  Do not perform telnet tests."
  echo "--nosnmp    Do not perform SNMP dictionary querying."
  echo "--nosmtp    Do not perform SMTP tests (connect, banner, VRFY)."
  echo "--nodns     Do not perform DNS tests."
  echo "--noftp     Do not perform ftp tests."
  echo "--nontp     Do not query for NTP peers."
  echo "--nocitrix  Do not perform Citrix tests."
  echo " "
  echo "--noweb     Do not perform certificate dump and nikto scanning of web servers"
  echo "--sslonly   Scan web, but only scan over SSL to avoid tripping Network IDS"
  echo "--arachni	Run arachni web scanner against web servers"
  echo "--dirb		Run dirb against web servers (default is to not run it)"
  echo "--nonikto   Don't run nikto scan (for speed) (default is to run it)"
  echo " "
  echo "--disableall Disables all tests.  Then use enable-<option> to enable"
  echo "--enable-<option> where option=ping, trace, ike, "
  echo "                  nmap (enabled automatically with any of the following "
  echo "                  [note: if file specified, it will still be used])"
  echo "                  ssh, telnet, web (or http), smtp, dns, ftp, snmp, ntp, citrix, nmapfixed"
  echo ""
  echo -e "\033[1mExamples:\033[0m"
  echo "Standard External Scan with DNS File and Network List"
  echo -e "\033[34m$0 --basedescriptor=MyClient --networkfile=MyClientsNetwork.txt --dnsfile=MyClientsIPSystemNames.txt\033[0m"
  echo ""
  echo "External Scan against specified hosts and do not scan web servers unless over SSL"
  echo -e "\033[34m$0 --basedescriptor=MyClient --hostfile=MyClientsHosts.txt --sslonly\033[0m"
  echo ""
  echo "Standard External Scan using previously run nmap gnmap (e.g. from nmap -oA) output file"
  echo -e "\033[34m$0 --basedescriptor=MyClient --hostfile=myclienthosts.txt --nmapfile=Mynmapscan.gnmap --dnsfile=MyClientsIPSystemNames.txt\033[0m"
  echo ""
  echo "Internal network scan:"
  echo -e "\033[34m$0 --basedescriptor=MyClient --networkfile=MyClientsNetwork.txt --dnsfile=MyClientsIPSystemNames.txt --nonmapfixed --enable-ping --enable-trace\033[0m"
  echo ""
  echo -e "\033[1mNotes:\033[0m"
  echo -e "- At any time, pressing '\033[1mp\033[0m' will \033[1mpause\033[0m the scan at the next available opportunity, '\033[1mq\033[0m' will \033[1mquit\033[0m."
  echo "- If an nmap scan is terminated <ctl>-c, when the script is rerun, it will check for the existance of the gnmap file and if it exists ask to resume."
  echo ""
}

BoundNiktoProcessesOldCheck() {
	MAXNIKTO=4

	SYSRAM=`grep MemTotal /proc/meminfo | grep -Eo "[0-9]{3,}"`

	if [ ${#SYSRAM} -gt 0 ]; then
		if [ $SYSRAM -le 700000 ]; then
			# <= 700M reduce Max Nikto's
			MAXNIKTO=3
		else
			if [ $SYSRAM -ge 1000000 ]; then
				# >= 1G, increase max
				MAXNIKTO=6
			fi
		fi
	fi

	WAITING=0

	NUMNIKTO=`ps -A | grep nikto | wc -l`

	if [ $NUMNIKTO -ge $MAXNIKTO ]; then
		echo -n "Waiting for free Nikto slot ($NUMNIKTO/$MAXNIKTO in use).."
		WAITING=1
	fi

	# because of the way while handles the stack, can't dynamically
	# update the NUMNIKTO variable inside the loop.  Need the exec quotes
	while [ `ps -A | grep nikto | wc -l` -ge $MAXNIKTO ]
	do
		echo -n "."
		sleep 9s
		
		CheckForKeypress
	done	

	if [ $WAITING -eq 1 ]; then
		echo "Continuing"
	fi
}

BoundWebScanProcesses() {
	# New memory management approach, try to keep 250M free.

	MINSCANMEMFREE=250

	WAITING=0
	FREEMEM=`free -m | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4`
	if [ $FREEMEM -lt $MINSCANMEMFREE ]; then
		echo -n "Waiting for memory to free up (only $FREEMEM available).."
		WAITING=1
	fi

	while [ `free -m | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4` -lt $MINSCANMEMFREE ]
	do
		echo -n "."
		sleep 9s
		
		CheckForKeypress
	done	

	if [ $WAITING -eq 1 ]; then
		echo "Continuing"
	fi
}

CheckForKeypress() {
	USER_INPUT=""
	read -t 1 -n 1 USER_INPUT 

	if [ ${#USER_INPUT} -gt 0 ]; then
		case $USER_INPUT in
		p)
			echo ""
			echo "Paused [`date`].  Press c to continue or q to quit."

			while true
			do
				USER_INPUT=""
				read -t 1 -n 1 USER_INPUT 
				if [ ${#USER_INPUT} -gt 0 ]; then
					case $USER_INPUT in
					c)
						echo "Continuing [`date`]..."
						break			
					;;
					q)
						echo "Quitting [`date`]."
						exit 1
					;;
					*)
						echo "Paused.  Press c to continue or q to quit."
					;;
					esac
				fi
			done
		;;
		q)
			echo "Quitting [`date`]."
			exit 1
		;;
		esac
	fi
}

# --------------- Globals -----------------------
EXPECTED_ARGS=2
OSTYPE=`uname`
CURDIR=`pwd`
METASPLOIT=1

SOCKSAPP="/usr/bin/proxychains"
SOCKSIFY=""

# Do syn scan (-sS) unless using proxy,
# Then need a connect scan (slower) with -sT
NMAPSCANTYPE="-sT"

PING=0
TRACERT=0
IKESCAN=1

SSH=1
TELNETTEST=1

NMAPFILE=""
NMAP=1
NMAPFIXED=0
NMAP_RESUME_SCAN=0
NMAP_RESUME_FIXED=0

WEB=1
SSLONLY=0
RUNARACHNI=0
RUNDIRB=0
RUNNIKTO=1
SSLTHING=1
SSLTHINGEXE="/usr/bin/sslthing-updated.sh"

DNSTESTS=1
SMTP=1
FTPTEST=1

SNMP=1
NTPTEST=1
CITRIX=1

if echo "$OSTYPE" | grep -i "CYGWIN" > /dev/null; then
	ISLINUX=0
else
	ISLINUX=1
fi

# --------------- Main --------------------------

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

if [ $ISLINUX -eq 1 ]; then
#  Must be superuser
	if [ "$(id -u)" != "0" ]; then
	   echo "This script must be run as root.  Please use sudo $0 to run."
	   exit 2
	fi
fi

# -- Parse Arguments -------------

# Defaults:
HOSTFILE=""
NETWORKFILE=""
USENETWORKFILE=1
BASEDESCRIPTOR=""
SNMPSTRINGFILE="/opt/snmpmap/SnmpStrings.txt"
DNSFILE=""

for i in $*
do
	case $i in
    	--networkfile=*)
		NETWORKFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		HOSTFILE=""
		USENETWORKFILE=1
		;;
    	--hostfile=*)
		HOSTFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		USENETWORKFILE=0
		;;
    	--basedescriptor=*)
		BASEDESCRIPTOR=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		;;
	--usetor)
		SOCKSIFY=$SOCKSAPP
		PING=0
		TRACERT=0
		IKESCAN=0

		DNSTESTS=0
		SNMP=0
		NTPTEST=0

		NMAPSCANTYPE="-sT"
		;;
    	--snmpfile=*)
		SNMPSTRINGFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		echo "$SNMPSTRINGFILE" | grep "^/"

		if [ $? -gt 0 ]; then
#			Path was relative			
			SNMPSTRINGFILE=`echo "$CURDIR/$SNMPSTRINGFILE"`
		fi
		;;
    	--dnsfile=*)
		DNSFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`

		echo "$DNSFILE" | grep "^/"

		if [ $? -gt 0 ]; then
#			Path was relative			
			DNSFILE=`echo "$CURDIR/$DNSFILE"`
		fi

		;;
    	--nmapfile=*)
		NMAPFILE=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
		NMAP=1
		;;
	--nonmapfixed)
		NMAPFIXED=0
		;;
    	--noping)
		# Do no ping hosts
		PING=0
		;;
    	--notrace)
		# Do no trace to hosts
		TRACERT=0
		;;
    	--noike)
		# Do no ike-scan hosts
		IKESCAN=0
		;;
  	--nonmap)
		# Do no ike-scan hosts
		IKESCAN=0
		SMTP=0
		SSH=0
		SNMP=0
		WEB=0
		NMAP=0
		;;
      	--nossh)
		# Do no ssh tests
		SSH=0
		;;
	--notelnet)
		TELNETTEST=0
		;;
    	--nosmtp)
		# Do no smtp tests
		SMTP=0
		;;
    	--noftp)
		# Do no ftp tests
		FTPTEST=0
		;;
    	--nontp)
		# Do no NTP tests
		NTPTEST=0
		;;
    	--nosnmp)
		# Do no snmp tests
		SNMP=0
		;;
    	--nocitrix)
		# Do no Citrix tests
		CITRIX=0
		;;
	--nodns)
		DNSTESTS=0
		;;
    	--noweb)
		# Do no web / http tests
		WEB=0
		;;
	--sslonly)
		# Do no http tests when SSL is not available
		SSLONLY=1
		WEB=1
		NMAP=1
		;;
	--arachni)
		# Run the arachni scanner against web services.
		RUNARACHNI=1
		;;
	--dirb)
		# Run the dirb scanner against web services.
		RUNDIRB=1
		;;
	--nonikto)
		RUNNIKTO=0
		;;
	--disableall)
		PING=0
		TRACERT=0
		IKESCAN=0
		
		DNSTESTS=0
		SSH=0
		TELNETTEST=0
		
		NMAP=0
		NMAPFIXED=0
		
		WEB=0
		SMTP=0
		FTPTEST=0
		
		SNMP=0
		NTPTEST=0
		CITRIX=0

		;;
	--enable-nmapfixed)
		NMAPFIXED=0
		;;
	--enable-ping)
		PING=1
		;;
	--enable-trace)
		TRACERT=1
		;;
	--enable-ike)
		IKESCAN=1
		;;
	--enable-ssh)
		NMAP=1
		SSH=1
		;;
	--enable-telnet)
		TELNETTEST=1
		NMAP=1
		;;
	--enable-dns)
		DNSTESTS=1
		NMAP=1
		;;
	--enable-web|--enable-http)
		WEB=1
		NMAP=1
		;;
	--enable-smtp)
		SMTP=1
		NMAP=1
		;;
	--enable-ftp)
		NMAP=1
		FTPTEST=1
		;;
	--enable-snmp)
		NMAP=1
		SNMP=1
		;;
	--enable-ntp)
		NMAP=1
		NTPTEST=1
		;;
	--enable-citrix)
		NMAP=1
		CITRIX=1
		;;
    	*)
                # unknown option
		echo "Unknown option: $i"
  		ShowUsage
		exit 3
		;;
  	esac
done

if [ ${#BASEDESCRIPTOR} -eq 0 ]; then
	echo "ERROR: Please provide a base descriptor (--basedescriptor)"
	exit 3
fi

NETCATPRESENT=1

echo " " > $CURDIR/$BASEDESCRIPTOR.rpt

# test for netcat....
nc -h 2> /dev/null 1> /dev/null
if [ $? -eq 127 ]; then
   echo "Unable to locate netcat (nc).  Disabling some smtp tests..."
   echo "Unable to locate netcat (nc).  Disabling some smtp tests..." >> $CURDIR/$BASEDESCRIPTOR.rpt

   NETCATPRESENT=0
fi

which msfconsole > /dev/null

if [ $? -gt 0 ]; then
   # Enabled or not, if not present, disable.

  if [ $METASPLOIT -eq 1 ]; then
	echo "Unable to locate msfconsole.  Disabling any Metasploit-based checks (ntp monitor list)..."
   fi
   METASPLOIT=0
fi

# test for sslthing.sh

if [ ! -e /usr/bin/sslthing-updated.sh ]; then
	if [ -e /usr/bin/sslthing.sh ]; then
	   echo "Warning: Updated sslthing (sslthing-updated.sh) could not be located.  Using standard sslthing.sh."
	   SSLTHINGEXE="/usr/bin/sslthing.sh"
	else
	   echo "Warning: Unable to locate sslthing-updated.sh or sslthing.sh.  SSL cipher testing disabled."
	   SSLTHING=0
	fi
fi

# test for ntpq....
USENTPQ=1

ntpq --help 2> /dev/null 1> /dev/null
if [ $? -eq 127 ]; then
   echo "Warning: Unable to locate ntpq NTP query tool.  NTP will be tested via nmap rather than ntpq..."
   USENTPQ=0
fi

if [ ! -e $SNMPSTRINGFILE ]; then
	echo "SNMP string file $SNMPSTRINGFILE does not exist."
	exit 1
fi

if [ $USENETWORKFILE -eq 1 ]; then
	# Specified to use a network
	if [ ! -e $NETWORKFILE ]; then
		echo "Network file $NETWORKFILE does not exist."
		exit 1
	fi
else
	# Specified to use a host file
	if [ ! -e $HOSTFILE ]; then
		echo "Host file $HOSTFILE does not exist."
		exit 1
	fi
fi

if [ ${#DNSFILE} -gt 0 ]; then
	if [ ! -e $DNSFILE ]; then
		echo "DNS map file $DNSFILE does not exist."
		exit 1
	fi
fi

# NMAP Resume checks
if [ -e $BASEDESCRIPTOR.gnmap -a ${#NMAPFILE} -eq 0 ]; then
	# gnmap file exists and it wasn't supplied as a pre-existing nmap file
	while true
	do
	    echo -n "NMAP file $BASEDESCRIPTOR.gnmap already exists.  Resume scan or Overwrite [R/O]? "
	    read -e USER_CHOICE

	    case $USER_CHOICE in
		r|R) 
			NMAP_RESUME_SCAN=1
		break
		;;
		o|O)
			NMAP_RESUME_SCAN=0
		break
		;;
		*) 
			echo "Please answer R/r or O/o!"
		;;
	      esac
	done
fi

if [ -e $BASEDESCRIPTOR-Fixed.gnmap -a $NMAPFIXED -eq 1 ]; then
	# gnmap file exists and fixed scan requested
	while true
	do
	    echo -n "NMAP file $BASEDESCRIPTOR-Fixed.gnmap already exists for fixed port scan.  Resume scan or Overwrite [R/O]? "
	    read -e USER_CHOICE

	    case $USER_CHOICE in
		r|R) 
			NMAP_RESUME_FIXED=1
		break
		;;
		o|O)
			NMAP_RESUME_FIXED=0
		break
		;;
		*) 
			echo "Please answer R/r or O/o!"
		;;
	      esac
	done
fi

# --------------------------------
DATESTR=`date`
echo "Starting scan [$DATESTR]"
if [ $USENETWORKFILE -eq 1 ]; then
	echo "Network File: $NETWORKFILE"
else
	echo "Host File: $HOSTFILE"
fi

echo "OS Type: $OSTYPE"
echo "Base Descriptor: $BASEDESCRIPTOR"

echo "Starting scan [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Host File: $HOSTFILE" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "OS Type: $OSTYPE" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Base Descriptor: $BASEDESCRIPTOR" >> $CURDIR/$BASEDESCRIPTOR.rpt

if [ ${#SOCKSIFY} -eq 0 ]; then
	echo "TOR: Disabled"
	echo "TOR: Disabled" >> $CURDIR/$BASEDESCRIPTOR.rpt
else
	echo "TOR: Enabled"
	echo "TOR: Enabled" >> $CURDIR/$BASEDESCRIPTOR.rpt
fi

echo " "
if [ ${#NMAPFILE} -eq 0 ]; then
	echo "NMAP:	Scanning"
	echo "NMAP:	Scanning" >> $CURDIR/$BASEDESCRIPTOR.rpt
else
	echo "NMAP:	From file $NMAPFILE"
	echo "NMAP:	From file $NMAPFILE" >> $CURDIR/$BASEDESCRIPTOR.rpt
fi

echo "Ping:	$PING" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Trace:	$TRACERT" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Ike:	$IKESCAN" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "ssh:	$SSH" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Telnet:	$TELNETTEST" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "HTTP-S:	$WEB" >> $CURDIR/$BASEDESCRIPTOR.rpt

echo "Ping:	$PING"
echo "Trace:	$TRACERT"
echo "Ike:	$IKESCAN"
echo "ssh:	$SSH"
echo "Telnet:	$TELNETTEST"
echo "HTTP-S:	$WEB"

if [ ${#DNSFILE} -gt 0 ]; then
	echo "DNS Map File: $DNSFILE"
	echo "DNS Map File: $DNSFILE" >> $CURDIR/$BASEDESCRIPTOR.rpt
else
	echo "DNS Map File: None Specified."
	echo "DNS Map File: None Specified." >> $CURDIR/$BASEDESCRIPTOR.rpt
fi

echo "SMTP:	$SMTP" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "FTP:	$FTPTEST" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "SNMP:	$SNMP" >> $CURDIR/$BASEDESCRIPTOR.rpt

echo "SMTP:	$SMTP"
echo "FTP:	$FTPTEST"
echo "SNMP:	$SNMP"
if [ $SNMP -eq 1 ]; then
	echo "SNMP String File: $SNMPSTRINGFILE"
	echo "SNMP String File: $SNMPSTRINGFILE" >> $CURDIR/$BASEDESCRIPTOR.rpt
fi

echo "NTP:	$NTPTEST" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "Citrix:	$CITRIX" >> $CURDIR/$BASEDESCRIPTOR.rpt

echo "NTP:	$NTPTEST"
echo "Citrix:	$CITRIX"

CheckForKeypress

if [ $USENETWORKFILE -eq 1 -a ${#NMAPFILE} -eq 0 ]; then
	echo ""
	echo "Network file specified.  Running nmap scan now to build host list from the following networks:"
	cat $NETWORKFILE
	echo ""

	if [ $NMAP_RESUME_SCAN -eq 1 ]; then
		$SOCKSIFY nmap --resume $BASEDESCRIPTOR.gnmap -PN -sV --max-retries 1 --host-timeout 180m -T3 -O -F --data-length 30 --version-intensity 3 $NMAPSCANTYPE -sU -oA $BASEDESCRIPTOR -iL $NETWORKFILE
	else
		$SOCKSIFY nmap -PN -sV --max-retries 1 --host-timeout 180m -T3 -O -F --data-length 30 --version-intensity 3 $NMAPSCANTYPE -sU -oA $BASEDESCRIPTOR -iL $NETWORKFILE
	fi

	# set results to nmap output file since it's already been run
	NMAPFILE=`echo $BASEDESCRIPTOR.gnmap`

	# Make sure nmap result checks are enabled.
	NMAP=1

	# Building online / active hosts from nmap results
	if [ ! -e $BASEDESCRIPTOR.gnmap ]; then
		echo "ERROR: Unable to find $BASEDESCRIPTOR.gnmap.  Nmap scan may have failed."
		exit 2
	fi

	HOSTFILE=`echo $BASEDESCRIPTOR.discoveredhosts.txt`

	cat $NMAPFILE | grep "/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g" | grep -Ev "^$" | sort -u > $HOSTFILE

	if [ -e $HOSTFILE ]; then
		NUMHOSTSDISCOVERED=`cat $HOSTFILE | wc -l`
		echo "Discovered $NUMHOSTSDISCOVERED active hosts.  Creating NMAP CSV file $NMAPFILE.csv from $NMAPFILE for analysis..."
		if [ ${#DNSFILE} -gt 0 ]; then
			nmap.FormatToCSV.sh $NMAPFILE $DNSFILE > $NMAPFILE.csv
		else
			nmap.FormatToCSV.sh $NMAPFILE > $NMAPFILE.csv
		fi

		echo "Continuing analysis..."
	else
		echo "ERROR: Cannot extract online hosts from nmap scan.  No hosts discovered or no ports open?"
		exit 3
	fi
fi

CheckForKeypress

HOSTLIST=`cat $HOSTFILE`

# The Sed replace of \r is a safety check for files moving between
# Windows an *nix.
HOSTLIST=`echo "$HOSTLIST" | sed "s|\r||g" | grep -v "^$"`
echo "Hosts:"
echo "$HOSTLIST"
echo " "

echo "Hosts:" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo "$HOSTLIST" >> $CURDIR/$BASEDESCRIPTOR.rpt
echo " " >> $CURDIR/$BASEDESCRIPTOR.rpt
# -----------------------------------------------------------
if [ $PING -eq 1 ]; then
	echo "-------------- Ping ------------------ [$DATESTR]"
	DATESTR=`date`
	echo "Running ping..."

	mkdir ping 2> /dev/null

	echo "Pinging Hosts" > $CURDIR/ping/$BASEDESCRIPTOR.ping.txt
	
	echo "`date`" >> $CURDIR/ping/$BASEDESCRIPTOR.ping.txt
	
	for HOSTIP in $HOSTLIST
	do
	#	Ping syntax is different depending on OS
	#	Native Windows: ping -n 1 $HOSTIP
	#	Linux: ping -c 1 $HOSTIP
	#	Cygwin: ping $HOSTIP count 1
	
	
		echo "------------------------------------------------------"
	
		if [ $ISLINUX -eq 0 ]; then
	#		Cygwin
			ping $HOSTIP count 1 >> $CURDIR/ping/$BASEDESCRIPTOR.ping.txt
		else
	#		Linux
			ping -c 1 $HOSTIP >> $CURDIR/ping/$BASEDESCRIPTOR.ping.txt
		fi

		CheckForKeypress

	done
	echo "`date`" >> $CURDIR/ping/$BASEDESCRIPTOR.ping.txt

	TMPRESULTS=`cat $CURDIR/ping/$BASEDESCRIPTOR.ping.txt | grep -B 1 -E "1 (packets )?received" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	
	NUMHOSTS=`echo "$TMPRESULTS" | wc -l`

	echo "-------- Ping ----------- [$DATESTR]"  >> $CURDIR/$BASEDESCRIPTOR.rpt

	if [ $NUMHOSTS -gt 0 ]; then
		echo "$TMPRESULTS" > $CURDIR/ping/$BASEDESCRIPTOR.ping.success.txt

		echo "Pingable Hosts:" >> $CURDIR/$BASEDESCRIPTOR.rpt
		cat $CURDIR/ping/$BASEDESCRIPTOR.ping.success.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
	else
		echo "No pingable hosts found."
		echo "No pingable hosts found." >> $CURDIR/$BASEDESCRIPTOR.rpt
	fi


fi

# -----------------------------------------------------------
if [ $IKESCAN -eq 1 ]; then
	DATESTR=`date`
	echo "-------------- IKE Scan ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
	echo "-------------- IKE Scan ------------------ [$DATESTR]"
	echo "Running ikescan..."
	# This requires a symbolic link under cygwin to work... ln -s <ike-scan location> /usr/bin/ike-scan and ln -s <psk-crack> /usr/bin/psk-crack
	TMPRESULTS=`ike-scan -v --showbackoff=30 -f $CURDIR/$HOSTFILE 2>&1`

	CheckForKeypress

	NUMHOSTS=`echo "$TMPRESULTS" | grep -i "Implementation guess" | grep -o -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g" | grep -v "^$" | wc -l`
	
	if [ $NUMHOSTS -gt 0 ]; then
		mkdir ipsec 2> /dev/null
		echo "$TMPRESULTS" > $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan.txt 

		cat $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan.txt | grep -i "Implementation guess" | grep -o -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g" > $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan-live.txt
		# 	pskcrack can only be used with one host at a time

		if [ -e $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan-live.txt ]; then
			IKELIST=`cat $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan-live.txt`
			NUMHOSTS=`cat $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan-live.txt | wc -l`
		
			if [ $NUMHOSTS -gt 0 ]; then
				echo "Found $NUMHOSTS live ike hosts!"
				cat $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan.txt
				cat $CURDIR/ipsec/$BASEDESCRIPTOR.ikescan.txt >> $CURDIR/$BASEDESCRIPTOR.rpt

				echo "searching for aggressive mode keys and weak transforms..."
				for IKEIP in $IKELIST
				do
					if [ ${#IKEIP} -gt 0 ]; then
						# For this psk dump to reliably be successful, a --id= parameter should be added where
						# the id value is the hex representation of an allowed peering address.
						# ex. for 172.22.12.251 as the id, use --id=0xac160cfb with a command like:
						# ike-scan -v -A --pskcrack=$HOME/test.psk_key.txt --idtype=1 --id=0xac160cfb 172.22.12.250
						# ike-scan --aggressive --multiline --id=some_id 172.22.12.250  can be used to see a more
						# readable output.
						ike-scan -A --pskcrack=$CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.psk_key.txt --idtype=1 $IKEIP
					
						echo "Weak Transforms:" > $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
						echo "Weak Transforms:" >> $CURDIR/$BASEDESCRIPTOR.rpt

						# DES, MD5, DH1, PSK
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=1,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "PSK: DES, MD5, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "PSK: DES, MD5, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH1, PSK
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=1,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "PSK: DES, SHA1, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "PSK: DES, SHA1, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, MD5, DH2, PSK
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=1,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "PSK: DES, MD5, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "PSK: DES, MD5, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH2, PSK
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=1,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "PSK: DES, SHA1, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "PSK: DES, SHA1, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# -----------------------------
						# DES, MD5, DH1, RSA
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=3,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "RSA: DES, MD5, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "RSA: DES, MD5, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH1, RSA
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=3,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "RSA: DES, SHA1, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "RSA: DES, SHA1, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, MD5, DH2, RSA
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=3,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "RSA: DES, MD5, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "RSA: DES, MD5, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH2, RSA
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=3,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "RSA: DES, SHA1, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "RSA: DES, SHA1, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# -----------------------------
						# DES, MD5, DH1, XAUTH
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=65001,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "XAUTH: DES, MD5, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "XAUTH: DES, MD5, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH1, XAUTH
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=65001,4=1)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "XAUTH: DES, SHA1, DH1" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "XAUTH: DES, SHA1, DH1" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, MD5, DH2, XAUTH
						TMPRESULT=`ike-scan --trans="(1=1,2=1,3=65001,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "XAUTH: DES, MD5, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "XAUTH: DES, MD5, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# DES, SHA1, DH2, XAUTH
						TMPRESULT=`ike-scan --trans="(1=1,2=2,3=65001,4=2)" $IKEIP`

						echo "$TMPRESULT" | grep "1 returned handshake" > /dev/null

						if [ $? -eq 0 ]; then
							echo "XAUTH: DES, SHA1, DH2" >> $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
							echo "XAUTH: DES, SHA1, DH2" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						WEAKLINESIZE=`cat $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt | wc -l`

						if [ $WEAKLINESIZE -eq 1 ]; then
							# none found.  Just label.  Delete the file.
							rm $CURDIR/ipsec/$BASEDESCRIPTOR_$IKEIP.weak_transforms.txt
						fi
					fi

				CheckForKeypress

				done
			else
				echo "No ipsec listeners found."
				echo "No ipsec listeners found." >> $CURDIR/$BASEDESCRIPTOR.rpt
			fi
		fi
	else
			echo "No ipsec listeners found."
			echo "No ipsec listeners found." >> $CURDIR/$BASEDESCRIPTOR.rpt
	fi
fi

# -----------------------------------------------------------

if [ $NMAP -eq 1 ]; then
	if [ ${#NMAPFILE} -eq 0 ]; then
		DATESTR=`date`
		echo "-------------- NMap ------------------ [$DATESTR]"
		echo "Running nmap..."
		if [ $NMAP_RESUME_FIXED -eq 1 ]; then
			$SOCKSIFY nmap --resume $BASEDESCRIPTOR.gnmap -PN -sV -T3 -O -F  --max-retries 1 --host-timeout 180m --data-length 30 --version-intensity 3 $NMAPSCANTYPE -sU -oA $BASEDESCRIPTOR -iL $HOSTFILE
		else
			$SOCKSIFY nmap -PN -sV -T3 -O -F  --max-retries 1 --host-timeout 180m --data-length 30 --version-intensity 3 $NMAPSCANTYPE -sU -oA $BASEDESCRIPTOR -iL $HOSTFILE
		fi

		NMAPFILE=`echo $BASEDESCRIPTOR.gnmap`
	else
		# if using nmap file, need to grep out only relevent results
		cat $HOSTFILE | sed "s|\.|\\\.|g" | sed "s|$| |g" | sed "s|  ||g" | sed "s|  ||g" > $HOSTFILE.grep

		cat $NMAPFILE | grep --file=$HOSTFILE.grep > $NMAPFILE.releventhosts

		NMAPFILE=`echo $NMAPFILE.releventhosts`
	fi

	CheckForKeypress

	if [ -e $NMAPFILE ]; then
		echo "Creating NMAP CSV file from $NMAPFILE to $NAMPFILE.csv for analysis..."
		if [ ${#DNSFILE} -gt 0 ]; then
			nmap.FormatToCSV.sh $NMAPFILE $DNSFILE > $NMAPFILE.csv
		else
			nmap.FormatToCSV.sh $NMAPFILE > $NMAPFILE.csv
		fi
	else
		echo "ERROR: Unable to find output nmap file $NMAPFILE.  Check to ensure nmap ran successfully."
		exit 3
	fi

	echo "Continuing analysis..."

	if [ $NMAPFIXED -eq 1 ]; then
		echo "Spawning nmap fixed source port rescan...[`date`]"
		if [ -e $BASEDESCRIPTOR-Fixed.gnmap ]; then
			# Scan file already exists.  Ask if we should resume or overwrite
			while true
			do
			    echo -n "NMAP file $BASEDESCRIPTOR.gnmap already exists.  Resume or Overwrite [R/O]? "
			    read -e USER_CHOICE

			    case $USER_CHOICE in
				r|R) 
				$SOCKSIFY nmap --resume $BASEDESCRIPTOR-Fixed.gnmap -PN -T4 -F  --max-retries 1 --host-timeout 180m --data-length 30 $NMAPSCANTYPE -sU --source-port 80 -oA $BASEDESCRIPTOR-Fixed -iL $HOSTFILE 2> /dev/null 1> /dev/null &
				break
				;;
				o|O)
				$SOCKSIFY nmap -PN -T4 -F  --max-retries 1 --host-timeout 180m --data-length 30 $NMAPSCANTYPE -sU --source-port 80 -oA $BASEDESCRIPTOR-Fixed -iL $HOSTFILE 2> /dev/null 1> /dev/null &
				break
				;;
				*) 
					echo "Please answer R/r or O/o!"
				;;
			      esac
			done
		else
		$SOCKSIFY nmap -PN -T4 -F  --max-retries 1 --host-timeout 180m --data-length 30 $NMAPSCANTYPE -sU --source-port 80 -oA $BASEDESCRIPTOR-Fixed -iL $HOSTFILE 2> /dev/null 1> /dev/null &
		fi
	fi

	CheckForKeypress

	if [ $DNSTESTS -eq 1 ]; then	
		# Note: No SOCKSIFY here because UDP does not support socks proxying
		DATESTR=`date`	
		echo "-------------- DNS ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "-------------- DNS ------------------ [$DATESTR]"
		echo "Looking for DNS hosts..."
		TMPRESULTS=`cat $NMAPFILE | grep " 53\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`

		if [ $NUMHOSTS -gt 0 ]; then
			mkdir dns 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/dns/$BASEDESCRIPTOR.dns_hosts.txt
			DNSLIST=`echo "$TMPRESULTS" | sed "s|\r||g" | grep -v "^$"`
			
			echo "Found $NUMHOSTS DNS listeners!"
			echo "$DNSLIST"

			for DNSIP in $DNSLIST
			do
				# Version
				nmap -PN -sV --version-intensity 7 -p 53 -sU $DNSIP > $CURDIR/dns/$DNSIP.$BASEDESCRIPTOR.dns_version.txt
	
				echo "$DNSIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
				echo "Version" >> $CURDIR/$BASEDESCRIPTOR.rpt
				cat $CURDIR/dns/$DNSIP.$BASEDESCRIPTOR.dns_version.txt | grep -i "^53/" >> $CURDIR/$BASEDESCRIPTOR.rpt

				# Recursion
				dig @$DNSIP www.google.com > $CURDIR/dns/$DNSIP.$BASEDESCRIPTOR.dns_recursion.txt
	
				if [ $? -eq 0 ]; then
					echo "Recursion" >> $CURDIR/$BASEDESCRIPTOR.rpt
					echo "Recursion available"  >> $CURDIR/$BASEDESCRIPTOR.rpt

					# check for cache snooping by now querying for the successful google result:
					TMPRESULT=`dig @$DNSIP www.google.com A +norecurse | grep "ANSWER:" | grep -o "ANSWER: \w," | sed "s|1,|Present|" | sed "s|0,|Not Present|" | sed "s|,||g" | sed "s|ANSWER: ||"`

					echo "$TMPRESULT" | grep -i "^Present" > /dev/null

					if [ $? -eq 0 ]; then
						echo "Cache snooping: Yes" > $CURDIR/dns/$DNSIP.$BASEDESCRIPTOR.dns_cachesnooping.yes.txt
						echo "Cache snooping: Yes"  >> $CURDIR/$BASEDESCRIPTOR.rpt
					else
						echo "Cache snooping: No" > $CURDIR/dns/$DNSIP.$BASEDESCRIPTOR.dns_cachesnooping.no.txt
						echo "Cache snooping: No"  >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi
				else
					echo "Recursion" >> $CURDIR/$BASEDESCRIPTOR.rpt
					echo "Recursion not available"  >> $CURDIR/$BASEDESCRIPTOR.rpt
				fi

			CheckForKeypress

			done
		else
			echo "No DNS listeners."
			echo "No DNS listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $NTPTEST -eq 1 ]; then	
		# Note: No SOCKSIFY here because UDP does not support socks proxying
		DATESTR=`date`
		echo "-------------- NTP ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "-------------- NTP ------------------ [$DATESTR]"
		echo "Looking for NTP hosts..."
		TMPRESULTS=`cat $NMAPFILE | grep " 123\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`

		if [ $NUMHOSTS -gt 0 ]; then
			mkdir ntp 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/ntp/$BASEDESCRIPTOR.ntp_hosts.txt
			NTPLIST=`echo "$TMPRESULTS" | sed "s|\r||g" | grep -v "^$"`
			
			echo "Found $NUMHOSTS NTP listeners!"
			echo "$NTPLIST"

			for NTPIP in $NTPLIST
			do
				nmap -PN -sV --version-intensity 7 -p 123 -sU $NTPIP > $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_version.txt

				echo "$NTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
				echo "Version:" >> $CURDIR/$BASEDESCRIPTOR.rpt
				cat $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_version.txt | grep "^123" >> $CURDIR/$BASEDESCRIPTOR.rpt

				if [ $USENTPQ -eq 1 ]; then
					NTPRESULT=`ntpq -p -n $NTPIP 2> /dev/null`
				else
					# Note coincidentally, both will contain the name/word refid as
					# it's an NTP parameter so the same grep works for both.
					NTPRESULT=`nmap -PN -sU -p 123 --script=ntp-info $NTPIP 2> /dev/null`
				fi

				echo "$NTPRESULT" | grep "refid" > /dev/null

				if [ $? -eq 0 ]; then
					echo "$NTPRESULT" > $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_peers.txt

					echo "$NTPRESULT" >> $CURDIR/$BASEDESCRIPTOR.rpt
					
					if [ $USENTPQ -eq 1 ]; then
						ntpq -c "rv" -n $NTPIP 2> /dev/null 1> $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_sysinfo.txt
					
						cat $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_sysinfo.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi

					if [ $METASPLOIT -eq 1 ]; then
						# Attempt to list of recent clients
						NTPRECENTCLIENTS=`msfconsole -x "use auxiliary/scanner/ntp/ntp_monlist; set RHOSTS $NTPIP; exploit; exit" 2>/dev/null`

						NTPLINES=`echo "$NTPRECENTCLIENTS" | wc -l`

						if [ $NTPLINES -gt 3 ]; then
							echo "$NTPRECENTCLIENTS" > $CURDIR/ntp/$NTPIP.$BASEDESCRIPTOR.ntp_recent_clients.txt
							echo "$NTPRECENTCLIENTS" >> $CURDIR/$BASEDESCRIPTOR.rpt
						else
							echo "Unable to retrieve recent client list from $NTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi
					fi
				else
					echo "Although reported open, no ntp response from $NTPIP"
					echo "Although reported open, no ntp response from $NTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
				fi
			
			CheckForKeypress

			done
		else
			echo "No NTP listeners."
			echo "No NTP listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $SSH -eq 1 ]; then	
		DATESTR=`date`
		echo "-------------- SSH ------------------ [$DATESTR]"
		echo "-------------- SSH ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "Looking for ssh hosts..."
		TMPRESULTS=`cat $NMAPFILE | grep -v " 22\/open\/tcp\/\/tcpwrapped" | grep " 22\/open\/" | grep -o -E "Host: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
		
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir ssh 2> /dev/null

			echo "$TMPRESULTS" > $CURDIR/ssh/$BASEDESCRIPTOR.ssh_hosts.txt

			SSHLIST=`cat $CURDIR/ssh/$BASEDESCRIPTOR.ssh_hosts.txt`
			SSHLIST=`echo "$SSHLIST" | sed "s|\r||g"`
			
			echo "Found $NUMHOSTS SSH Listeners!"
			echo "$SSHLIST"

			for SSHIP in $SSHLIST
			do
				if [ ${#SSHIP} -gt 0 ]; then
					# Dump public key
					$SOCKSIFY ssh-keyscan $SSHIP > $CURDIR/ssh/$SSHIP.$BASEDESCRIPTOR.ssh_publickey.txt 2> /dev/null

					# Get version info
					$SOCKSIFY nmap -PN -sV --version-intensity 7 -p 22 $SSHIP > $CURDIR/ssh/$SSHIP.$BASEDESCRIPTOR.ssh_version.txt

					echo "$SSHIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/ssh/$SSHIP.$BASEDESCRIPTOR.ssh_version.txt | grep "^22" >> $CURDIR/$BASEDESCRIPTOR.rpt

					# Test for SSH v1 weak encryption
					SSHRESULT=`$SOCKSIFY ssh -o "Protocol 1" -o "BatchMode yes" -o "StrictHostKeyChecking no" root@$SSHIP 2>&1`
				
					echo "$SSHRESULT" | grep "versions differ" > /dev/null

					if [ $? -gt 0 ]; then
						#version mismatch message not found and therefore ssh v1 supported
						echo "$SSHRESULT" > $CURDIR/ssh/$SSHIP.$BASEDESCRIPTOR.ssh_v1.yes.txt
						echo "$SSHIP Supports SSHv1!"
						echo "Supports SSHv1: Yes" >> $CURDIR/$BASEDESCRIPTOR.rpt
					else
						# ssh replies with "Protocol major versions differ: 1 vs. 2"
						echo "$SSHRESULT" > $CURDIR/ssh/$SSHIP.$BASEDESCRIPTOR.ssh_v1.no.txt
						echo "Supports SSHv1: no" >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi
				fi

			CheckForKeypress

			done

		else
			echo "No SSH listeners."
			echo "No SSH listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $TELNETTEST -eq 1 ]; then	
		DATESTR=`date`
		echo "-------------- Telnet ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "-------------- Telnet ------------------ [$DATESTR]"
		echo "Looking for telnet hosts..."
		TMPRESULTS=`cat $NMAPFILE | grep -v " 23\/open\/tcp\/\/tcpwrapped" | grep " 23\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
		
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir telnet 2> /dev/null

			echo "$TMPRESULTS" > $CURDIR/telnet/$BASEDESCRIPTOR.telnet_hosts.txt

			TELNETLIST=`cat $CURDIR/telnet/$BASEDESCRIPTOR.telnet_hosts.txt`
			TELNETLIST=`echo "$TELNETLIST" | sed "s|\r||g"`
			
			echo "Found $NUMHOSTS Telnet Listeners!"
			echo "$TELNETLIST"

			for TELNETIP in $TELNETLIST
			do
				if [ ${#TELNETIP} -gt 0 ]; then
					echo "$TELNETIP" >> $CURDIR/$BASEDESCRIPTOR.rpt

					# Get version info
					$SOCKSIFY nmap -PN -sV --version-intensity 7 -p 23 $TELNETIP > $CURDIR/telnet/$TELNETIP.$BASEDESCRIPTOR.telnet_version.txt
					echo "Version:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/telnet/$TELNETIP.$BASEDESCRIPTOR.telnet_version.txt | grep "^23" >> $CURDIR/$BASEDESCRIPTOR.rpt
					# grab banner
					$SOCKSIFY nc $TELNETIP 23 > $CURDIR/telnet/$TELNETIP.$BASEDESCRIPTOR.telnet_banner.txt &

					sleep 2

					NUMNETCATS=`ps -A | grep -E " nc$" | wc -l`

					if [ $NUMNETCATS -gt 0 ]; then
						NETCATPROC=`ps -A | grep -E " nc$" | grep -Eo "^.*? pts" | sed "s|pts||" | sed "s| ||g" | grep -v "^$"`

						if [ $NETCATPROC -gt 0 ]; then
							kill $NETCATPROC
						fi

						echo "Banner:" >> $CURDIR/$BASEDESCRIPTOR.rpt
						cat $CURDIR/telnet/$TELNETIP.$BASEDESCRIPTOR.telnet_banner.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi
				fi

			CheckForKeypress

			done

		else
			echo "No telnet listeners."
			echo "No telnet listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $SMTP -eq 1 ]; then	
		if [ ! -e /opt/smtp_ehlo.txt ]; then
		  # Make the file
		  echo "ehlo localhost.localdomain" > /opt/smtp_ehlo.txt
		  echo "VRFY jsmith" >> /opt/smtp_ehlo.txt
		  echo "quit" >> /opt/smtp_ehlo.txt
		fi

		if [ ! -e /opt/smtp_badverb.txt ]; then
		  # Make the file
		  echo "t23" > /opt/smtp_badverb.txt
		  echo "quit" >> /opt/smtp_badverb.txt
		fi

		DATESTR=`date`
		echo "-------------- SMTP ------------------ [$DATESTR]"
		echo "-------------- SMTP ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "Looking for smtp hosts..."
		TMPRESULTS=`cat $NMAPFILE | grep -v " 25\/open\/tcp\/\/tcpwrapped" | grep " 25\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`

		if [ $NUMHOSTS -gt 0 ]; then
			mkdir smtp 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/smtp/$BASEDESCRIPTOR.smtp_hosts.txt

			SMTPLIST=`cat $CURDIR/smtp/$BASEDESCRIPTOR.smtp_hosts.txt | sed "s|\r||g"`
			
			echo "Found $NUMHOSTS SMTP Listeners!"
			echo "$SMTPLIST"

			for SMTPIP in $SMTPLIST
			do
				if [ ${#SMTPIP} -gt 0 ]; then
					# Get version info
					echo "$SMTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					$SOCKSIFY nmap -PN -sV --version-intensity 7 -p 25 $SMTPIP > $CURDIR/smtp/$SMTPIP.$BASEDESCRIPTOR.smtp_version.txt
					echo "Version:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/smtp/$SMTPIP.$BASEDESCRIPTOR.smtp_version.txt | grep "^25" >> $CURDIR/$BASEDESCRIPTOR.rpt
					$SOCKSIFY nc $SMTPIP 25 < /opt/smtp_ehlo.txt > $CURDIR/smtp/$BASEDESCRIPTOR.$SMTPIP.ehlo_vrfy.smtp.txt
					echo "EHLO and VRY Responses:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/smtp/$BASEDESCRIPTOR.$SMTPIP.ehlo_vrfy.smtp.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
					$SOCKSIFY nc $SMTPIP 25 < /opt/smtp_badverb.txt > $CURDIR/smtp/$BASEDESCRIPTOR.$SMTPIP.badverb.smtp.txt
					echo "Bad Verb Response:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/smtp/$BASEDESCRIPTOR.$SMTPIP.badverb.smtp.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
				fi

			CheckForKeypress

			done

		else
			echo "No smtp listeners found."
			echo "No smtp listeners found." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $FTPTEST -eq 1 ]; then	
		DATESTR=`date`
		echo "-------------- FTP ------------------ [$DATESTR]"
		echo "-------------- FTP ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "Looking for ftp hosts..."
		echo "Looking for ftp hosts..." >> $CURDIR/$BASEDESCRIPTOR.rpt

		TMPRESULTS=`cat $NMAPFILE |  grep -vi " 21\/open\/tcp\/\/tcpwrapped" | grep " 21\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
		
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir ftp 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/ftp/$BASEDESCRIPTOR.ftp_hosts.txt

			FTPLIST=`cat $CURDIR/ftp/$BASEDESCRIPTOR.ftp_hosts.txt`
			FTPLIST=`echo "$FTPLIST" | sed "s|\r||g"`
			
			echo "Found $NUMHOSTS FTP Listeners!"
			echo "$FTPLIST"

			for FTPIP in $FTPLIST
			do
				if [ ${#FTPIP} -gt 0 ]; then
					echo "$FTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					# Get version info
					$SOCKSIFY nmap -PN -sV --version-intensity 7 -p 21 $FTPIP > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_version.txt

					echo "Version:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_version.txt | grep "^21" >> $CURDIR/$BASEDESCRIPTOR.rpt

					ANONFTPRESULT=`$SOCKSIFY nmap -PN -T2 -p 21 --script=ftp-anon $FTPIP 2> /dev/null`
					echo "$ANONFTPRESULT" | grep -i "Anonymous FTP login allowed" > /dev/null

					if [ $? -eq 0 ]; then
						echo "Anonymous FTP: Yes" >> $CURDIR/$BASEDESCRIPTOR.rpt
						# anonymous access allowed
						echo "$ANONFTPRESULT" > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_anonymous.txt
						echo "$FTPIP allows anonymous access!"

						# Get directory listing:
						$SOCKSIFY lftp -c open -e "ls" ftp://$FTPIP > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_dir.txt&

						# On an error, lftp will take quite a while and keep retrying
						# This will limit it to 30 seconds then kill the process and move on
						sleep 30

						LFTPPROCLIST=`ps | grep "lftp" | grep -Eo "^     [0-9]{1,5}" | sed "s| ||g" | grep -v "^$"`

						for LFTPPROC in $LFTPPROCLIST
						do
							kill $LFTPPROC > /dev/null
						done

						if [ -e $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_dir.txt ]; then
							echo "Directory Listing:" >> $CURDIR/$BASEDESCRIPTOR.rpt
							cat $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftp_dir.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
						else
							echo "Directory Listing: Possibly blocked or empty." >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi

						# Check for FTP Bounce
						TMPRESULT=`$SOCKSIFY nmap -PN --script=ftp-bounce -p 21 $FTPIP 2> /dev/null`

						echo "$TMPRESULT" | grep -i "bounce working" > /dev/null

						if [ $? -eq 0 ]; then
							echo "FTP Bounce Scan Capable: Yes" >> $CURDIR/$BASEDESCRIPTOR.rpt
							echo "$FTPIP supports bounce scanning!"
							echo "$TMPRESULT" > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.bounce_scan.txt
						else
							echo "FTP Bounce Scan Capable: No" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi
					else
						echo "Anonymous FTP: No" >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi
				fi

			CheckForKeypress

			done
		else
			echo "No ftp listeners."
			echo "No ftp listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi

		echo "Looking for ftps hosts..."
		echo "Looking for ftps hosts..." >> $CURDIR/$BASEDESCRIPTOR.rpt

		TMPRESULTS=`cat $NMAPFILE |  grep -vi " 990\/open\/tcp\/\/tcpwrapped" | grep " 990\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
		
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir ftp 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/ftp/$BASEDESCRIPTOR.ftps_hosts.txt

			FTPLIST=`cat $CURDIR/ftp/$BASEDESCRIPTOR.ftps_hosts.txt`
			FTPLIST=`echo "$FTPLIST" | sed "s|\r||g"`
			
			echo "Found $NUMHOSTS FTPS Listeners!"
			echo "$FTPLIST"

			for FTPIP in $FTPLIST
			do
				if [ ${#FTPIP} -gt 0 ]; then
					echo "$FTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					# Get version info
					$SOCKSIFY nmap -PN -sV --version-intensity 7 -p 990 $FTPIP > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps_version.txt

					echo "Version:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					cat $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps_version.txt | grep "^990" >> $CURDIR/$BASEDESCRIPTOR.rpt

					# SSL Ciphers
					if [ $SSLTHING -eq 1 ]; then
						$SOCKSIFY $SSLTHINGEXE $FTPIP:990 > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps.SupportedCiphers.txt
						echo "Supported Ciphers:" >> $CURDIR/$BASEDESCRIPTOR.rpt
						cat $FTPIP.$BASEDESCRIPTOR.ftps.SupportedCiphers.txt >> $CURDIR/$BASEDESCRIPTOR.rpt 
					fi

					# Anonymous access
					lftp -e quit ftps://$FTPIP/

					if [ $? -gt 0 ]; then
						echo ""
					else
						echo "Anonymous FTPS: Yes" >> $CURDIR/$BASEDESCRIPTOR.rpt
						# anonymous access allowed
						echo "$FTPIP allows anonymous access." > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps_anonymous.txt
						echo "$FTPIP allows anonymous access!"

						# Get directory listing:
						$SOCKSIFY lftp -c open -e "ls" ftps://$FTPIP/ > $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps_dir.txt

						echo "Directory Listing:" >> $CURDIR/$BASEDESCRIPTOR.rpt
						cat $CURDIR/ftp/$FTPIP.$BASEDESCRIPTOR.ftps_dir.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi

				fi

			CheckForKeypress

			done
		else
			echo "No ftps listeners."
			echo "No ftps listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $SNMP -eq 1 ]; then	
		# Note: No SOCKSIFY here because UDP does not support socks proxying
		DATESTR=`date`
		echo "-------------- SNMP ------------------ [$DATESTR]"
		echo "-------------- SNMP ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "Looking for snmp hosts..."

		TMPRESULTS=`cat $NMAPFILE | grep " 161\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`

		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
				
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir snmp 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/snmp/$BASEDESCRIPTOR.snmp_hosts.txt

			echo "Found $NUMHOSTS SNMP Listeners!"

			if [ -e $CURDIR/snmp/$BASEDESCRIPTOR.snmp_hosts.txt ]; then
				SNMPLIST=`cat $CURDIR/snmp/$BASEDESCRIPTOR.snmp_hosts.txt`
				SNMPLIST=`echo "$SNMPLIST" | sed "s|\r||g"`

				echo "$SNMPLIST"
			
				for SNMPIP in $SNMPLIST
				do
					if [ ${#SNMPIP} -gt 0 ]; then
						echo "$SNMPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt

						# Get version info
						nmap -PN -sV --version-intensity 7 -p 161 -sU $SNMPIP > $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_version.txt
						echo "Version: " >> $CURDIR/$BASEDESCRIPTOR.rpt
						cat $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_version.txt | grep "^161" >> $CURDIR/$BASEDESCRIPTOR.rpt
						/opt/snmpmap/snmpmap.sh $SNMPIP $SNMPSTRINGFILE > $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_results.txt

						if [ -e $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_results.txt ]; then
							MATCHEDSTRINGS=`cat $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_results.txt | grep -v "Starting SNMP mapping" | grep -v "Finished mapping" | grep -v "\[" | sed "s|^$||g" | wc -l`

							if [ $MATCHEDSTRINGS -gt 0 ]; then
								echo "Found SNMP string(s) for $SNMPIP!"
								echo "Found SNMP string(s) for $SNMPIP!" >> $CURDIR/$BASEDESCRIPTOR.rpt
								FOUNDSTRINGS=`cat $CURDIR/snmp/$SNMPIP.$BASEDESCRIPTOR.snmp_results.txt | | grep -v "Starting SNMP mapping" | grep -v "Finished mapping" | grep -v "\[" | sed "s|^$||g"`
								echo "$FOUNDSTRINGS"
								echo "$FOUNDSTRINGS" >> $CURDIR/$BASEDESCRIPTOR.rpt
							else
								echo "No SNMP matches found for $SNMPIP."
								echo "No SNMP matches found for $SNMPIP." >> $CURDIR/$BASEDESCRIPTOR.rpt
							fi
						fi
					fi

				CheckForKeypress

				done
			fi
		else
			echo "No SNMP listeners."
			echo "No SNMP listeners." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $CITRIX -eq 1 ]; then	
		DATESTR=`date`
		echo "-------------- Citrix ------------------ [$DATESTR]"
		echo "-------------- Citrix ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
		echo "Looking for Citrix hosts..."

		TMPRESULTS=`cat $NMAPFILE  |  grep -v " 1604\/open\/tcp\/\/tcpwrapped" | grep " 1604\/open\/" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g"`
		NUMHOSTS=`echo "$TMPRESULTS" | grep -v "^$" | wc -l`
		
		if [ $NUMHOSTS -gt 0 ]; then
			mkdir citrix 2> /dev/null
			echo "$TMPRESULTS" > $CURDIR/citrix/$BASEDESCRIPTOR.citrix_hosts.txt

			echo "Found $NUMHOSTS citrix hosts!"
			CITRIXLIST=`cat $CURDIR/citrix/$BASEDESCRIPTOR.citrix_hosts.txt`
			CITRIXLIST=`echo "$CITRIXLIST" | sed "s|\r||g"`
		
			for CITRIXIP in $CITRIXLIST
			do
				if [ ${#CITRIXIP} -gt 0 ]; then
					# Read published apps
					echo "$CITRIXIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					CITRIXRESULT=`$SOCKSIFY nmap -PN -sU --script=citrix-enum-apps -p 1604 $CITRIXIP 2> /dev/null`

					echo "$CITRIXRESULT" > $CURDIR/citrix/$CITRIXIP.$BASEDESCRIPTOR.citrix_published_apps.txt

					echo "Published Apps:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					echo "$CITRIXRESULT" >> $CURDIR/$BASEDESCRIPTOR.rpt
					echo "Note: Also check for XML-published list with nmap --script=citrix-enum-apps-xml" >> $CURDIR/$BASEDESCRIPTOR.rpt

					# Enumerate servers list from specified server
					CITRIXRESULT=`$SOCKSIFY nmap -PN -sU --script=citrix-enum-servers -p 1604 $CITRIXIP 2> /dev/null`

					echo "$CITRIXRESULT" > $CURDIR/citrix/$CITRIXIP.$BASEDESCRIPTOR.citrix_enum_servers.txt

					echo "Known Servers:" >> $CURDIR/$BASEDESCRIPTOR.rpt
					echo "$CITRIXRESULT" >> $CURDIR/$BASEDESCRIPTOR.rpt
				fi

			CheckForKeypress

			done

		else
			echo "No citrix hosts found."
			echo "No citrix hosts found." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi

	if [ $WEB -eq 1 ]; then
		DATESTR=`date`
		echo "-------------- HTTP(S) ------------------ [$DATESTR]"
		echo "Looking for HTTP(S) hosts and services..."

		echo "-------------- HTTP(S) ------------------ [$DATESTR]"  >> $CURDIR/$BASEDESCRIPTOR.rpt

		# Get raw grep lines with http(s)
		TMPRESULTS=`cat $NMAPFILE | grep -E "[0-9]{2,5}\/open\/tcp\/\/(ssl.)?http(s)?" | sed "s|\r||g" | sed "s|\r||g"`

		HTTPFULLIPLIST=`echo "$TMPRESULTS" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|\r||g" | sed "s|\r||g" | grep -v "^$" | sort -u`		

		NUMHOSTS=`echo "$HTTPFULLIPLIST" | grep -v "^$" | wc -l`

		if [ $NUMHOSTS -gt 0 ]; then
			mkdir http 2>/dev/null
			mkdir http/nikto 2>/dev/null
			mkdir http/ssl 2>/dev/null 
			mkdir http/dirb 2>/dev/null 

			echo "$TMPRESULTS" > $CURDIR/http/$BASEDESCRIPTOR.http_hosts_full.txt

			echo "Found $NUMHOSTS HTTP and HTTPS Listeners!"
			echo "$HTTPFULLIPLIST"
			echo "$HTTPFULLIPLIST" > $CURDIR/http/$BASEDESCRIPTOR.http_hosts.txt

			HTTPLIST=`cat $CURDIR/http/$BASEDESCRIPTOR.http_hosts_full.txt`

			# Cycle through each and pull out IP, then SSL, then HTTP
			if [ -e $CURDIR/http/$BASEDESCRIPTOR.http_hosts_full.txt ]; then
				NIKTODIR=`ls -1d /opt/nikto/nikto-* | grep -o "nikto-.*" | grep -v "\.tar\.gz" | sort -u | tail -1`
				NIKTODIR=`echo "/opt/nikto/$NIKTODIR"`
				cd $NIKTODIR

				# make sure nikto is up to date
				echo "Checking for nikto updates..."
				./nikto.pl -update

				echo " "
				echo "Note: nikto processes are spawned to run in parrallel"
				echo "so watch output files for scan completion."
				echo " "

				if [ ${#DNSFILE} -gt 0 ]; then
					# Check to see if the file contains a full path or not...
					echo "$DNSFILE" | grep "\/" > /dev/null

					if [ $? -gt 0 ]; then
						# not a full path.
						DNSFILE=`echo "$CURDIR/$DNSFILE"`
					fi
				fi

				for HTTPIP in $HTTPFULLIPLIST
				do
					GHTTPIP=`echo "$HTTPIP" | sed 's|\.|\\\.|g' | grep -v "^$"`
					HTTPFULLLINE=`cat $CURDIR/http/$BASEDESCRIPTOR.http_hosts_full.txt | grep "$GHTTPIP"`

					echo "HTTP(s) Scanning $HTTPIP..."

					HTTPHOSTNAMES=""
					NUMHOSTNAMES=0

					if [ ${#DNSFILE} -gt 0 ]; then
						# Multiple names for this IP.  Need to scan each as Virtual Headers may be in play.
						GREPIP=`echo $HTTPIP | sed "s|\.|\\\.|g"`
						
						cat $DNSFILE | grep -E "$GREPIP$" > /dev/null

						if [ $? -eq 0 ]; then
							# Found IP in file
							HTTPHOSTNAMES=`cat $DNSFILE | grep -E "$GREPIP$" | sed "s|$GREPIP||g" | sed "s| ||g" | sed 's|\s||g'`
							NUMHOSTNAMES=`echo "$HTTPHOSTNAMES" | wc -l`
						fi
					fi

					PORTSERVICE=`echo "$HTTPFULLLINE" | grep -o -E "[0-9]{2,5}\/open\/tcp\/\/(ssl.)?http(s)?" | sed "s|\r||g" | grep -v "^$"`

					SSLPORTS=`echo "$PORTSERVICE" | grep -E "ssl" | grep -E -o "[0-9]{2,5}" | sed "s|\r||g" | grep -v "^$"`
					HTTPPORTS=`echo "$PORTSERVICE" | grep -v -E "ssl" | grep -E -o "[0-9]{2,5}" | sed "s|\r||g" | grep -v "^$"`

					echo "$HTTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
					# Scan SSL
					
					NUMPORTS=`echo "$SSLPORTS" | grep -v "^$" | wc -l`

					if [ $NUMPORTS -gt 0 ]; then
						echo "SSL Ports" >> $CURDIR/$BASEDESCRIPTOR.rpt

						echo "scanning $NUMPORTS SSL ports for $HTTPIP..."
						# Dump certificates and encryption ciphers
						for SSLPORT in $SSLPORTS
						do
							# Dump SSL details
							nmap.ssl.sh --detail $HTTPIP:$SSLPORT > $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.cert_details.txt
							# Still need to write the common name for later use
							nmap.ssl.sh $HTTPIP:SSLPORT > $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.ssl.CertCommonName.txt

							# Get version info
							$SOCKSIFY nmap -PN -sV --version-intensity 7 -p $SSLPORT $HTTPIP > $CURDIR/http/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.http_version.txt

							echo "[$SSLPORT] Version Info:" >> $CURDIR/$BASEDESCRIPTOR.rpt
							cat $CURDIR/http/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.http_version.txt | grep "^$SSLPORT" >> $CURDIR/$BASEDESCRIPTOR.rpt

							if [ $SSLTHING -eq 1 ]; then
								$SOCKSIFY $SSLTHINGEXE $HTTPIP:$SSLPORT 2> /dev/null 1> $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.ssl.SupportedCiphers.txt
								echo "Supported Ciphers:" >> $CURDIR/$BASEDESCRIPTOR.rpt
								cat $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.ssl.SupportedCiphers.txt >> $CURDIR/$BASEDESCRIPTOR.rpt 
							fi

						CheckForKeypress

						done

						if [ $RUNNIKTO -eq 1 ]; then
						for SSLPORT in $SSLPORTS
						do
							if [ -e $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.ssl.CertCommonName.txt ]; then
								CERTNAME=`cat $CURDIR/http/ssl/$BASEDESCRIPTOR.$HTTPIP.$SSLPORT.ssl.CertCommonName.txt | grep -v "*"`
								CERTNAME=`echo "$CERTNAME" | sed 's|\n||g'`
							fi

							if [ $RUNNIKTO -eq 1 ]; then
								echo "Nikto scanning $HTTPIP SSL/$SSLPORT..."
	
								# Limit number of simultaneous scans to preserve system functionality.
								# w/ 768M of memory each instance is ~5% memory utilization.  30 hosts
								# Can consume more than available memory and thrash drive.
								BoundWebScanProcesses

								WPSCANSTRING=""

								if [ ${#CERTNAME} -gt 0 ]; then
									# Use Cert name if available
									echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $CERTNAME"
									echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $CERTNAME" >> $CURDIR/$BASEDESCRIPTOR.rpt
									echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $CERTNAME"  > $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.$CERTNAME.nikto.txt
									$SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $CERTNAME >> $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.$CERTNAME.nikto.txt&
									WPSCANSTRING=`echo "$CERTNAME:$SSLPORT"`
									WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`

									if [ $RUNDIRB -eq 1 ]; then
										dirb https://$WPSCANSTRING/ -o $CURDIR/http/dirb/$WPSCANNAME.dirb.txt -S &
										
										BoundWebScanProcesses
									fi

									if [ $RUNARACHNI -eq 1 ]; then
										arachni.run.sh https://$WPSCANSTRING "$WPSCANNAME.afr" 2>&1 1>/dev/null &
									fi
									
									wget -q -O- https://$WPSCANSTRING/wp-content/plugins/

									if [ $? -eq 0 ]; then
										echo "Running wpscan https://$WPSCANSTRING/"
										echo "Running wpscan https://$WPSCANSTRING/" >> $CURDIR/$BASEDESCRIPTOR.rpt
										# wp-content/plugins responded 200 OK.  Run wpscan
										if [ ! -e $CURDIR/http/wpscan ]; then
											mkdir $CURDIR/http/wpscan 2>/dev/null
										fi

										if [ -e /opt/wpscan/wpscan.rb ]; then
											/opt/wpscan/wpscan.rb --follow-redirection --threads 30 --url https://$WPSCANSTRING/ > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt

											cat $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt | strings | sed "s|\[3[1-2]m||g" | sed "s|\[0m||g" > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2
											if [ -e $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 ]; then
												rm $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
												mv $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
											fi
										fi
									fi

								else
									if [ ${#HTTPHOSTNAMES} -gt 0 ]; then
									   # If no good cert name, use DNS lookup if available
									   for VHOST in $HTTPHOSTNAMES
									   do
										if [ ${#VHOST} -gt 0 ]; then
											echo "Running ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $VHOST"
											echo "Running ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $VHOST" >> $CURDIR/$BASEDESCRIPTOR.rpt
											echo "Running ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $VHOST" > $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.$VHOST.nikto.txt
											$SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP -vhost $VHOST >> $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.$VHOST.nikto.txt&

											WPSCANSTRING=`echo "$VHOST:$SSLPORT"`
											WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`

											if [ $RUNDIRB -eq 1 ]; then
												dirb https://$WPSCANSTRING/ -o $CURDIR/http/dirb/$WPSCANNAME.dirb.txt -S &
												BoundWebScanProcesses
											fi

											if [ $RUNARACHNI -eq 1 ]; then
												arachni.run.sh https://$WPSCANSTRING "$WPSCANNAME.afr" 2>&1 1>/dev/null &
											fi
											
											wget -q -O- https://$WPSCANSTRING/wp-content/plugins/

											if [ $? -eq 0 ]; then
												echo "Running wpscan https://$WPSCANSTRING/"
												echo "Running wpscan https://$WPSCANSTRING/" >> $CURDIR/$BASEDESCRIPTOR.rpt
												# wp-content/plugins responded 200 OK.  Run wpscan
												if [ ! -e $CURDIR/http/wpscan ]; then
													mkdir $CURDIR/http/wpscan 2>/dev/null
												fi

												if [ -e /opt/wpscan/wpscan.rb ]; then
													/opt/wpscan/wpscan.rb --follow-redirection --threads 30 --url https://$WPSCANSTRING/ > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt

													cat $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt | strings | sed "s|\[3[1-2]m||g" | sed "s|\[0m||g" > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2
													if [ -e $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 ]; then
														rm $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
														mv $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
													fi
												fi
											fi

										fi
									   done
									else
										# Otherwise, just scan straight
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP"
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP" > $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.nikto.txt
										$SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $SSLPORT -ssl -host $HTTPIP >> $CURDIR/http/nikto/$BASEDESCRIPTOR.https.$HTTPIP.$SSLPORT.nikto.txt&

										WPSCANSTRING=`echo "$HTTPIP:$SSLPORT"`
										WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`

										if [ $RUNDIRB -eq 1 ]; then
											dirb https://$WPSCANSTRING/ -o $CURDIR/http/dirb/$WPSCANNAME.dirb.txt -S &
											BoundWebScanProcesses
										fi
										
										WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`
										
										if [ $RUNARACHNI -eq 1 ]; then
											arachni.run.sh https://$WPSCANSTRING "$WPSCANNAME.afr" 2>&1 1>/dev/null &
										fi
										
										wget -q -O- https://$WPSCANSTRING/wp-content/plugins/

										if [ $? -eq 0 ]; then
											echo "Running wpscan https://$WPSCANSTRING/"
											echo "Running wpscan https://$WPSCANSTRING/" >> $CURDIR/$BASEDESCRIPTOR.rpt
											# wp-content/plugins responded 200 OK.  Run wpscan
											if [ ! -e $CURDIR/http/wpscan ]; then
												mkdir $CURDIR/http/wpscan 2>/dev/null
											fi

											if [ -e /opt/wpscan/wpscan.rb ]; then
												/opt/wpscan/wpscan.rb --follow-redirection --threads 30 --url https://$WPSCANSTRING/ > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt

												cat $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt | strings | sed "s|\[3[1-2]m||g" | sed "s|\[0m||g" > $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2
												if [ -e $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 ]; then
													rm $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
													mv $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt2 $CURDIR/http/wpscan/$BASEDESCRIPTOR.https.$HTTPIP.$WPSCANNAME.wpscan.txt
												fi
											fi
										fi

									fi

								fi
							fi

						CheckForKeypress

						done
						fi
					else
						echo "No SSL ports for $HTTPIP..."
						echo "No SSL ports for $HTTPIP..." >> $CURDIR/$BASEDESCRIPTOR.rpt
					fi

					NUMPORTS=`echo "$HTTPPORTS" | grep -v "^$" | wc -l`

					if [ $NUMPORTS -gt 0 ]; then
						if [ $SSLONLY -eq 0 ]; then
							echo "HTTP Ports" >> $CURDIR/$BASEDESCRIPTOR.rpt

							# Scan HTTP
							echo "scanning $NUMPORTS http ports for $HTTPIP..."
							for HTTPPORT in $HTTPPORTS
							do
								echo "[$HTTPPORT] Version Info:" >> $CURDIR/$BASEDESCRIPTOR.rpt
								# Get version info
								$SOCKSIFY nmap -PN -sV --version-intensity 7 -p $HTTPPORT $HTTPIP > $CURDIR/http/$BASEDESCRIPTOR.http.$HTTPIP.$HTTPPORT.http_version.txt
								cat $CURDIR/http/$BASEDESCRIPTOR.http.$HTTPIP.$HTTPPORT.http_version.txt | grep "^$HTTPPORT" >> $CURDIR/$BASEDESCRIPTOR.rpt

								# Check for open relay
								TMPRESULTS=`$SOCKSIFY nmap -PN -p $HTTPPORT --script=http-open-proxy $HTTPIP 2> /dev/null`
	
								echo "$TMPRESULTS" | grep -i "Potentially OPEN proxy" > /dev/null

								if [ $? -eq 0 ]; then
									echo "[$HTTPPORT] Potentially open proxy: Yes" >> $CURDIR/$BASEDESCRIPTOR.rpt
									echo "$TMPRESULTS" > $CURDIR/http/$BASEDESCRIPTOR.http.$HTTPIP.$HTTPPORT.open_proxy.txt
								else
									echo "[$HTTPPORT] Potentially open proxy: No" >> $CURDIR/$BASEDESCRIPTOR.rpt
								fi

								if [ $RUNNIKTO -eq 1 ]; then
									BoundWebScanProcesses

									WPSCANSTRING=""
									echo "Nikto scanning $HTTPIP HTTP/$HTTPPORT..."
									if [ ${#HTTPHOSTNAMES} -gt 0 ]; then
									   # If no good cert name, use DNS lookup if available
									   for VHOST in $HTTPHOSTNAMES
									   do
										if [ ${#VHOST} -gt 0 ]; then
											# If using DNS lookup and a host name is available, use it
											echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP -vhost $VHOST"
											echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP -vhost $VHOST" >> $CURDIR/$BASEDESCRIPTOR.rpt
											echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP -vhost $VHOST" > $CURDIR/http/nikto/$BASEDESCRIPTOR.http.$HTTPPORT.$VHOST.nikto.txt
											$SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP -vhost $VHOST >> $CURDIR/http/nikto/$BASEDESCRIPTOR.http.$HTTPPORT.$VHOST.nikto.txt&

											WPSCANSTRING=`echo "$VHOST:$HTTPPORT"`
											WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`

											if [ $RUNDIRB -eq 1 ]; then
												dirb http://$WPSCANSTRING/ -o $CURDIR/http/dirb/$WPSCANNAME.dirb.txt -S &
												BoundWebScanProcesses
											fi

											if [ $RUNARACHNI -eq 1 ]; then
												arachni.run.sh https://$WPSCANSTRING "$WPSCANNAME.afr" 2>&1 1>/dev/null &
											fi
											
											wget -q -O- http://$WPSCANSTRING/wp-content/plugins/

											if [ $? -eq 0 ]; then
												echo "Running wpscan http://$WPSCANSTRING/"
												echo "Running wpscan http://$WPSCANSTRING/" >> $CURDIR/$BASEDESCRIPTOR.rpt
												# wp-content/plugins responded 200 OK.  Run wpscan
												if [ ! -e $CURDIR/http/wpscan ]; then
													mkdir $CURDIR/http/wpscan 2>/dev/null
												fi

												if [ -e /opt/wpscan/wpscan.rb ]; then
													/opt/wpscan/wpscan.rb --follow-redirection --threads 30 --url http://$WPSCANSTRING/ > $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt

													cat $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt | strings | sed "s|\[3[1-2]m||g" | sed "s|\[0m||g" > $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2
													if [ -e $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2 ]; then
														rm $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt
														mv $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2 $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt
													fi

												fi
											fi

										fi
									   done
									else
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP"
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP" >> $CURDIR/$BASEDESCRIPTOR.rpt
										echo "Running $SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP" > $CURDIR/http/nikto/$BASEDESCRIPTOR.http.$HTTPIP.$HTTPPORT.nikto.txt
										$SOCKSIFY ./nikto.pl -evasion 1 -maxtime 4h -timeout 5 -port $HTTPPORT -host $HTTPIP >> $CURDIR/http/nikto/$BASEDESCRIPTOR.http.$HTTPIP.$HTTPPORT.nikto.txt&

										WPSCANSTRING=`echo "$HTTPIP:$HTTPPORT"`
										WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`
										
										if [ $RUNDIRB -eq 1 ]; then
											dirb http://$WPSCANSTRING/ -o $CURDIR/http/dirb/$WPSCANNAME.dirb.txt -S &
											BoundWebScanProcesses
										fi

										if [ $RUNARACHNI -eq 1 ]; then
											arachni.run.sh https://$WPSCANSTRING "$WPSCANNAME.afr" 2>&1 1>/dev/null &
										fi
										
										wget -q -O- http://$WPSCANSTRING/wp-content/plugins/

										if [ $? -eq 0 ]; then
											echo "Running wpscan http://$WPSCANSTRING/"
											echo "Running wpscan http://$WPSCANSTRING/" >> $CURDIR/$BASEDESCRIPTOR.rpt
											# wp-content/plugins responded 200 OK.  Run wpscan
											if [ ! -e $CURDIR/http/wpscan ]; then
												mkdir $CURDIR/http/wpscan 2>/dev/null
											fi

											if [ -e /opt/wpscan/wpscan.rb ]; then
												WPSCANNAME=`echo "$WPSCANSTRING" | sed "s|:|\.|"`
												/opt/wpscan/wpscan.rb --follow-redirection --threads 30 --url http://$WPSCANSTRING/ > $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$WPSCANNAME.wpscan.txt

												cat $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt | strings | sed "s|\[3[1-2]m||g" | sed "s|\[0m||g" > $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2
												if [ -e $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2 ]; then
													rm $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt
													mv $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt2 $CURDIR/http/wpscan/$BASEDESCRIPTOR.http.$HTTPIP.$WPSCANNAME.wpscan.txt
												fi
											fi
										fi

									fi
								fi
							
								CheckForKeypress

							done
						else
							echo "HTTP scanning disabled (SSLONLY)" >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi
					else
						if [ $SSLONLY -eq 0 ]; then
							# Don't confuse the user by displaying this message if SSLONLY is set.
							echo "No http ports for $HTTPIP..."
							echo "No http ports for $HTTPIP..." >> $CURDIR/$BASEDESCRIPTOR.rpt
						fi
					fi

				CheckForKeypress

				done

				# Summarize cert info into one file
				CERTFILES=`ls -1 $CURDIR/http/ssl/$BASEDESCRIPTOR.*.cert_details.txt`

				if [ `echo "$CERTFILES" | wc -l` -gt 0 ]; then
					echo -e "Common Name\tIP Address\tPort\tIssuer\tExpiration\tSupported Ciphers" > $CURDIR/http/$BASEDESCRIPTOR.ssl_summary.txt
					cat $CURDIR/http/ssl/$BASEDESCRIPTOR.*.cert_details.txt | grep -v "^Common Name" >> $CURDIR/http/ssl/$BASEDESCRIPTOR.ssl_summary.txt

					if [ -e $CURDIR/http/ssl/$BASEDESCRIPTOR.ssl_summary.txt ]; then
						cp $CURDIR/http/ssl/$BASEDESCRIPTOR.ssl_summary.txt $CURDIR/http/
					fi
				fi

				# Return from nikto directory
				cd $CURDIR

				# because of the way while handles the stack, can't dynamically
				# update the NUMNIKTO variable inside the loop.  Need the exec quotes
				echo -n "Waiting for `ps -A | grep nikto | wc -l` nikto processes to finish to post-process nikto data (use nikto.showprocesses.sh to monitor status)..."
				while [ `ps -A | grep nikto | wc -l` -gt 0 ]
				do
					echo -n "."
					sleep 9s
	
					CheckForKeypress
				done	

				# Sort out the Nikto results.
				cd $CURDIR/http/nikto
				nikto.move_nofindings.sh
				mkdir summary 2>/dev/null

				nikto.ConvertToCSV.sh > summary/$BASEDECRIPTOR.all_nikto.csv

				if [ -e summary/$BASEDESCRIPTOR.all_nikto.csv ]; then
					cp summary/$BASEDESCRIPTOR.all_nikto.csv $CURDIR/http/
				fi
					
							
			fi
		else
			echo "No web listeners."
		fi
	fi	
else
	if [ $NMAPFIXED -eq 1 ]; then
		echo "Spawning nmap fixed source port rescan...[`date`]"
		$SOCKSIFY nmap -PN -T4 -F $NMAPSCANTYPE -sU --source-port 80 -oA $BASEDESCRIPTOR-Fixed -iL $HOSTFILE 2> /dev/null &
	fi

	CheckForKeypress

fi


# -----------------------------------------------------------
if [ $TRACERT -eq 1 ]; then
# Note: Tracert can take a long time to run so we do it last.
	DATESTR=`date`
	echo "-------------- Trace ------------------ [$DATESTR]"
	echo "-------------- Trace ------------------ [$DATESTR]" >> $CURDIR/$BASEDESCRIPTOR.rpt
	echo "Running traceroute..."
	mkdir trace 2> /dev/null
	echo "Tracing Hosts" > $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt
	echo "`date`" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt
	
	if [ $ISLINUX -eq 1 ]; then
		echo "Tracing Hosts" > $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt
		echo "`date`" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt
	fi
	
	CheckForKeypress

	for HOSTIP in $HOSTLIST
	do
		echo "Tracing $HOSTIP..."
		if [ $ISLINUX -eq 0 ]; then
	#		Cygwin
			tracert -w 2000 $HOSTIP >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt
		else
	#		Linux
			tracert -w 2 -I $HOSTIP >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt

			# Output looks a little different.  Standardize for later grep
			echo "" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt	
			echo "Trace complete." >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt	

			tracert -w 2 $HOSTIP >> $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt

			echo "" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt	
			echo "Trace complete." >> $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt	
		fi

	CheckForKeypress

	done

	echo "`date`" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt

	cat $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.txt | grep -B 2 "Trace complete" | grep -E "[0-9] ms" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u > $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.success.txt

	NUMHOSTS=`cat $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.success.txt | grep -v "^$" | wc -l`

	if [ $NUMHOSTS -gt 0 ]; then
		echo "ICMP Trace successful to:"
		cat $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.success.txt

		echo "ICMP Trace successful to:"  >> $CURDIR/$BASEDESCRIPTOR.rpt
		cat $CURDIR/trace/$BASEDESCRIPTOR.trace_icmp.success.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
	else
		echo "Unable to icmp trace to hosts."
		echo "Unable to icmp trace to hosts." >> $CURDIR/$BASEDESCRIPTOR.rpt
	fi

	if [ $ISLINUX -eq 1 ]; then
		echo "`date`" >> $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt

		cat $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.txt | grep -B 2 "Trace complete" | grep -E "[0-9] ms" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u > $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.success.txt

		NUMHOSTS=`cat $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.success.txt | grep -v "^$" | wc -l`

		if [ $NUMHOSTS -gt 0 ]; then
			echo "UDP Trace successful to:"
			cat $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.success.txt

			echo "UDP Trace successful to:" >> $CURDIR/$BASEDESCRIPTOR.rpt
			cat $CURDIR/trace/$BASEDESCRIPTOR.trace_udp.success.txt >> $CURDIR/$BASEDESCRIPTOR.rpt
		else
			echo "Unable to udp trace to hosts."

			echo "Unable to udp trace to hosts." >> $CURDIR/$BASEDESCRIPTOR.rpt
		fi
	fi
fi

# -----------------------------------------------------------
echo "Scan completed [`date`]"
echo "Scan completed [`date`]" >> $CURDIR/$BASEDESCRIPTOR.rpt

