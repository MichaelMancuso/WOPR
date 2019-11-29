#!/bin/bash
echo "[`date`] Streaming on rtp://$MYIP:8091.  Use VLCPlayer or something similar to listen to audio stream."
# Use arecord -l to list ALSA input devices.  hw:1,0 is probably right for USB webcam
MYIP=` ifconfig | grep -Eio "inet addr:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "127.0.0.1" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`

ffmpeg -ac 1 -f alsa -i hw:1,0 -acodec mp2 -ab 32k -ac 1 -re -f rtp rtp://$MYIP:8091

