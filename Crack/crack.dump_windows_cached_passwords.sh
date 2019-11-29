#!/bin/bash

ShowUsage() {
	echo "$0 Usage:"
	echo "$0 [SYSTEM HIVE FILE] [SECURITY HIVE FILE]"
	echo "$0 requires the SYSTEM and SECURITY registry hive files from a Windows drive (in <WINDIR>/system32/config) and extracts cached logon credentials (e.g. cached domain logon credentials"
	echo ""
	echo "If the files are not provided, the local directory will be assumed."
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

SYSTEMHIVEFILE="SYSTEM"
SECURITYHIVEFILE="SECURITY"

if [ $# -gt 0 ]; then
	SYSTEMHIVEFILE="$1"

	if [ $# -gt 1 ]; then
		SECURITYHIVEFILE="$2"
	fi
fi

if [ ! -e $SYSTEMHIVEFILE ]; then
	echo "ERROR: Unable to find $SYSTEMHIVEFILE"
	exit 2
fi

if [ ! -e $SECURITYHIVEFILE ]; then
	echo "ERROR: Unable to find $SECURITYHIVEFILE"
	exit 2
fi


cachedump $SYSTEMHIVEFILE $SECURITYHIVEFILE
