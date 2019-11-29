#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Select Station:"
	echo "1. Mix 106.1"
	echo "2. Q102"
	echo -n "Selection (1):"

	USER_INPUT=""
	read -n 1 USER_INPUT 

else
	USER_INPUT=$1
fi

if [ ${#USER_INPUT} -gt 0 ]; then
	case $USER_INPUT in
	2)
		# Q 102
		rtmpdump -r "rtmp://cp20056.live.edgefcs.net/live/Phi_PA_WIOQ-FM_OR@152654" -v | mplayer -
	;;
	*)
		# Mix 106.1
		rtmpdump -r "rtmp://cp20057.live.edgefcs.net/live/Phi_PA_WISX-FM_OR@152655" -v | mplayer -
	;;
	esac
fi
