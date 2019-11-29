#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <current file> <current computer> [debug]"
	echo "Note that this script is meant to be used with audit-results-process.sh and not called directly"
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

if [ $# -gt 2 ]; then
	DEBUG=1
else
	DEBUG=0
fi

CURFILE="$1"
CURCOMPUTER="$2"

IFS_BAK=$IFS
IFS="
"

echo "$CURFILE" | grep -q "\.software"

if [ $? -eq 0 ]; then
	ISSOFTWARE=1
else
	ISSOFTWARE=0
fi

# Find Software
if [ $ISSOFTWARE -eq 1 ]; then
	SOFTWARE=`cat "../$CURFILE" | sed "s|\r||g"`
	SOFTWARE=`echo "$SOFTWARE" | grep -v "^$" | grep -v "^Microsoft (R) Windows Script Host Version" | grep -v "Copyright (C) Microsoft Corporation"` 
	NUMSOFTWARE=`echo "$SOFTWARE" | wc -l`

	if [ $NUMSOFTWARE -gt 0 ]; then
		for CURSOFTWARE in $SOFTWARE; do
			echo "$CURSOFTWARE" >> software_list.tmp
			echo -e "$CURCOMPUTER\t$CURSOFTWARE" >> software_computer_list.txt
		done
	else
		echo "[`date`] ERROR: No software listed for $CURCOMPUTER." 
		echo "[`date`] ERROR: No software listed for $CURCOMPUTER." >> messages.txt
	fi
	
fi

# Find Services
echo "$CURFILE" | grep -q "\.services"

if [ $? -eq 0 ]; then
	ISSERVICES=1
else
	ISSERVICES=0
fi

if [ $ISSERVICES -eq 1 ]; then
	SERVICENAMES=`cat "../$CURFILE" | sed "s|\r||g"`
	SERVICENAMES=`echo "$SERVICENAMES" | grep -v "^$" | grep -v "^Microsoft (R) Windows Script Host Version" | grep -v "Copyright (C) Microsoft Corporation"` 
	
	NUMSERVICES=`echo "$SERVICENAMES" | wc -l`
	
	if [ $NUMSERVICES -gt 0 ]; then
		for CURSERVICE in $SERVICENAMES; do
			echo "$CURSERVICE" >> service_list.tmp
			echo -e "$CURCOMPUTER\t$CURSERVICE" >> service_computer_list.txt
		done
	else
		echo "[`date`] ERROR: No services listed for $CURCOMPUTER." 
		echo "[`date`] ERROR: No services listed for $CURCOMPUTER." >> messages.txt
	fi
fi

# Find Processes
echo "$CURFILE" | grep -q "\.processes"

if [ $? -eq 0 ]; then
	ISPROCESS=1
else
	ISPROCESS=0
fi

if [ $ISPROCESS -eq 1 ]; then
	sed -i 's|'`echo "\007"`'|\\|g' ../$CURFILE
	PROCNAMES=`cat "../$CURFILE" | sed "s|\r||g"`
	PROCNAMES=`echo -E "$PROCNAMES" | grep -v "^$" | grep -v "^Microsoft (R) Windows Script Host Version" | grep -v "Copyright (C) Microsoft Corporation" | grep -v "System Idle Process"` 
	PROCNAMES=`echo -E "$PROCNAMES" | grep -vP "Name\tPid\tPri\tExe Path"`	

	NUMPROCS=`echo -E "$PROCNAMES" | wc -l`
	
	if [ $NUMPROCS -gt 0 ]; then
		for CURPROC in $PROCNAMES; do
			if [ $DEBUG -eq 0 ]; then
				echo "$CURPROC" >> process_list.tmp
				echo "$CURCOMPUTER,$CURPROC" | sed "s|,|\t|g" >> process_computer_list.txt
			else
				echo "$CURCOMPUTER,$CURPROC" | sed "s|,|\t|g" 
			fi
		done
	else
		echo "[`date`] ERROR: No processes listed for $CURCOMPUTER." 
		echo "[`date`] ERROR: No processes listed for $CURCOMPUTER." >> messages.txt
	fi
fi

# Find OS
echo "$CURFILE" | grep -q "\.os\.txt"

if [ $? -eq 0 ]; then
	ISOS=1
else
	ISOS=0
fi

if [ $ISOS -eq 1 ]; then
	OSNAME=`cat "../$CURFILE" | sed "s|\r||g" | grep -v "^$" | grep -v "^Microsoft (R) Windows Script Host Version" | grep -v "Copyright (C) Microsoft Corporation"`

	NUMOSNAMES=`echo "$OSNAME" | wc -l`
	
	if [ $NUMOSNAMES -gt 0 ]; then
		CURNAME=`echo "$OSNAME" | head -1`
		echo "$CURNAME" >> os_list.tmp
		echo "$CURCOMPUTER,$CURNAME" | sed "s|,|\t|g" >> os_computer_list.txt
	else
		echo "[`date`] ERROR: No operating systems listed for $CURCOMPUTER." 
		echo "[`date`] ERROR: No operating systems listed for $CURCOMPUTER." >> messages.txt
	fi
fi

# Find Shares
echo "$CURFILE" | grep -q "\.shares\.txt"

if [ $? -eq 0 ]; then
	ISSHARE=1
else
	ISSHARE=0
fi

if [ $ISSHARE -eq 1 ]; then
	NUMSHARES=`cat "../$CURFILE" | wc -l`
	
	if [ $NUMSHARES -eq 0 ]; then
		rm ../$CURFILE
	fi
fi

IFS=$IFS_BAK
IFS_BAK=
