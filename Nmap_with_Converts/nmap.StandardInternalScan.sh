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
# Use this one to scan UDP too
UDPSETTING="-sU"
# UDPSETTING=""
nmap --help | grep -q "\-Pn"

if [ $? -eq 0 ]; then
	DONTSCANPARM="-Pn"
fi

# enable this to allow ping checks
DONTSCANPARM=""

if [ $# -gt 1 ]; then
	# Base Descriptor.  Output to files.
	BASEDESCRIPTOR=$2
	TARGET=$1
	# Full for newest nmap: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR $TARGET
	# Full from file: nmap -Pn -sV -T3 -A -F  --scan-delay 2ms --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -sU -oA $BASEDESCRIPTOR -iL $TARGETFILE
# Took -sC script scan out because it was too "noisy"
	nmap $DONTSCANPARM -n -sV -T4 -O --scan-delay 2ms --max-retries 1 --host-timeout 60m --data-length 31 --version-intensity 3 -sS $UDPSETTING -oA $BASEDESCRIPTOR $TARGET
else
	# Just scan
	nmap $DONTSCANPARM -n -sV -T4 -O --scan-delay 2ms --max-retries 1 --host-timeout 60m --data-length 31 --version-intensity 3 -sS $UDPSETTING $TARGET
fi

