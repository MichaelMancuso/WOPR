#!/bin/bash

which livestreamer >/dev/null

if [ $? -gt 0 ]; then
	sudo pip install livestreamer
fi

livestreamer http://www.ustream.tv/channel/live-iss-stream best

