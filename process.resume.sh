#!/bin/bash

ShowUsage() {
	echo "$0 <pid>"
	echo ""
	echo "$0 will resume a process paused with process.suspend.sh (kill -STOP $PID)."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

PID=$1

echo "Waking up $PID..."
kill -CONT $PID
