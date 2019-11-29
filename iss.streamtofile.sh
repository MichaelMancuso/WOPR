#!/bin/bash

which livestreamer >/dev/null

if [ $? -gt 0 ]; then
	sudo pip install livestreamer
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi

FILENAME=$1

echo "[`date`] Streaming to $FILENAME..."
livestreamer http://www.ustream.tv/channel/live-iss-stream best -O $FILENAME

