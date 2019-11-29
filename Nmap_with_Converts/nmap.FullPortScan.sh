#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> <base descriptor> [--ping-first]"
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
  echo "If --ping-first is specified, nmap is not run with -Pn"
  echo "Note: these parameters must be AFTER the target and base descriptor but can be in any order."
  echo ""
  echo "Target can be specified as file:<file> to use an input file of hosts"
  echo ""
}

EXPECTED_ARGS=2

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

SCANMICROSOFT=1
PINGFIRST=0

for i in $*
do
	case $i in
	--help)
		ShowUsage
		exit 1
	;;
	--ping-first)
		PINGFIRST=1
	;;
  	esac
done

if [ $PINGFIRST -eq 0 ]; then
	# Don't ping first
	DONTSCANPARM="-Pn"
else
	# enable this to allow ping checks
	DONTSCANPARM=""
fi

PORTLIST="T:0-65535,U:53,123,135-139,161,500,1434,5060,5061"

TARGET="$1"
BASEDESCRIPTOR="$2"

echo "$TARGET" | grep -iq "^file:"

if [ $? -eq 0 ]; then
	# is a file designator
	NETFILE=`echo "$TARGET" | sed "s|file:||" | sed "s|FILE:||"`

	if [ ! -e $NETFILE ]; then
		echo "ERROR: Unable to find file '$NETFILE'"
		exit 2
	fi

	# Base Descriptor.  Output to files.
	# Full for newest nmap: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR $TARGET
	# Full from file: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR -iL $TARGETFILE
# Took -sC script scan out because it was too "noisy"
	nmap $DONTSCANPARM -n -sV -T3 -O -p "$PORTLIST" --max-retries 2 --version-intensity 3 -sT -sU -oA $BASEDESCRIPTOR -iL $NETFILE
else
	nmap $DONTSCANPARM -n -sV -T3 -O -p "$PORTLIST"  --max-retries 2 --version-intensity 3 -sT -sU -oA $BASEDESCRIPTOR $TARGET
fi


