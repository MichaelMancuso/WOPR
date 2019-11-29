#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> [base descriptor]"
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
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
# This port list includes SIP, SIP-TLS, H.323, IAX1, IAX2, SKINNY, Microsoft Lync ports, etc.
PORTLIST="4569,5222,6600,1720,1731,2000,5036,5060,5061,5062,5063,5064,5065,5066,5067,5068,5070,5071,5072,5073,5075,5076,5080,5081,5082,8057,8058,8404"
# Use this one to scan UDP too
UDPSETTING="-sU"
nmap --help | grep -q "\-Pn"

if [ $? -eq 0 ]; then
	DONTSCANPARM="-Pn"
fi

# enable this to allow ping checks
# DONTSCANPARM=""

if [ $# -gt 1 ]; then
	# Base Descriptor.  Output to files.
	BASEDESCRIPTOR=$2
	TARGET=$1
	# Full for newest nmap: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR $TARGET
	# Full from file: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR -iL $TARGETFILE
# Took -sC script scan out because it was too "noisy"
	nmap $DONTSCANPARM -sV -T3 -O -p $PORTLIST  --scan-delay 2ms --max-retries 1 --host-timeout 60m --data-length 31 --version-intensity 3 -sT $UDPSETTING -oA $BASEDESCRIPTOR $TARGET
else
	# Just scan
	nmap $DONTSCANPARM -sV -T3 -O -p $PORTLIST  --scan-delay 2ms --max-retries 1 --host-timeout 60m --data-length 31 --version-intensity 3 -sT $UDPSETTING $TARGET
fi

