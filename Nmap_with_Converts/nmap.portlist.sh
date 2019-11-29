#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> <port list> [base descriptor]"
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
}

EXPECTED_ARGS=2

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

if [ $# -gt 2 ]; then
	# Base Descriptor.  Output to files.
	nmap -sV -T4 -O --version-light -sS -p $2 -oA $3 $1
else
	# Just scan
	nmap -sV -T4 -O --version-light -sS -p $2 $1
fi
