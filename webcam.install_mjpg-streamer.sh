#!/bin/bash

apt-get -y install subversion libjpeg8-dev imagemagick

cd $HOME
mkdir mjpg-streamer
cd mjpg-streamer

svn co https://svn.code.sf.net/p/mjpg-streamer/code
cd code/mjpg-streamer
make
make install

if [ ! -e /var/mjpg_streamer ]; then
	mkdir /var/mjpg_streamer
fi

cp www/* /var/mjpg_streamer

echo "[`date`] Done."
echo "Use these commands to start the web server:"
echo "export LD_LIBRARY_PATH=/usr/local/lib"
echo "mjpg_streamer -i \"input_uvc.so -d /dev/video0 -f 5 -r 320x240\"  -o \"output_http.so -p 8090 -w /var/mjpg_streamer\" -b"
echo "-p specifies the listening web port.  The files for the server have been copied to /var/mjpg_streamer."
echo ""
echo "To connect/view the stream, go to a web browser and try one of these:"
echo "http://<ip address>:8090/"
echo "http://<ip address>:8090/?action=stream"
echo "http://<ip address>:8090/?action=snapshot"
echo ""
echo "On mobile devices, use this URL to stream via javascript:"
echo "http://<ip address>:8090/javascript.html"
echo ""

