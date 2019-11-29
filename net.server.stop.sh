#!/bin/bash

PIDOFRUN=`ps -A -o pid,cmd|grep "net.server.run.sh" | grep -v grep |head -n 1 | awk '{print $1}'`

if [ ${#PIDOFRUN} -gt 0 ]; then
	echo "Found net.server.run.sh.  Stopping service..."
	kill $PIDOFRUN
	echo "Done."
else
	echo "net.server.run.sh does not appear to be running.  Nothing to stop."
fi

PIDOFRUN=`ps -A -o pid,cmd|grep "net.server.ssl.rb" | grep -v grep |head -n 1 | awk '{print $1}'`

if [ ${#PIDOFRUN} -gt 0 ]; then
	echo "Found net.server.ssl.rb.  Stopping service..."
	kill $PIDOFRUN
	echo "Done."
else
	echo "net.server.ssl.rb does not appear to be running.  Nothing to stop."
fi
