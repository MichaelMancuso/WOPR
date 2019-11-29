#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <target system> <SMB Domain> [<user/pass file> or <account name> <password>]"
	echo "$0 will test the specified username and password against the specified target."
	echo ""
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

TARGET="$1"
SMBDOMAIN="$2"
SMBUSER="$3"
SMBPASS="$4"

if [ -e $SMBUSER ]; then
	# It's a file
	USERFILE=$3
else
	USERFILE = ""
fi

# Change whitespace to a new line
IFS_BAK=$IFS
IFS="
"

if [ ${#USERFILE} -eq 0 ]; then
	# msfcli auxiliary/scanner/smb/smb_login RHOSTS=$TARGET SMBDomain=$SMBDOMAIN SMBUser=$SMBUSER SMBPass=$SMBPASS E
	msfconsole -x "use auxiliary/scanner/smb/smb_login; set RHOSTS $TARGET; set SMBDomain $SMBDOMAIN; set SMBUser $SMBUSER; set SMBPass $SMBPASS; exploit; exit"
else
	msfconsole -x "use auxiliary/scanner/smb/smb_login; set RHOSTS $TARGET; set SMBDomain $SMBDOMAIN; set USERPASS_FILE $USERFILE; exploit; exit"
fi

# Change whitespace back
IFS=$IFS_BAK
IFS_BAK=


