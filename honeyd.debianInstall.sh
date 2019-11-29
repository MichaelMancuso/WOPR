#!/bin/sh

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root.  Please use sudo $0 to run."
   exit 2
fi

# For now nova doesn't build.  Some npm node-gyp error.
INSTALLNOVA=0

echo "[`date`] Setting up honeyd prerequisites..."
apt-get -y install autoconf libtool
# apt-get -y install libpcap-dev libdnet-dev libevent-dev libdumbnet-dev libedit-dev zlib1g-dev gawk
apt-get -y install debhelper libpcap-dev libdumbnet-dev libevent-dev sharutils flex bison libreadline-dev python-support zlib1g-dev libpcre3-dev rrdtool

echo "[`date`] Creating $HOME/honeyd for source code..."

if [ ! -e $HOME/honeyd ]; then
	mkdir $HOME/honeyd
fi

cd $HOME/honeyd

echo "[`date`] Cloning git://github.com/DataSoft/Honeyd.git..."
git clone git://github.com/DataSoft/Honeyd.git honeyd
cd honeyd

echo "[`date`] Building source..."
./autogen.sh
automake
./configure
make
echo "[`date`] Installing honeyd..."
make install
mkdir /var/log/honeyd

if [ $INSTALLNOVA -eq 1 ]; then
	echo "[`date`] Setting up Nova..."
	echo "[`date`] Installing prerequisites..."
	#  apt-get -y install iptables # Don't want to do this unless I have to but it was in the original dependencies list.
	apt-get -y install libann-dev libboost-program-options1.49-dev libboost-serialization1.49-dev sqlite3 libsqlite3-dev libcurl3 libcurl4-gnutls-dev libprotoc-dev protobuf-compiler liblinux-inotify2-perl libfile-readbackwards-perl

	echo "[`date`] Installing npm..."
	echo 'export PATH=$HOME/local/bin:$PATH' >> $HOME/.bashrc
	. $HOME/.bashrc
	mkdir $HOME/local
	mkdir $HOME/node-latest-install
	cd $HOME/node-latest-install
	curl http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1
	./configure --prefix=$HOME/local
	make install
	wget https://npmjs.org/install.sh
	chmod +x install.sh
	./install.sh
	npm config set strict-ssl false
	
	echo "[`date`] Getting Nova source from git://github.com/DataSoft/Nova.git..."

	cd $HOME/honeyd
	git clone git://github.com/DataSoft/Nova.git Nova

	echo "[`date`] Building Nova..."
	cd Nova
	autoconf
	./configure
	make
	make install
	nova_init
	echo "[`date`] Run 'quasar' to start the interface and connect with a browser to https://127.0.0.1:8080/"
	echo "         Username: nova, password: toor"
fi

echo "[`date`] Done."
