#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <file>"
	exit 1
fi

# Some format options:
# ffmpeg -formats:
#  E mpeg1video      raw MPEG-1 video
#  E mpeg2video      raw MPEG-2 video
# DE mpegts          MPEG-TS (MPEG-2 Transport Stream)
# D  mpegtsraw       raw MPEG-TS (MPEG-2 Transport Stream)
# D  mpegvideo       raw MPEG video
 
INPUTFILE=$1

ffmpeg -hide_banner -i $INPUTFILE -vcodec mpeg2video -pix_fmts yuv420p -me_method epzs -threads 4 -r 29.97 -acodec ac3 -ac 2 -ab 192k -ar 48000 -async 1

# can add output:
# ffmpeg -hide_banner -i $INPUTFILE -vcodec mpeg2video -pix_fmts yuv420p -me_method epzs -threads 4 -r 29.97 -acodec ac3 -ac 2 -ab 192k -ar 48000 -async 1 -f vob testout.mpg


