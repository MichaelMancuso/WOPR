#!/bin/bash

# script to set up for simple_ra radio astronomy tools
#  See this for prerequisites: https://github.com/patchvonbraun/simple_ra/blob/master/README

which gnuradio-companion > /dev/null

if [ $? -gt 0 ]; then
	echo "ERROR: Please install gnuradio first."
	exit 1
fi

apt-get -y install python-ephem

if [ ! -e /opt/ra ]; then
	mkdir /opt/ra
fi

cd /opt/ra

git clone https://github.com/patchvonbraun/gr-ra_blocks gr-ra_blocks

if [ ! -e gr-ra_blocks ]; then
	echo "ERROR: Unable to git gr-ra_blocks."
	exit 2
fi

cd gr-ra_blocks
mkdir build
cd build
cmake ..
make -j 4
sudo make install
sudo ldconfig

cd /opt/ra
git clone https://github.com/patchvonbraun/simple_ra.git simple_ra

if [ ! -e simple_ra ]; then
	echo "ERROR: Unable to git simple_ra."
	exit 2
fi

cd simple_ra
make -j 4
make sysinstall
