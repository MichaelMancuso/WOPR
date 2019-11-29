#!/bin/bash

USERNAME=`whoami`

# SRCDIR="/media/$USERNAME/VMDrive/VirtualMachines"
SRCDIR="/opt/VirtualMachines"
DESTDIR="/media/$USERNAME/2TBBackup/VirtualMachines"
BACKUPLOG="$HOME/backuplogs/backuplog.txt"

if [ -e $BACKUPLOG ]; then
	rm $BACKUPLOG
fi

# Don't need this check anymore with the local drive
# if [ ! -e /media/$USERNAME/VMDrive ]; then
#	echo "ERROR: Unable to find VMDrive."
#	echo "ERROR: Unable to find VMDrive." >> $BACKUPLOG
#	exit 1
# fi

if [ ! -e /media/$USERNAME/2TBBackup ]; then
	echo "ERROR: Unable to find backup drive."
	echo "ERROR: Unable to find backup drive." >> $BACKUPLOG
	exit 1
fi

echo "[`date`] Cleaning up vmware drag/drop cache..."
if [ -e /opt/VirtualMachines/.cache/drag_and_drop ]; then
	rm /opt/VirtualMachines/.cache/drag_and_drop/* 2>/dev/null
fi

echo "[`date`] Starting backup.  See $BACKUPLOG for details."
echo "[`date`] Starting backup." >> $BACKUPLOG

echo "Backing up Kali VM..."
echo "Backing up Kali VM..." >> $BACKUPLOG
rsync -rva $SRCDIR/Kali/ $DESTDIR/Kali  >> $BACKUPLOG

echo "Backing up Work VM Windows 10..."
echo "Backing up Work VM Windows 10..." >> $BACKUPLOG
rsync -rva $SRCDIR/WorkVM10/ $DESTDIR/WorkVM10 >> $BACKUPLOG

echo "Backing up personal Windows 10 VM..."
echo "Backing up personal Windows 10 VM..." >> $BACKUPLOG
rsync -rva $SRCDIR/Win7-64-Field/ $DESTDIR/Win7-64-Field >> $BACKUPLOG

echo "[`date`] Done."
echo "[`date`] Done." >> $BACKUPLOG

