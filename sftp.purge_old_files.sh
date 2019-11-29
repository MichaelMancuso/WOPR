#!/bin/bash

cd /home
SFTPDIRS=`ls -1d *_sftp`
MAXDAYS=60

echo "[`date`] Starting <user>_sftp file cleanup of files older than $MAXDAYS days..."

for CURDIR in $SFTPDIRS
do
	echo "[`date`] Processing $CURDIR..."
	cd /home/$CURDIR
	find . -type f -mtime +$MAXDAYS -exec rm {} \;
	
	# Just in case there's a dir error on a cd, let's not screw up any important files.
	cd /tmp
done

echo "[`date`] Done."
