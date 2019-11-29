#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> [base descriptor]"
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
  echo ""
  echo "Note: If you'd like to provide an input file with subnets"
  echo "specify target as file:<file>"
  echo""
}

EXPECTED_ARGS=1

if [ $# -lt $EXPECTED_ARGS ];then
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
	esac
done

# The don't ping hosts param has changed from -PN to -Pn.  Have to check the NMAP version
DONTSCANPARM="-PN"
# Use this one to scan UDP too
UDPSETTING="-sU"
# UDPSETTING=""
nmap --help | grep -q "\-Pn"

if [ $? -eq 0 ]; then
	DONTSCANPARM="-Pn"
fi

TARGET="$1"

if [ $# -gt 1 ]; then
	# Base Descriptor.  Output to files.
	BASEDESCRIPTOR="$2"

	echo "$TARGET" | grep -iq "^file:"

	if [ $? -eq 0 ]; then
		# is a file designator
		NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

		if [ ! -e $NETFILE ]; then
			echo "ERROR: Unable to find file '$NETFILE'"
			exit 2
		fi

#		Copyable line version:
#		nmap -Pn -n -sV -T3 -O -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT -oA $BASEDESCRIPTOR <target>
#		A little faster: (Note -F is the same as --top-ports 100, and version scanning [-sV] significantly increases scan time)
#		nmap -Pn -n -T3 --top-ports 50 --max-retries 1 --host-timeout 180m --data-length 31 -sT -oA $BASEDESCRIPTOR <target>
#		Faster -p list covering DB's, common ports, remote access, NFS, web servers, and voice:
#		21,22,23,25,53,80,88,110,111,389,427,443,515,636,657,990,992,1025,1159,1433,1434,1575,1630,1720,2001,2002,2005,2512,2513,2598,2897,3000,3306,3389,5001,5002,5060,5061,5080,5432,5555,5900,8000,8009,8080,8443,10000

		nmap $DONTSCANPARM -n -sV -T3 -O -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT $UDPSETTING -oA $BASEDESCRIPTOR -iL $NETFILE
	else
		nmap $DONTSCANPARM -n -sV -T3 -O -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT $UDPSETTING -oA $BASEDESCRIPTOR $TARGET
	fi

else
	# Just scan
	nmap $DONTSCANPARM -n -sV -T3 -O -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT $UDPSETTING $TARGET
fi

