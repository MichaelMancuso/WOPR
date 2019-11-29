#!/bin/bash

ISMOUNTED=`mount -l | grep "olympus-shares" | grep -v "^$" | wc -l`

if [ $ISMOUNTED -eq 0 ]; then
	echo "[`date`] ERROR: remote share not mounted."
	exit 1
fi

ISMOUNTED=`mount -l | grep "\/backup" | grep -v "^$" | wc -l`

if [ $ISMOUNTED -eq 0 ]; then
	echo "[`date`] ERROR: local backup drive not mounted."
	exit 2
fi

echo "[`date`] Starting share data sync..."
cp -rup /mnt/olympus-shares/* /backup/shares/
echo "[`date`] Backing up olympus /etc..."
scp -rp -i /root/.ssh/root.olympus.key root@olympus.phn.private:/etc /backup/backups/olympus
echo "[`date`] Done."
