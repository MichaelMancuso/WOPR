#!/bin/sh

# --------------- Functions -------------------------
ShowUsage() {
  echo "usage: $0 <target> <port list> <-T | -U> [base descriptor]"
  echo "Launches nmap against specified ports and scans for version information."
  echo " "
  echo "-T or -U indicate TCP or UDP port(s) respectively"
  echo " "
  echo "If a base descriptor is provided, nmap generates "
  echo "all three output formats with the specified base name."
}

EXPECTED_ARGS=3

if [ $# -lt $EXPECTED_ARGS ];then
  ShowUsage
  exit 1
fi

if [ $# -gt 3 ]; then
	# Base Descriptor.  Output to files.
	case $3 in
    	-U)
		nmap -sV -sU -O --version-intensity 6 -sS -p $2 -oA $4 $1
	;;
    	-T)
		nmap -sV -O --version-intensity 6 -sS -p $2 -oA $4 $1
	;;
    	*)
		ShowUsage
  	esac
else
	# Just scan
	case $3 in
    	-U)
		nmap -sV -sU -O --version-intensity 6 -sS -p $2 $1
	;;
	-T)
		nmap -sV -O --version-intensity 6 -sS -p $2 $1
	;;
    	*)
		ShowUsage
  	esac
fi
