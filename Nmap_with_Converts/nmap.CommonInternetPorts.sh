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


if [ $# -gt 1 ]; then
	# Base Descriptor.  Output to files.
	BASEDESCRIPTOR=$2
	TARGET=$1
	nmap -Pn -n -sV -T3 -O -p T:21,22,23,25,53,80,110,115,123,161,443,636,990,2000,2001,2512,2513,3389,8000,8080,8443,10000,U:53,161,500,5060,5061 --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT -sU -oA $BASEDESCRIPTOR $TARGET
else
	# Just scan
	nmap -Pn -n -sV -T3 -O -p T:21,22,23,25,53,80,110,115,123,161,443,636,990,2000,2001,2512,2513,3389,8000,8080,8443,10000,U:53,123,161,500,5060,5061 --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sT -sU $TARGET
fi

