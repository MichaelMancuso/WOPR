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

if [ $# -gt 1 ]; then
	# Base Descriptor.  Output to files.
	nmap -n -T3 -O -F --max-retries 1 --host-timeout 180m --data-length 31 -sS -sU -oA $2 $1
else
	# Just scan
	nmap -n -T3 -O -F --max-retries 1 --host-timeout 180m --data-length 31 -sS -sU $1
fi
