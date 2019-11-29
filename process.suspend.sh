#!/bin/bash

ShowUsage() {
	echo "$0 <pid>"
	echo ""
	echo "$0 will temporarily suspend (sleep) the process specified."
	echo ""
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

PID=$1

echo "Suspending $PID..."
kill -STOP $PID
