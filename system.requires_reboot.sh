#!/bin/bash
if [ -e /var/run/reboot-required ]; then
  echo "[`date`] System is awaiting a reboot."
  
  exit 1
fi

which needrestart > /dev/null

if [ $? -gt 0 ]; then
	apt-get install -y needrestart
fi

NEEDSRESTART=`needrestart -bk | grep "NEEDRESTART-KSTA:.*2" | grep -v "^$" | wc -l`

if [ $NEEDSRESTART -eq 1 ]; then
  echo "[`date`] System is awaiting a reboot (kernel upgrade)."
  
  exit 2
fi

echo "[`date`] No reboot required."

exit 0
