#!/bin/bash

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

NEEDSRESTART=`needrestart -bk | grep "NEEDRESTART-KSTA:.*2" | grep -v "^$" | wc -l`

if [ $NEEDSRESTART -eq 1 ]; then
	echo "[`date`] System requires reboot to complete installation.  Restarting..."
	reboot
fi

