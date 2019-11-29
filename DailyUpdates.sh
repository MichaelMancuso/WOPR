#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade

REBOOT_IF_REQUIRED=0

if [ $REBOOT_IF_REQUIRED -eq 1 ]; then
	if [ -e /var/run/reboot-required ]; then
	  echo "[`date`] System requires reboot.  Rebooting..."
	  reboot
	fi
fi
