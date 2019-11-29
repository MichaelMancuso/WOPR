#!/bin/bash

# if [ ! -e /usr/bin/palantir ]; then
#	echo "ERROR: Please download palantir."
#	exit 1
# fi

#echo "[`date`] Starting palantir with 640x480 resolution, 15 fps.  Video is on HTTP/3000."
# palantir -s 640x480 -r 15 -p 3000

PORT=8090

# Old for zoneminder
# mjpg_streamer -i "/usr/local/lib/input_uvc.so -d /dev/video0 -f 8 -r 320x240" -o "/usr/local/lib/output_http.so -p $PORT" -b

export LD_LIBRARY_PATH=/usr/local/lib

# -b forks to background
mjpg_streamer -i "input_uvc.so -d /dev/video0 -f 5 -r 320x240"  -o "output_http.so -p $PORT -w /var/mjpg_streamer" -b
 
sleep 5

NUM_STREAMS=`ps -A | grep "mjpg" | wc -l`

if [ $NUM_STREAMS -gt 0 ]; then
	MYIP=` ifconfig | grep -Eio "inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "127.0.0.1" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
	echo "[`date`] Streaming server started.  Open your browser to http://$MYIP:$PORT/?action=stream to view stream."
	echo "[`date`] Streaming server started.  Open your browser to http://$MYIP:$PORT/?action=snapshot to view single picture."
else
	echo "[`date`] ERROR: An error occurred starting the stream server.  No mjpg_streamer processes started."
fi
