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
	nmap -n -Pn -sV -T2 -O -F --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS -oA $BASEDESCRIPTOR $TARGET
else
	# Just scan
	nmap -n -Pn -sV -T2 -O -F --max-retries 1 --host-timeout 180m --data-length 31 --version-intensity 3 -sS $TARGET
fi

