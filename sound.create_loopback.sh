#!/bin/bash

# echo "make sure you apt-get install alsa-utils"
HASMOD=`lsmod | grep "^snd_aloop" | wc -l`

if [ $HASMOD -eq 0 ]; then
	sudo modprobe snd-aloop
fi

# To have it start on boot:
# echo "snd-aloop" >> /etc/modules

# Now from here in gqrx you can go to settings and change the Audio output Device from default to "Loopback analog stereo"

