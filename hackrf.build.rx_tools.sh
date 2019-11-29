#!/bin/bash

echo "[`date`] Starting setup of the latest hackrf, SoapySDR, SoapyHackRF, and kalibrate-hackrf"
if [ ! -e /opt/hackrf ]; then
	mkdir /opt/hackrf
fi

apt-get update
# Required by kalibrate-hackrf
apt-get -y install fftw3-dev

ISPI=`uname -a | grep armv | wc -l`

# LibHackRF
cd /opt/hackrf
git clone https://github.com/mossmann/hackrf.git hackrf
cd hackrf/host
mkdir build
cd build
cmake ..
make -j4
make install


if [ ! -e /usr/include/hackrf.h ]; then
	ln -s /usr/local/include/libhackrf/hackrf.h /usr/include/hackrf.h
fi

# SoapySDR
cd /opt/hackrf
git clone https://github.com/pothosware/SoapySDR.git SoapySDR
cd SoapySDR
mkdir build
cd build
cmake ..
make -j4
make install
ldconfig

# rx_tools (hackrf versions of rtl_xxxxx)
cd /opt/hackrf
git clone https://github.com/rxseger/rx_tools.git rx_tools
cd rx_tools
mkdir build
cd build
cmake ..
make -j4
make install

# SoapySDR HackRF Module
cd /opt/hackrf
git clone https://github.com/pothosware/SoapyHackRF.git SoapyHackRF
cd SoapyHackRF
mkdir build
cd build
cmake ..
make -j4

if [ $? -gt 0 ]; then
	exit 1
fi

make install

# Kalibrate-hackrf
cd /opt/hackrf
git clone https://github.com/scateu/kalibrate-hackrf.git kalibrate-hackrf
cd kalibrate-hackrf
./bootstrap && CXXFLAGS='-W -Wall -O3' ./configure && make

if [ -e src/kal ]; then
	cp src/kal /usr/bin/kalibrate-hackrf
else
	echo "[`date`] ERROR: kalibrate-hackrf did not build."
fi

# SoapyRemote (replacement for rtl_tcp)
cd /opt/hackrf
git clone https://github.com/pothosware/SoapyRemote.git SoapyRemote
cd SoapyRemote
mkdir build
cd build
cmake ..
make -j4
make install

# One last ldconfig to make sure everything is updated.
ldconfig

echo "[`date`] Done.  Check output for errors."

