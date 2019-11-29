#!/bin/bash

# Reference: https://setiathome.berkeley.edu/forum_thread.php?id=78799#1756163
#
#

echo "[`date`] Installing prerequisites..."
apt-get update
apt-get -y install git make m4 libtool autoconf pkg-config automake subversion libcurl4-openssl-dev libssl-dev gettext docbook2x docbook-xml libxml2-utils zlib1g-dev libsm-dev libice-dev libxmu-dev libxi-dev libx11-dev libnotify-dev freeglut3-dev libfcgi-dev libjpeg8-dev libxss-dev libxcb-util0-dev libxcb-dpms0-dev libxext-dev libstdc++6-4.7-dev boinc-client boinc-app-seti boinc-manager

echo "[`date`] Setting compiler flags..."
CC=gcc
export CC

CFLAGS="-march=armv7-a -mfloat-abi=hard -mfpu=neon-vfpv4 -ffast-math -funsafe-math-optimizations -O3"
export CFLAGS

CXXFLAGS="$CFLAGS"
export CXXFLAGS

echo "[`date`] Downloading and compiling FFTW..."
cd /tmp
wget http://www.fftw.org/fftw-3.3.4.tar.gz
tar -zxvf fftw-3.3.4.tar.gz
cd fftw-3.3.4
./configure --enable-float --enable-neon
make -j 4
make install

echo "[`date`] Downloading and compiling Boinc 7.4.42..."
cd /tmp
git clone https://github.com/BOINC/boinc boinc
cd boinc
./_autosetup 
./configure --disable-server --disable-manager LDFLAGS=-static-libgcc --with-boinc-alt-platform=arm-unknown-linux-gnueabihf 
 -j 4 compiles using all 4 cores
make -j 4
# make install  # Don't have to make install.  Don't know why.  In fact, this whole process may not be required.
# Without it there were some ./configure errors building seti_boinc

cd /tmp
# svn checkout https://setisvn.ssl.berkeley.edu/svn/seti_boinc@3304 seti_boinc --trust-server-cert --non-interactive
svn checkout https://setisvn.ssl.berkeley.edu/svn/seti_boinc seti_boinc --trust-server-cert --non-interactive
cd seti_boinc 

./_autosetup 
# ./configure BOINCDIR=/home/pi/boinc --enable-client --enable-static --disable-shared --disable-server --enable-dependency-tracking --with-gnu-ld --disable-altivec --enable-fast-math --disable-tests
./configure --enable-client --enable-static --disable-shared --disable-server --enable-dependency-tracking --with-gnu-ld --disable-altivec --enable-fast-math --disable-tests
make -j 4

cd client

if [ ! -e setiathome-8.0.armv7l-unknown-linux-gnueabihf ]; then
	echo "[`date`] ERROR: setiathome build failed.  Exiting."
	exit 2
fi

cp setiathome-8.0.armv7l-unknown-linux-gnueabihf ~/

echo "[`date`] Configuring application..."

echo "<app_info>" > ~/app_info.xml
echo "	<app>" >> ~/app_info.xml
echo "		<name>setiathome_v8</name>" >> ~/app_info.xml
echo "		<user_friendly_name>SETI@home v8</user_friendly_name>" >> ~/app_info.xml
echo "	</app>" >> ~/app_info.xml
echo "	<file_info>" >> ~/app_info.xml
echo "	<name>setiathome-8.0.armv7l-unknown-linux-gnueabihf</name>" >> ~/app_info.xml
echo "	<executable/>" >> ~/app_info.xml
echo "	</file_info>" >> ~/app_info.xml
echo "	<app_version>" >> ~/app_info.xml
echo "		<app_name>setiathome_v8</app_name>" >> ~/app_info.xml
echo "		<version_num>800</version_num>" >> ~/app_info.xml
echo "		<file_ref>" >> ~/app_info.xml
echo "		<file_name>setiathome-8.0.armv7l-unknown-linux-gnueabihf</file_name>" >> ~/app_info.xml
echo "		<main_program/>" >> ~/app_info.xml
echo "		</file_ref>" >> ~/app_info.xml
echo "	</app_version>" >> ~/app_info.xml
echo "</app_info>" >> ~/app_info.xml

cp ~/setiathome-8.0.armv7l-unknown-linux-gnueabihf /var/lib/boinc-client/projects/setiathome.berkeley.edu/

if [ ! -e /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml.original ]; then
	cp /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml.original
fi

cp ~/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/
cp ~/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.new
chown boinc.boinc /var/lib/boinc-client/projects/setiathome.berkeley.edu/*

echo "[`date`] Starting service..."
/etc/init.d/boinc-client restart
systemctl daemon-reload

echo "[`date`] Done."
echo "If you still have problems starting the boinc-client service, use these steps..."
echo "apt-get purge boinc-client boinc-manager"
echo "apt-get install boinc-client boinc-app-seti boinc-manager"
echo "Then run seti.finish_install.sh"
