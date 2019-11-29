#!/bin/bash

ShowUsage() {
	echo "$0 Usage:"
	echo "$0 <Windows drive mount point> [username]"
	
	echo ""
	
	echo "$0 will change into the system32/config directory of a mounted Windows hard drive and run 'chntpw -u <username>'."
	echo "If Username isn't provided, $0 will dump the list of available users."
	echo ""
	echo "Note: chntpw (part of Kali) can also be used to promote an existing user to Administrator."
	echo "      Also, changing the pwd on Win7 does not always work, however setting it to <blank> will."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

WINDIR="$1"
WINUSERNAME=""

if [ $# -gt 1 ]; then
	WINUSERNAME="$2"
fi

if [ ! -e $WINDIR ]; then
	echo "ERROR: Unable to find directory $WINDIR"
	exit 2
fi

cd "$WINDIR"

if [ ! -e ./SAM ]; then
	echo "ERROR: Unable to find SAM file in $WINDIR"
	exit 3
fi

if [ ${#WINUSERNAME} -gt 0 ]; then
	chntpw -u "$WINUSERNAME" SAM
else
	chntpw -l SAM
fi
